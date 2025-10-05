import 'package:flutter/material.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/enums/order_enums.dart';

/// Widget to display notifications list
class NotificationListWidget extends StatefulWidget {
  final bool showOnlyUnread;
  final int? maxItems;

  const NotificationListWidget({
    super.key,
    this.showOnlyUnread = false,
    this.maxItems,
  });

  @override
  State<NotificationListWidget> createState() => _NotificationListWidgetState();
}

class _NotificationListWidgetState extends State<NotificationListWidget> {
  final NotificationService _notificationService = NotificationService();
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _notificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ValueListenableBuilder<List<NotificationModel>>(
          valueListenable: _notificationService.notificationsNotifier,
          builder: (context, notifications, _) {
            var filteredNotifications = notifications;

            if (widget.showOnlyUnread) {
              filteredNotifications = notifications.where((n) => !n.isRead).toList();
            }

            if (widget.maxItems != null && filteredNotifications.length > widget.maxItems!) {
              filteredNotifications = filteredNotifications.take(widget.maxItems!).toList();
            }

            if (filteredNotifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.showOnlyUnread ? 'No unread notifications' : 'No notifications',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: filteredNotifications.length,
              itemBuilder: (context, index) {
                final notification = filteredNotifications[index];
                return NotificationTile(
                  notification: notification,
                  onTap: () => _markAsRead(notification),
                  onDismiss: () => _deleteNotification(notification),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    await _notificationService.deleteNotification(notification.id);
  }
}

/// Individual notification tile widget
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDismiss?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: notification.isRead ? 1 : 3,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getNotificationColor(notification.type),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                notification.timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: onTap,
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    final notificationType = NotificationType.fromCode(type);
    switch (notificationType) {
      case NotificationType.orderStatusUpdate:
        return Colors.blue;
      case NotificationType.orderCancelled:
        return Colors.red;
      case NotificationType.paymentReceived:
        return Colors.green;
      case NotificationType.orderDelivered:
        return Colors.purple;
      case NotificationType.orderOverdue:
        return Colors.orange;
      case NotificationType.reminderPayment:
        return Colors.amber;
      case NotificationType.reminderDelivery:
        return Colors.indigo;
    }
  }

  IconData _getNotificationIcon(String type) {
    final notificationType = NotificationType.fromCode(type);
    switch (notificationType) {
      case NotificationType.orderStatusUpdate:
        return Icons.update;
      case NotificationType.orderCancelled:
        return Icons.cancel;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.orderDelivered:
        return Icons.local_shipping;
      case NotificationType.orderOverdue:
        return Icons.warning;
      case NotificationType.reminderPayment:
        return Icons.money_off;
      case NotificationType.reminderDelivery:
        return Icons.schedule;
    }
  }
}

/// Notification badge widget showing unread count
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final NotificationService notificationService;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: notificationService.unreadCountNotifier,
      builder: (context, unreadCount, _) {
        return Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
          child: child,
        );
      },
    );
  }
}