import '../models/refund_transaction.dart';
import '../models/payment_model.dart';
import '../models/order_model.dart';
import '../enums/order_enums.dart';
import 'local_db_service.dart';
import 'notification_service.dart';
import '../../core/utils/logger.dart';

/// Service for managing refund transactions and processing
class RefundService {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final NotificationService _notificationService = NotificationService();

  /// Process a refund for a payment
  Future<RefundTransaction> processRefund({
    required String paymentId,
    required String orderId,
    required double refundAmount,
    required String reason,
    required String processedBy,
    RefundMethod method = RefundMethod.original,
    String? transactionId,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      Logger.info('RefundService', 'Processing refund for payment: $paymentId');

      // Validate payment exists and get details
      final payment = await _getPayment(paymentId);
      if (payment == null) {
        throw Exception('Payment not found: $paymentId');
      }

      // Validate refund amount
      await _validateRefundAmount(paymentId, refundAmount);

      // Validate order status
      final order = await _getOrder(orderId);
      if (order == null) {
        throw Exception('Order not found: $orderId');
      }

      if (!_canRefundOrder(order)) {
        throw Exception('Order cannot be refunded in current status: ${order.status}');
      }

      // Create refund transaction
      final refund = RefundTransaction.create(
        originalPaymentId: paymentId,
        orderId: orderId,
        refundAmount: refundAmount,
        reason: reason,
        processedBy: processedBy,
        method: method,
        transactionId: transactionId,
        notes: notes,
        metadata: metadata,
      );

      // Process in database transaction
      final db = await _dbService.database;
      await db.transaction((txn) async {
        // Insert refund transaction
        await txn.insert('refund_transactions', refund.toMap());

        // Update order if full refund
        if (refundAmount >= payment.amount) {
          await txn.update(
            'orders',
            {
              'status': 'refunded',
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'unique_id = ?',
            whereArgs: [orderId],
          );
        }
      });

      Logger.info('RefundService', 'Refund processed successfully: ${refund.uniqueId}');

      // Create notification
      await _notificationService.createNotification(
        title: 'Refund Processed',
        message: 'Refund of ₹${refundAmount.toStringAsFixed(2)} processed for order ${order.uniqueId}',
        type: NotificationType.paymentReceived, // We can create a new refund type
        orderId: orderId,
        customerId: order.customerId,
        actionUrl: '/refunds/detail?id=${refund.uniqueId}',
        data: {
          'refund_id': refund.uniqueId,
          'payment_id': paymentId,
          'amount': refundAmount,
        },
      );

      return refund;
    } catch (e, stackTrace) {
      Logger.error('RefundService', 'Failed to process refund for payment: $paymentId', 
                   error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get refund by ID
  Future<RefundTransaction?> getRefund(String refundId) async {
    try {
      final refundMaps = await _dbService.select(
        'refund_transactions',
        where: 'unique_id = ?',
        whereArgs: [refundId],
        limit: 1,
      );

      if (refundMaps.isEmpty) return null;

      return RefundTransaction.fromMap(refundMaps.first);
    } catch (e, stackTrace) {
      Logger.error('RefundService', 'Failed to get refund: $refundId', 
                   error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get refunds for an order
  Future<List<RefundTransaction>> getRefundsForOrder(String orderId) async {
    try {
      final refundMaps = await _dbService.select(
        'refund_transactions',
        where: 'order_id = ?',
        whereArgs: [orderId],
        orderBy: 'processed_at DESC',
      );

      return refundMaps.map((map) => RefundTransaction.fromMap(map)).toList();
    } catch (e, stackTrace) {
      Logger.error('RefundService', 'Failed to get refunds for order: $orderId', 
                   error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get refunds for a payment
  Future<List<RefundTransaction>> getRefundsForPayment(String paymentId) async {
    try {
      final refundMaps = await _dbService.select(
        'refund_transactions',
        where: 'original_payment_id = ?',
        whereArgs: [paymentId],
        orderBy: 'processed_at DESC',
      );

      return refundMaps.map((map) => RefundTransaction.fromMap(map)).toList();
    } catch (e, stackTrace) {
      Logger.error('RefundService', 'Failed to get refunds for payment: $paymentId', 
                   error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Update refund status
  Future<RefundTransaction> updateRefundStatus({
    required String refundId,
    required RefundStatus status,
    String? transactionId,
    String? notes,
  }) async {
    try {
      final refund = await getRefund(refundId);
      if (refund == null) {
        throw Exception('Refund not found: $refundId');
      }

      final updatedRefund = refund.copyWith(
        status: status,
        transactionId: transactionId ?? refund.transactionId,
        notes: notes ?? refund.notes,
        updatedAt: DateTime.now(),
      );

      await _dbService.update(
        'refund_transactions',
        updatedRefund.toMap(),
        where: 'unique_id = ?',
        whereArgs: [refundId],
      );

      Logger.info('RefundService', 'Refund status updated: $refundId -> ${status.value}');

      // Create notification for status change
      if (status == RefundStatus.completed) {
        await _notificationService.createNotification(
          title: 'Refund Completed',
          message: 'Refund of ₹${refund.refundAmount.toStringAsFixed(2)} has been completed',
          type: NotificationType.paymentReceived,
          orderId: refund.orderId,
          actionUrl: '/refunds/detail?id=$refundId',
          data: {
            'refund_id': refundId,
            'status': status.value,
          },
        );
      }

      return updatedRefund;
    } catch (e, stackTrace) {
      Logger.error('RefundService', 'Failed to update refund status: $refundId', 
                   error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Calculate total refunded amount for a payment
  Future<double> getTotalRefundedAmount(String paymentId) async {
    try {
      final refunds = await getRefundsForPayment(paymentId);
      return refunds
          .where((refund) => refund.status == RefundStatus.completed)
          .fold<double>(0.0, (sum, refund) => sum + refund.refundAmount);
    } catch (e) {
      Logger.error('RefundService', 'Failed to calculate refunded amount for payment: $paymentId', error: e);
      return 0.0;
    }
  }

  /// Calculate remaining refundable amount for a payment
  Future<double> getRefundableAmount(String paymentId) async {
    try {
      final payment = await _getPayment(paymentId);
      if (payment == null) return 0.0;

      final totalRefunded = await getTotalRefundedAmount(paymentId);
      return payment.amount - totalRefunded;
    } catch (e) {
      Logger.error('RefundService', 'Failed to calculate refundable amount for payment: $paymentId', error: e);
      return 0.0;
    }
  }

  /// Get refund statistics for a date range
  Future<Map<String, dynamic>> getRefundStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final refundMaps = await _dbService.select(
        'refund_transactions',
        where: 'processed_at BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
      );

      final refunds = refundMaps.map((map) => RefundTransaction.fromMap(map)).toList();

      final totalRefunds = refunds.length;
      final totalAmount = refunds.fold<double>(0.0, (sum, refund) => sum + refund.refundAmount);
      final completedRefunds = refunds.where((r) => r.status == RefundStatus.completed).length;
      final pendingRefunds = refunds.where((r) => r.status == RefundStatus.pending).length;

      final refundsByReason = <String, int>{};
      for (final refund in refunds) {
        refundsByReason[refund.reason] = (refundsByReason[refund.reason] ?? 0) + 1;
      }

      return {
        'total_refunds': totalRefunds,
        'total_amount': totalAmount,
        'completed_refunds': completedRefunds,
        'pending_refunds': pendingRefunds,
        'refunds_by_reason': refundsByReason,
        'average_refund_amount': totalRefunds > 0 ? totalAmount / totalRefunds : 0.0,
      };
    } catch (e, stackTrace) {
      Logger.error('RefundService', 'Failed to get refund statistics', 
                   error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Process automatic refund for cancelled order
  Future<RefundTransaction?> processAutomaticRefund({
    required String orderId,
    required String paymentId,
    required String reason,
    String processedBy = 'system',
  }) async {
    try {
      Logger.info('RefundService', 'Processing automatic refund for cancelled order: $orderId');

      final payment = await _getPayment(paymentId);
      if (payment == null) {
        Logger.warning('RefundService', 'Payment not found for automatic refund: $paymentId');
        return null;
      }

      // Check if already refunded
      final existingRefunds = await getRefundsForPayment(paymentId);
      if (existingRefunds.any((r) => r.status == RefundStatus.completed)) {
        Logger.info('RefundService', 'Payment already refunded: $paymentId');
        return null;
      }

      return await processRefund(
        paymentId: paymentId,
        orderId: orderId,
        refundAmount: payment.amount,
        reason: reason,
        processedBy: processedBy,
        method: RefundMethod.original,
        notes: 'Automatic refund due to order cancellation',
      );
    } catch (e, stackTrace) {
      Logger.error('RefundService', 'Failed to process automatic refund', 
                   error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Private helper methods

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

  Future<void> _validateRefundAmount(String paymentId, double refundAmount) async {
    if (refundAmount <= 0) {
      throw Exception('Refund amount must be greater than 0');
    }

    final refundableAmount = await getRefundableAmount(paymentId);
    if (refundAmount > refundableAmount) {
      throw Exception('Refund amount (₹${refundAmount.toStringAsFixed(2)}) exceeds refundable amount (₹${refundableAmount.toStringAsFixed(2)})');
    }
  }

  bool _canRefundOrder(Order order) {
    const refundableStatuses = [
      'pending', 'cutting', 'stitching', 'in_progress', 
      'ready', 'completed', 'cancelled'
    ];
    return refundableStatuses.contains(order.status.toLowerCase());
  }
}