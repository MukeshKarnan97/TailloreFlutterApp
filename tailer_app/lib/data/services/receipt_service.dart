import '../models/payment_receipt.dart';
import '../models/payment_model.dart';
import '../models/order_model.dart';
import 'local_db_service.dart';
import '../../core/utils/logger.dart';

/// Service for generating and managing payment receipts
class ReceiptService {
  final LocalDatabaseService _dbService = LocalDatabaseService();

  /// Generate receipt for payment
  Future<PaymentReceipt> generatePaymentReceipt({
    required String paymentId,
    required String orderId,
    required String customerId,
    Map<String, dynamic>? additionalBusinessDetails,
    Map<String, dynamic>? additionalCustomerDetails,
    String? notes,
  }) async {
    try {
      Logger.info('ReceiptService', 'Generating payment receipt for payment: $paymentId');

      // Get payment details
      final payment = await _getPayment(paymentId);
      if (payment == null) {
        throw Exception('Payment not found: $paymentId');
      }

      // Get order details
      final order = await _getOrder(orderId);
      if (order == null) {
        throw Exception('Order not found: $orderId');
      }

      // Get customer details
      final customer = await _getCustomer(customerId);
      if (customer == null) {
        throw Exception('Customer not found: $customerId');
      }

      // Prepare business details
      final businessDetails = {
        'name': 'Tailor Shop', // You can make this configurable
        'address': '123 Fashion Street, Textile City',
        'phone': '+91 9876543210',
        'email': 'info@tailorshop.com',
        'gst_number': 'GST123456789',
        'logo_path': null,
        ...?additionalBusinessDetails,
      };

      // Prepare customer details
      final customerDetails = {
        'name': customer['name'] ?? 'Customer',
        'phone': customer['phone'] ?? '',
        'email': customer['email'] ?? '',
        'address': customer['address'] ?? '',
        ...?additionalCustomerDetails,
      };

      // Prepare item details
      final itemDetails = {
        'order_id': order.uniqueId,
        'description': 'Custom Tailoring Order', // Simplified
        'measurements': order.measurements,
        'delivery_date': order.deliveryDate.toIso8601String(),
        'amount': payment.amount,
        'payment_method': payment.method.displayName,
        'transaction_id': payment.transactionId,
      };

      // Create receipt
      final receipt = PaymentReceipt.create(
        paymentId: paymentId,
        orderId: orderId,
        customerId: customerId,
        type: ReceiptType.payment,
        amount: payment.amount,
        paymentMethod: payment.method.displayName,
        businessDetails: businessDetails,
        customerDetails: customerDetails,
        itemDetails: itemDetails,
        notes: notes,
      );

      // Save to database
      await _dbService.insert('payment_receipts', receipt.toMap());

      Logger.info('ReceiptService', 'Payment receipt generated: ${receipt.receiptNumber}');
      return receipt;
    } catch (e, stackTrace) {
      Logger.error('ReceiptService', 'Failed to generate payment receipt', 
                   error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate receipt for refund
  Future<PaymentReceipt> generateRefundReceipt({
    required String paymentId,
    required String orderId,
    required String customerId,
    required double refundAmount,
    required String refundReason,
    String? notes,
  }) async {
    try {
      Logger.info('ReceiptService', 'Generating refund receipt for payment: $paymentId');

      // Get original payment details
      final payment = await _getPayment(paymentId);
      if (payment == null) {
        throw Exception('Payment not found: $paymentId');
      }

      // Get order and customer details (similar to payment receipt)
      final order = await _getOrder(orderId);
      final customer = await _getCustomer(customerId);

      if (order == null || customer == null) {
        throw Exception('Order or customer not found');
      }

      // Prepare details for refund receipt
      final businessDetails = {
        'name': 'Tailor Shop',
        'address': '123 Fashion Street, Textile City',
        'phone': '+91 9876543210',
        'email': 'info@tailorshop.com',
        'gst_number': 'GST123456789',
      };

      final customerDetails = {
        'name': customer['name'] ?? 'Customer',
        'phone': customer['phone'] ?? '',
        'email': customer['email'] ?? '',
        'address': customer['address'] ?? '',
      };

      final itemDetails = {
        'order_id': order.uniqueId,
        'original_payment_id': paymentId,
        'original_amount': payment.amount,
        'refund_amount': refundAmount,
        'refund_reason': refundReason,
        'original_payment_method': payment.method.displayName,
      };

      // Create refund receipt
      final receipt = PaymentReceipt.create(
        paymentId: paymentId,
        orderId: orderId,
        customerId: customerId,
        type: ReceiptType.refund,
        amount: refundAmount,
        paymentMethod: payment.method.displayName,
        businessDetails: businessDetails,
        customerDetails: customerDetails,
        itemDetails: itemDetails,
        notes: notes,
      );

      // Save to database
      await _dbService.insert('payment_receipts', receipt.toMap());

      Logger.info('ReceiptService', 'Refund receipt generated: ${receipt.receiptNumber}');
      return receipt;
    } catch (e, stackTrace) {
      Logger.error('ReceiptService', 'Failed to generate refund receipt', 
                   error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate PDF for receipt (placeholder - requires pdf package)
  Future<String?> generateReceiptPDF(PaymentReceipt receipt) async {
    try {
      Logger.info('ReceiptService', 'PDF generation not implemented yet for receipt: ${receipt.receiptNumber}');
      
      // TODO: Implement PDF generation when pdf package is added
      // This would require adding pdf package to pubspec.yaml
      // and implementing the actual PDF generation logic
      
      return null;
    } catch (e, stackTrace) {
      Logger.error('ReceiptService', 'Failed to generate PDF', 
                   error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get receipt by ID
  Future<PaymentReceipt?> getReceipt(String receiptId) async {
    try {
      final receiptMaps = await _dbService.select(
        'payment_receipts',
        where: 'unique_id = ?',
        whereArgs: [receiptId],
        limit: 1,
      );

      if (receiptMaps.isEmpty) return null;

      return PaymentReceipt.fromMap(receiptMaps.first);
    } catch (e, stackTrace) {
      Logger.error('ReceiptService', 'Failed to get receipt: $receiptId', 
                   error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get receipts for order
  Future<List<PaymentReceipt>> getReceiptsForOrder(String orderId) async {
    try {
      final receiptMaps = await _dbService.select(
        'payment_receipts',
        where: 'order_id = ?',
        whereArgs: [orderId],
        orderBy: 'receipt_date DESC',
      );

      return receiptMaps.map((map) => PaymentReceipt.fromMap(map)).toList();
    } catch (e, stackTrace) {
      Logger.error('ReceiptService', 'Failed to get receipts for order: $orderId', 
                   error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Mark receipt as emailed
  Future<PaymentReceipt> markAsEmailed(String receiptId) async {
    try {
      final receipt = await getReceipt(receiptId);
      if (receipt == null) {
        throw Exception('Receipt not found: $receiptId');
      }

      final updatedReceipt = receipt.markAsEmailed();
      await _dbService.update(
        'payment_receipts',
        updatedReceipt.toMap(),
        where: 'unique_id = ?',
        whereArgs: [receiptId],
      );

      Logger.info('ReceiptService', 'Receipt marked as emailed: $receiptId');
      return updatedReceipt;
    } catch (e, stackTrace) {
      Logger.error('ReceiptService', 'Failed to mark receipt as emailed', 
                   error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Mark receipt as printed
  Future<PaymentReceipt> markAsPrinted(String receiptId) async {
    try {
      final receipt = await getReceipt(receiptId);
      if (receipt == null) {
        throw Exception('Receipt not found: $receiptId');
      }

      final updatedReceipt = receipt.markAsPrinted();
      await _dbService.update(
        'payment_receipts',
        updatedReceipt.toMap(),
        where: 'unique_id = ?',
        whereArgs: [receiptId],
      );

      Logger.info('ReceiptService', 'Receipt marked as printed: $receiptId');
      return updatedReceipt;
    } catch (e, stackTrace) {
      Logger.error('ReceiptService', 'Failed to mark receipt as printed', 
                   error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Helper methods

  Future<Payment?> _getPayment(String paymentId) async {
    try {
      final paymentMaps = await _dbService.select(
        'payment',
        where: 'unique_id = ?',
        whereArgs: [paymentId],
        limit: 1,
      );

      if (paymentMaps.isEmpty) return null;
      return Payment.fromMap(paymentMaps.first);
    } catch (e) {
      return null;
    }
  }

  Future<Order?> _getOrder(String orderId) async {
    try {
      final orderMaps = await _dbService.select(
        'orders',
        where: 'unique_id = ?',
        whereArgs: [orderId],
        limit: 1,
      );

      if (orderMaps.isEmpty) return null;
      return Order.fromMap(orderMaps.first);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getCustomer(String customerId) async {
    try {
      final customerMaps = await _dbService.select(
        'customer',
        where: 'unique_id = ?',
        whereArgs: [customerId],
        limit: 1,
      );

      if (customerMaps.isEmpty) return null;
      return customerMaps.first;
    } catch (e) {
      return null;
    }
  }
}