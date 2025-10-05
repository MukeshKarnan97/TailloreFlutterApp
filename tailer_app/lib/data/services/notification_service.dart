import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';
import '../models/order_cancellation_model.dart';
import '../enums/order_enums.dart';
import 'local_db_service.dart';
import '../../core/utils/logger.dart';

/// Service for managing in-app notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final LocalDatabaseService _dbService = LocalDatabaseService();
  final ValueNotifier<List<NotificationModel>> _notifications = ValueNotifier([]);
  final ValueNotifier<int> _unreadCount = ValueNotifier(0);

  /// Get notifications stream
  ValueNotifier<List<NotificationModel>> get notificationsNotifier => _notifications;
  
  /// Get unread count stream
  ValueNotifier<int> get unreadCountNotifier => _unreadCount;

  /// Get current notifications list
  List<NotificationModel> get notifications => _notifications.value;

  /// Get current unread count
  int get unreadCount => _unreadCount.value;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      Logger.info('NotificationService', 'Initializing notification service');
      await _loadNotifications();
      Logger.info('NotificationService', 'Notification service initialized with ${notifications.length} notifications');
    } catch (e, stackTrace) {
      Logger.error('NotificationService', 'Failed to initialize notification service', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Load notifications from database
  Future<void> _loadNotifications() async {
    try {
      final notificationMaps = await _dbService.select(
        'notifications',
        orderBy: 'created_at DESC',
        limit: 50, // Load last 50 notifications
      );

      final loadedNotifications = notificationMaps
          .map((map) => NotificationModel.fromMap(map))
          .toList();

      _notifications.value = loadedNotifications;
      _updateUnreadCount();
      
      Logger.debug('NotificationService', 'Loaded ${loadedNotifications.length} notifications');
    } catch (e, stackTrace) {
      Logger.error('NotificationService', 'Failed to load notifications', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Update unread count
  void _updateUnreadCount() {
    final count = notifications.where((n) => !n.isRead).length;
    _unreadCount.value = count;
    Logger.debug('NotificationService', 'Unread count updated: $count');
  }

  /// Create and save notification
  Future<NotificationModel> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? orderId,
    String? customerId,
    String? actionUrl,
  }) async {
    try {
      final notification = NotificationModel.create(
        title: title,
        message: message,
        type: type.code,
        data: data,
        orderId: orderId,
        customerId: customerId,
        actionUrl: actionUrl,
      );

      try {
        await _dbService.insert('notifications', notification.toMap());
      } catch (dbError) {
        Logger.error('NotificationService', 'Failed to insert into notifications: $dbError');
        // If database insert fails, we can still continue with the notification in memory
        // This prevents cancellation from failing due to notification issues
      }
      
      // Add to local list and update UI (even if DB insert failed)
      final updatedNotifications = [notification, ...notifications];
      _notifications.value = updatedNotifications;
      _updateUnreadCount();
      
      Logger.info('NotificationService', 'Created notification: ${notification.title}');
      return notification;
    } catch (e, stackTrace) {
      Logger.error('NotificationService', 'Failed to create notification', 
                   error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _dbService.update(
        'notifications',
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [notificationId],
      );

      // Update local list
      final updatedNotifications = notifications.map((n) {
        return n.id == notificationId ? n.markAsRead() : n;
      }).toList();
      
      _notifications.value = updatedNotifications;
      _updateUnreadCount();
      
      Logger.debug('NotificationService', 'Marked notification as read: $notificationId');
    } catch (e, stackTrace) {
      Logger.error('NotificationService', 'Failed to mark notification as read', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _dbService.update(
        'notifications',
        {'is_read': 1},
        where: 'is_read = ?',
        whereArgs: [0],
      );

      // Update local list
      final updatedNotifications = notifications.map((n) => n.markAsRead()).toList();
      _notifications.value = updatedNotifications;
      _updateUnreadCount();
      
      Logger.info('NotificationService', 'Marked all notifications as read');
    } catch (e, stackTrace) {
      Logger.error('NotificationService', 'Failed to mark all notifications as read', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dbService.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [notificationId],
      );

      // Update local list
      final updatedNotifications = notifications.where((n) => n.id != notificationId).toList();
      _notifications.value = updatedNotifications;
      _updateUnreadCount();
      
      Logger.debug('NotificationService', 'Deleted notification: $notificationId');
    } catch (e, stackTrace) {
      Logger.error('NotificationService', 'Failed to delete notification', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _dbService.delete(
        'notifications',
        where: '1=1', // Delete all rows
        whereArgs: [],
      );
      _notifications.value = [];
      _updateUnreadCount();
      
      Logger.info('NotificationService', 'Cleared all notifications');
    } catch (e, stackTrace) {
      Logger.error('NotificationService', 'Failed to clear all notifications', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Get notifications for specific order
  List<NotificationModel> getNotificationsForOrder(String orderId) {
    return notifications.where((n) => n.orderId == orderId).toList();
  }

  /// Get notifications for specific customer
  List<NotificationModel> getNotificationsForCustomer(String customerId) {
    return notifications.where((n) => n.customerId == customerId).toList();
  }

  /// Refresh notifications from database
  Future<void> refresh() async {
    await _loadNotifications();
  }

  /// Create order status update notification
  Future<NotificationModel> notifyOrderStatusUpdate(Order order, String oldStatus, String newStatus) async {
    final title = 'Order Status Updated';
    final message = 'Order ${order.uniqueId} status changed from ${oldStatus.toUpperCase()} to ${newStatus.toUpperCase()}';
    
    return await createNotification(
      title: title,
      message: message,
      type: NotificationType.orderStatusUpdate,
      orderId: order.uniqueId,
      customerId: order.customerId,
      actionUrl: '/orders/detail?id=${order.uniqueId}',
      data: {
        'old_status': oldStatus,
        'new_status': newStatus,
        'order_id': order.uniqueId,
        'customer_id': order.customerId,
      },
    );
  }

  /// Create order cancellation notification
  Future<NotificationModel> notifyOrderCancellation(Order order, OrderCancellation cancellation) async {
    final title = 'Order Cancelled';
    final message = 'Order ${order.uniqueId} has been cancelled. Reason: ${cancellation.reasonDisplayText}';
    
    return await createNotification(
      title: title,
      message: message,
      type: NotificationType.orderCancelled,
      orderId: order.uniqueId,
      customerId: order.customerId,
      actionUrl: '/orders/detail?id=${order.uniqueId}',
      data: {
        'order_id': order.uniqueId,
        'customer_id': order.customerId,
        'cancellation_reason': cancellation.reason,
        'refund_amount': cancellation.refundAmount,
      },
    );
  }

  /// Create payment received notification
  Future<NotificationModel> notifyPaymentReceived(Order order, double amount) async {
    final title = 'Payment Received';
    final message = 'Payment of ₹${amount.toStringAsFixed(0)} received for order ${order.uniqueId}';
    
    return await createNotification(
      title: title,
      message: message,
      type: NotificationType.paymentReceived,
      orderId: order.uniqueId,
      customerId: order.customerId,
      actionUrl: '/orders/detail?id=${order.uniqueId}',
      data: {
        'order_id': order.uniqueId,
        'customer_id': order.customerId,
        'payment_amount': amount,
      },
    );
  }

  /// Create order delivered notification
  Future<NotificationModel> notifyOrderDelivered(Order order) async {
    final title = 'Order Delivered';
    final message = 'Order ${order.uniqueId} has been successfully delivered';
    
    return await createNotification(
      title: title,
      message: message,
      type: NotificationType.orderDelivered,
      orderId: order.uniqueId,
      customerId: order.customerId,
      actionUrl: '/orders/detail?id=${order.uniqueId}',
      data: {
        'order_id': order.uniqueId,
        'customer_id': order.customerId,
      },
    );
  }

  /// Create order overdue notification
  Future<NotificationModel> notifyOrderOverdue(Order order) async {
    final title = 'Order Overdue';
    final message = 'Order ${order.uniqueId} is overdue. Delivery was scheduled for ${order.deliveryDate.toString().substring(0, 10)}';
    
    return await createNotification(
      title: title,
      message: message,
      type: NotificationType.orderOverdue,
      orderId: order.uniqueId,
      customerId: order.customerId,
      actionUrl: '/orders/detail?id=${order.uniqueId}',
      data: {
        'order_id': order.uniqueId,
        'customer_id': order.customerId,
        'delivery_date': order.deliveryDate.toIso8601String(),
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _notifications.dispose();
    _unreadCount.dispose();
  }
}
