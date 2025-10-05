import 'dart:convert';

/// Notification model for in-app notifications
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // order_status_update, payment_received, etc.
  final Map<String, dynamic> data; // Additional data like orderId, customerId
  final DateTime createdAt;
  final bool isRead;
  final String? orderId;
  final String? customerId;
  final String? actionUrl; // Deep link or route to navigate to

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.data,
    required this.createdAt,
    this.isRead = false,
    this.orderId,
    this.customerId,
    this.actionUrl,
  });

  /// Factory constructor for creating notification
  factory NotificationModel.create({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
    String? orderId,
    String? customerId,
    String? actionUrl,
  }) {
    final now = DateTime.now();
    final id = 'NOTIF_${now.millisecondsSinceEpoch}';
    
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      data: data ?? {},
      createdAt: now,
      isRead: false,
      orderId: orderId,
      customerId: customerId,
      actionUrl: actionUrl,
    );
  }

  /// Create from database map
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      data: map['data'] != null ? 
        (map['data'] is String ? 
          jsonDecode(map['data']) : 
          Map<String, dynamic>.from(map['data'])) : {},
      createdAt: map['created_at'] != null ? 
        DateTime.parse(map['created_at']) : 
        DateTime.now(),
      isRead: (map['is_read'] as int?) == 1,
      orderId: map['order_id']?.toString(),
      customerId: map['customer_id']?.toString(),
      actionUrl: map['action_url']?.toString(),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'data': jsonEncode(data),
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'order_id': orderId,
      'customer_id': customerId,
      'action_url': actionUrl,
    };
  }

  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? orderId,
    String? customerId,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  /// Mark as read
  NotificationModel markAsRead() {
    return copyWith(isRead: true);
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}