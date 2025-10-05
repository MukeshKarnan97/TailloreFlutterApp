/// Order cancellation reasons enum
enum CancellationReason {
  customerRequest('customer_request', 'Customer Request'),
  materialUnavailable('material_unavailable', 'Material Unavailable'),
  designComplexity('design_complexity', 'Design Too Complex'),
  timeConstraints('time_constraints', 'Time Constraints'),
  qualityIssues('quality_issues', 'Quality Issues'),
  paymentIssues('payment_issues', 'Payment Issues'),
  other('other', 'Other');

  const CancellationReason(this.code, this.displayName);
  
  final String code;
  final String displayName;

  static CancellationReason fromCode(String code) {
    return CancellationReason.values.firstWhere(
      (reason) => reason.code == code,
      orElse: () => CancellationReason.other,
    );
  }
}

/// Order status enum for better type safety
enum OrderStatus {
  pending('pending', 'Pending'),
  cutting('cutting', 'Cutting'),
  stitching('stitching', 'Stitching'),
  inProgress('in_progress', 'In Progress'),
  ready('ready', 'Ready'),
  completed('completed', 'Completed'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled');

  const OrderStatus(this.code, this.displayName);
  
  final String code;
  final String displayName;

  static OrderStatus fromCode(String code) {
    return OrderStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => OrderStatus.pending,
    );
  }

  /// Get available next statuses based on current status
  List<OrderStatus> getAvailableTransitions() {
    switch (this) {
      case OrderStatus.pending:
        return [OrderStatus.pending, OrderStatus.cutting, OrderStatus.stitching, OrderStatus.inProgress, OrderStatus.cancelled];
      case OrderStatus.cutting:
        return [OrderStatus.cutting, OrderStatus.stitching, OrderStatus.inProgress, OrderStatus.ready, OrderStatus.cancelled];
      case OrderStatus.stitching:
        return [OrderStatus.stitching, OrderStatus.inProgress, OrderStatus.ready, OrderStatus.cancelled];
      case OrderStatus.inProgress:
        return [OrderStatus.inProgress, OrderStatus.ready, OrderStatus.completed, OrderStatus.cancelled];
      case OrderStatus.ready:
        return [OrderStatus.ready, OrderStatus.completed, OrderStatus.delivered];
      case OrderStatus.completed:
        return [OrderStatus.completed, OrderStatus.delivered];
      case OrderStatus.delivered:
        return [OrderStatus.delivered];
      case OrderStatus.cancelled:
        return [OrderStatus.cancelled]; // Cannot change from cancelled
    }
  }

  /// Check if status can be cancelled
  bool get canBeCancelled {
    return this != OrderStatus.completed && 
           this != OrderStatus.delivered && 
           this != OrderStatus.cancelled;
  }
}

/// Notification type enum
enum NotificationType {
  orderStatusUpdate('order_status_update', 'Order Status Update'),
  orderCancelled('order_cancelled', 'Order Cancelled'),
  paymentReceived('payment_received', 'Payment Received'),
  orderDelivered('order_delivered', 'Order Delivered'),
  orderOverdue('order_overdue', 'Order Overdue'),
  reminderPayment('reminder_payment', 'Payment Reminder'),
  reminderDelivery('reminder_delivery', 'Delivery Reminder');

  const NotificationType(this.code, this.displayName);
  
  final String code;
  final String displayName;

  static NotificationType fromCode(String code) {
    return NotificationType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => NotificationType.orderStatusUpdate,
    );
  }
}