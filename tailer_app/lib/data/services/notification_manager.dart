import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/logger.dart';
import '../models/order_model.dart';
import '../enums/order_enums.dart';

/// Notification Manager for handling local and push notifications
/// Handles system notifications, scheduled reminders, and push messages
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  Function(String?)? _onNotificationTap;
  
  // Notification channels
  static const String _channelIdOrders = 'orders_channel';
  static const String _channelIdPayments = 'payments_channel';
  static const String _channelIdReminders = 'reminders_channel';
  static const String _channelIdGeneral = 'general_channel';
  
  /// Initialize notification manager
  Future<void> initialize({Function(String?)? onNotificationTap}) async {
    if (_isInitialized) {
      Logger.debug('NotificationManager', 'Already initialized');
      return;
    }

    try {
      Logger.info('NotificationManager', 'Initializing notification manager...');
      
      _onNotificationTap = onNotificationTap;
      
      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Initialization settings for all platforms
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      // Initialize the plugin
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      
      // Request permissions
      await _requestPermissions();
      
      // Create notification channels (Android)
      await _createNotificationChannels();
      
      _isInitialized = true;
      Logger.info('NotificationManager', 'Notification manager initialized successfully');
    } catch (e, stackTrace) {
      Logger.error('NotificationManager', 'Failed to initialize', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      // Request Android 13+ notification permission
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        if (status.isPermanentlyDenied) {
          Logger.warning('NotificationManager', 'Notification permission permanently denied');
          return false;
        }
        return status.isGranted;
      }
      
      // iOS permissions
      final iosPermissions = await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
      return iosPermissions ?? true;
    } catch (e, stackTrace) {
      Logger.error('NotificationManager', 'Failed to request permissions', 
                   error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin == null) return;
      
      // Orders channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdOrders,
          'Order Updates',
          description: 'Notifications for order status changes',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
      
      // Payments channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdPayments,
          'Payment Updates',
          description: 'Notifications for payments and reminders',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
      
      // Reminders channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdReminders,
          'Reminders',
          description: 'Delivery and payment reminders',
          importance: Importance.defaultImportance,
          enableVibration: true,
          playSound: true,
        ),
      );
      
      // General channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdGeneral,
          'General Notifications',
          description: 'General app notifications',
          importance: Importance.defaultImportance,
          enableVibration: false,
          playSound: false,
        ),
      );
      
      Logger.debug('NotificationManager', 'Notification channels created');
    } catch (e, stackTrace) {
      Logger.error('NotificationManager', 'Failed to create channels', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Handle notification tap
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    Logger.debug('NotificationManager', 'Notification tapped with payload: $payload');
    _onNotificationTap?.call(payload);
  }

  /// Show instant notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationType? type,
  }) async {
    if (!_isInitialized) {
      Logger.warning('NotificationManager', 'Manager not initialized');
      return;
    }

    try {
      final channelId = _getChannelForType(type);
      
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
      
      Logger.info('NotificationManager', 'Showed notification: $title');
    } catch (e, stackTrace) {
      Logger.error('NotificationManager', 'Failed to show notification', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Schedule notification for future time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationType? type,
  }) async {
    if (!_isInitialized) {
      Logger.warning('NotificationManager', 'Manager not initialized');
      return;
    }

    try {
      final channelId = _getChannelForType(type);
      
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      
      Logger.info('NotificationManager', 
                  'Scheduled notification "$title" for ${scheduledTime.toString()}');
    } catch (e, stackTrace) {
      Logger.error('NotificationManager', 'Failed to schedule notification', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      Logger.debug('NotificationManager', 'Cancelled notification: $id');
    } catch (e, stackTrace) {
      Logger.error('NotificationManager', 'Failed to cancel notification', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      Logger.info('NotificationManager', 'Cancelled all notifications');
    } catch (e, stackTrace) {
      Logger.error('NotificationManager', 'Failed to cancel all notifications', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Schedule delivery reminder (1 day before delivery)
  Future<void> scheduleDeliveryReminder(Order order) async {
    try {
      final deliveryDate = order.deliveryDate;
      final reminderTime = deliveryDate.subtract(const Duration(days: 1, hours: 10)); // 10 AM day before
      
      if (reminderTime.isBefore(DateTime.now())) {
        Logger.debug('NotificationManager', 
                     'Delivery reminder time has passed for order ${order.uniqueId}');
        return;
      }
      
      final notificationId = _generateNotificationId(order.uniqueId, 'delivery');
      
      await scheduleNotification(
        id: notificationId,
        title: 'Delivery Tomorrow',
        body: 'Order ${order.uniqueId} is scheduled for delivery tomorrow at ${_formatTime(deliveryDate)}',
        scheduledTime: reminderTime,
        payload: jsonEncode({
          'type': 'delivery_reminder',
          'orderId': order.uniqueId,
          'customerId': order.customerId,
        }),
        type: NotificationType.reminderDelivery,
      );
      
      Logger.info('NotificationManager', 
                  'Scheduled delivery reminder for order ${order.uniqueId}');
    } catch (e, stackTrace) {
      Logger.error('NotificationManager', 'Failed to schedule delivery reminder', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Schedule payment reminder
  Future<void> schedulePaymentReminder(Order order, {int daysBeforeDelivery = 2}) async {
    try {
      final deliveryDate = order.deliveryDate;
      final reminderTime = deliveryDate.subtract(Duration(days: daysBeforeDelivery, hours: 15)); // 3 PM
      
      if (reminderTime.isBefore(DateTime.now())) {
        Logger.debug('NotificationManager', 
                     'Payment reminder time has passed for order ${order.uniqueId}');
        return;
      }
      
      final balanceAmount = order.totalAmount - order.advancePaid;
      if (balanceAmount <= 0) {
        Logger.debug('NotificationManager', 
                     'No balance amount for order ${order.uniqueId}, skipping payment reminder');
        return;
      }
      
      final notificationId = _generateNotificationId(order.uniqueId, 'payment');
      
      await scheduleNotification(
        id: notificationId,
        title: 'Payment Reminder',
        body: 'Balance amount ₹${balanceAmount.toStringAsFixed(0)} pending for order ${order.uniqueId}',
        scheduledTime: reminderTime,
        payload: jsonEncode({
          'type': 'payment_reminder',
          'orderId': order.uniqueId,
          'customerId': order.customerId,
          'amount': balanceAmount,
        }),
        type: NotificationType.reminderPayment,
      );
      
      Logger.info('NotificationManager', 
                  'Scheduled payment reminder for order ${order.uniqueId}');
    } catch (e, stackTrace) {
      Logger.error('NotificationManager', 'Failed to schedule payment reminder', 
                   error: e, stackTrace: stackTrace);
    }
  }

  /// Notify order status change
  Future<void> notifyOrderStatusChange(Order order, String oldStatus, String newStatus) async {
    final notificationId = _generateNotificationId(order.uniqueId, 'status');
    
    await showNotification(
      id: notificationId,
      title: 'Order Status Updated',
      body: 'Order ${order.uniqueId}: ${oldStatus.toUpperCase()} → ${newStatus.toUpperCase()}',
      payload: jsonEncode({
        'type': 'order_status',
        'orderId': order.uniqueId,
        'customerId': order.customerId,
        'oldStatus': oldStatus,
        'newStatus': newStatus,
      }),
      type: NotificationType.orderStatusUpdate,
    );
  }

  /// Notify payment received
  Future<void> notifyPaymentReceived(Order order, double amount) async {
    final notificationId = _generateNotificationId(order.uniqueId, 'payment_received');
    
    await showNotification(
      id: notificationId,
      title: 'Payment Received',
      body: 'Received ₹${amount.toStringAsFixed(0)} for order ${order.uniqueId}',
      payload: jsonEncode({
        'type': 'payment_received',
        'orderId': order.uniqueId,
        'customerId': order.customerId,
        'amount': amount,
      }),
      type: NotificationType.paymentReceived,
    );
  }

  /// Notify order delivered
  Future<void> notifyOrderDelivered(Order order) async {
    final notificationId = _generateNotificationId(order.uniqueId, 'delivered');
    
    await showNotification(
      id: notificationId,
      title: 'Order Delivered',
      body: 'Order ${order.uniqueId} has been successfully delivered',
      payload: jsonEncode({
        'type': 'order_delivered',
        'orderId': order.uniqueId,
        'customerId': order.customerId,
      }),
      type: NotificationType.orderDelivered,
    );
  }

  /// Notify order overdue
  Future<void> notifyOrderOverdue(Order order) async {
    final notificationId = _generateNotificationId(order.uniqueId, 'overdue');
    
    await showNotification(
      id: notificationId,
      title: 'Order Overdue',
      body: 'Order ${order.uniqueId} is overdue. Scheduled delivery: ${_formatDate(order.deliveryDate)}',
      payload: jsonEncode({
        'type': 'order_overdue',
        'orderId': order.uniqueId,
        'customerId': order.customerId,
        'deliveryDate': order.deliveryDate.toIso8601String(),
      }),
      type: NotificationType.orderOverdue,
    );
  }

  /// Notify order cancellation
  Future<void> notifyOrderCancellation(Order order, String reason) async {
    final notificationId = _generateNotificationId(order.uniqueId, 'cancelled');
    
    await showNotification(
      id: notificationId,
      title: 'Order Cancelled',
      body: 'Order ${order.uniqueId} has been cancelled. Reason: $reason',
      payload: jsonEncode({
        'type': 'order_cancelled',
        'orderId': order.uniqueId,
        'customerId': order.customerId,
        'reason': reason,
      }),
      type: NotificationType.orderCancelled,
    );
  }

  /// Cancel scheduled reminders for an order
  Future<void> cancelOrderReminders(String orderId) async {
    final deliveryReminderId = _generateNotificationId(orderId, 'delivery');
    final paymentReminderId = _generateNotificationId(orderId, 'payment');
    
    await cancelNotification(deliveryReminderId);
    await cancelNotification(paymentReminderId);
    
    Logger.debug('NotificationManager', 'Cancelled reminders for order $orderId');
  }

  /// Get channel ID for notification type
  String _getChannelForType(NotificationType? type) {
    if (type == null) return _channelIdGeneral;
    
    switch (type) {
      case NotificationType.orderStatusUpdate:
      case NotificationType.orderDelivered:
      case NotificationType.orderOverdue:
      case NotificationType.orderCancelled:
        return _channelIdOrders;
      case NotificationType.paymentReceived:
      case NotificationType.reminderPayment:
        return _channelIdPayments;
      case NotificationType.reminderDelivery:
        return _channelIdReminders;
    }
  }

  /// Get channel name
  String _getChannelName(String channelId) {
    switch (channelId) {
      case _channelIdOrders:
        return 'Order Updates';
      case _channelIdPayments:
        return 'Payment Updates';
      case _channelIdReminders:
        return 'Reminders';
      default:
        return 'General Notifications';
    }
  }

  /// Generate unique notification ID from order ID and type
  int _generateNotificationId(String orderId, String type) {
    final combined = '$orderId-$type';
    return combined.hashCode.abs();
  }

  /// Format date for notification
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format time for notification
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await Permission.notification.isGranted;
    }
    return true; // iOS handles this differently
  }

  /// Open app notification settings
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }
}
