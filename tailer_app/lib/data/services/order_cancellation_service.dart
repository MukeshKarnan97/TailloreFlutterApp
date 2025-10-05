import '../models/order_model.dart';
import '../models/order_cancellation_model.dart';
import '../enums/order_enums.dart';
import 'local_db_service.dart';
import 'notification_service.dart';
import 'refund_service.dart';
import '../../core/utils/logger.dart';

/// Service for managing order cancellations
class OrderCancellationService {
  static final OrderCancellationService _instance = OrderCancellationService._internal();
  factory OrderCancellationService() => _instance;
  OrderCancellationService._internal();

  final LocalDatabaseService _dbService = LocalDatabaseService();
  final NotificationService _notificationService = NotificationService();
  final RefundService _refundService = RefundService();

  /// Cancel an order with reason
  Future<OrderCancellation> cancelOrder({
    required String orderId,
    required CancellationReason reason,
    String? customReason,
    required String cancelledBy,
    double? refundAmount,
    String? refundNotes,
  }) async {
    try {
      Logger.info('OrderCancellationService', 'Cancelling order: $orderId');

      // Check if order exists and can be cancelled
      final order = await _getOrder(orderId);
      if (order == null) {
        throw Exception('Order not found: $orderId');
      }

      if (!_canCancelOrder(order)) {
        throw Exception('Order cannot be cancelled in current status: ${order.status}');
      }

      // Create cancellation record
      final cancellation = OrderCancellation.create(
        orderId: orderId,
        reason: reason.code,
        customReason: customReason,
        cancelledBy: cancelledBy,
        refundAmount: refundAmount ?? 0.0,
        refundNotes: refundNotes,
      );

      // Use database transaction
      final db = await _dbService.database;
      await db.transaction((txn) async {
        // Insert cancellation record
        await txn.insert('order_cancellations', cancellation.toMap());

        // Update order status to cancelled
        await txn.update(
          'orders',
          {
            'status': OrderStatus.cancelled.code,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'unique_id = ?',
          whereArgs: [orderId],
        );
      });

      Logger.info('OrderCancellationService', 'Order cancelled successfully: $orderId');

      // Process automatic refund if refund amount is specified
      if (refundAmount != null && refundAmount > 0) {
        try {
          // Get the payment for this order to process refund
          final payments = await _getPaymentsForOrder(orderId);
          if (payments.isNotEmpty) {
            await _refundService.processAutomaticRefund(
              orderId: orderId,
              paymentId: payments.first['unique_id'],
              reason: 'Order cancelled: ${reason.displayName}',
              processedBy: cancelledBy,
            );
            Logger.info('OrderCancellationService', 'Automatic refund processed for order: $orderId');
          } else {
            Logger.warning('OrderCancellationService', 'No payment found for refund of order: $orderId');
          }
        } catch (refundError) {
          Logger.error('OrderCancellationService', 'Failed to process automatic refund for order: $orderId', 
                       error: refundError);
          // Don't rethrow - order cancellation was successful, refund can be processed manually
        }
      }

      // Create notification
      final updatedOrder = order.copyWith(status: OrderStatus.cancelled.code);
      await _notificationService.notifyOrderCancellation(updatedOrder, cancellation);

      return cancellation;
    } catch (e, stackTrace) {
      Logger.error('OrderCancellationService', 'Failed to cancel order: $orderId', 
                   error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get cancellation details for an order
  Future<OrderCancellation?> getCancellationDetails(String orderId) async {
    try {
      final cancellationMaps = await _dbService.select(
        'order_cancellations',
        where: 'order_id = ?',
        whereArgs: [orderId],
        limit: 1,
      );

      if (cancellationMaps.isEmpty) {
        return null;
      }

      return OrderCancellation.fromMap(cancellationMaps.first);
    } catch (e, stackTrace) {
      Logger.error('OrderCancellationService', 'Failed to get cancellation details for order: $orderId', 
                   error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get all cancelled orders with cancellation details
  Future<List<Map<String, dynamic>>> getCancelledOrdersWithDetails({
    int? limit,
    String? searchTerm,
  }) async {
    try {
      String query = '''
        SELECT 
          o.*,
          oc.reason,
          oc.custom_reason,
          oc.cancelled_by,
          oc.cancelled_at,
          oc.refund_amount,
          oc.refund_status,
          oc.refund_notes,
          c.name as customer_name,
          c.phone as customer_phone
        FROM orders o
        INNER JOIN order_cancellations oc ON o.unique_id = oc.order_id
        LEFT JOIN customers c ON o.customer_id = c.unique_id
        WHERE o.status = ?
      ''';

      List<dynamic> queryArgs = [OrderStatus.cancelled.code];

      if (searchTerm != null && searchTerm.isNotEmpty) {
        query += ' AND (o.unique_id LIKE ? OR c.name LIKE ? OR c.phone LIKE ?)';
        queryArgs.addAll(['%$searchTerm%', '%$searchTerm%', '%$searchTerm%']);
      }

      query += ' ORDER BY oc.cancelled_at DESC';

      if (limit != null) {
        query += ' LIMIT ?';
        queryArgs.add(limit);
      }

      final results = await _dbService.rawQuery(query, queryArgs);
      
      Logger.debug('OrderCancellationService', 'Found ${results.length} cancelled orders');
      return results;
    } catch (e, stackTrace) {
      Logger.error('OrderCancellationService', 'Failed to get cancelled orders', 
                   error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Update refund information for a cancellation
  Future<void> updateRefundStatus({
    required String orderId,
    required String refundStatus,
    double? refundAmount,
    String? refundNotes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'refund_status': refundStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (refundAmount != null) {
        updateData['refund_amount'] = refundAmount;
      }

      if (refundNotes != null) {
        updateData['refund_notes'] = refundNotes;
      }

      await _dbService.update(
        'order_cancellations',
        updateData,
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      Logger.info('OrderCancellationService', 'Updated refund status for order: $orderId');
    } catch (e, stackTrace) {
      Logger.error('OrderCancellationService', 'Failed to update refund status for order: $orderId', 
                   error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get cancellation statistics
  Future<Map<String, dynamic>> getCancellationStats({DateTime? fromDate, DateTime? toDate}) async {
    try {
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (fromDate != null) {
        whereClause += ' AND cancelled_at >= ?';
        whereArgs.add(fromDate.toIso8601String());
      }

      if (toDate != null) {
        whereClause += ' AND cancelled_at <= ?';
        whereArgs.add(toDate.toIso8601String());
      }

      // Get total cancellations
      final totalQuery = '''
        SELECT COUNT(*) as total_cancellations,
               SUM(refund_amount) as total_refund_amount
        FROM order_cancellations 
        WHERE $whereClause
      ''';
      final totalResult = await _dbService.rawQuery(totalQuery, whereArgs);

      // Get cancellations by reason
      final reasonQuery = '''
        SELECT reason, COUNT(*) as count
        FROM order_cancellations 
        WHERE $whereClause
        GROUP BY reason
        ORDER BY count DESC
      ''';
      final reasonResults = await _dbService.rawQuery(reasonQuery, whereArgs);

      // Get refund status breakdown
      final refundQuery = '''
        SELECT refund_status, COUNT(*) as count, SUM(refund_amount) as total_amount
        FROM order_cancellations 
        WHERE $whereClause AND refund_amount > 0
        GROUP BY refund_status
      ''';
      final refundResults = await _dbService.rawQuery(refundQuery, whereArgs);

      return {
        'total_cancellations': totalResult.first['total_cancellations'] ?? 0,
        'total_refund_amount': totalResult.first['total_refund_amount'] ?? 0.0,
        'cancellation_by_reason': reasonResults,
        'refund_status_breakdown': refundResults,
      };
    } catch (e, stackTrace) {
      Logger.error('OrderCancellationService', 'Failed to get cancellation statistics', 
                   error: e, stackTrace: stackTrace);
      return {
        'total_cancellations': 0,
        'total_refund_amount': 0.0,
        'cancellation_by_reason': [],
        'refund_status_breakdown': [],
      };
    }
  }

  /// Check if an order can be cancelled
  bool _canCancelOrder(Order order) {
    final status = OrderStatus.fromCode(order.status);
    
    // Orders can be cancelled if they are not yet delivered or already cancelled
    return status != OrderStatus.delivered && 
           status != OrderStatus.cancelled;
  }

  /// Get order details
  Future<Order?> _getOrder(String orderId) async {
    try {
      final orderMaps = await _dbService.select(
        'orders',
        where: 'unique_id = ?',
        whereArgs: [orderId],
        limit: 1,
      );

      if (orderMaps.isEmpty) {
        return null;
      }

      return Order.fromMap(orderMaps.first);
    } catch (e) {
      Logger.error('OrderCancellationService', 'Failed to get order: $orderId', error: e);
      return null;
    }
  }

  /// Validate cancellation reason
  bool isValidCancellationReason(CancellationReason reason, String? customReason) {
    if (reason == CancellationReason.other) {
      return customReason != null && customReason.trim().isNotEmpty;
    }
    return true;
  }

  /// Get cancellation reason display text
  String getCancellationReasonText(CancellationReason reason, String? customReason) {
    if (reason == CancellationReason.other && customReason != null) {
      return customReason;
    }
    return reason.displayName;
  }

  /// Check if order has pending refund
  Future<bool> hasPendingRefund(String orderId) async {
    try {
      final cancellation = await getCancellationDetails(orderId);
      return cancellation?.refundStatus == 'pending' && 
             cancellation?.refundAmount != null && 
             (cancellation?.refundAmount ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get payments for an order
  Future<List<Map<String, dynamic>>> _getPaymentsForOrder(String orderId) async {
    try {
      return await _dbService.select(
        'payments',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
    } catch (e) {
      Logger.error('OrderCancellationService', 'Failed to get payments for order: $orderId', error: e);
      return [];
    }
  }
}