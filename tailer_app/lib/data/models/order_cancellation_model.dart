import 'dart:convert';

/// Order cancellation model
class OrderCancellation {
  final String id;
  final String orderId;
  final String reason;
  final String? customReason;
  final String cancelledBy; // tailor_id or customer_id
  final DateTime cancelledAt;
  final double refundAmount;
  final String refundStatus; // pending, completed, not_applicable
  final String? refundNotes;
  final Map<String, dynamic> additionalData;

  const OrderCancellation({
    required this.id,
    required this.orderId,
    required this.reason,
    this.customReason,
    required this.cancelledBy,
    required this.cancelledAt,
    this.refundAmount = 0.0,
    this.refundStatus = 'not_applicable',
    this.refundNotes,
    this.additionalData = const {},
  });

  /// Factory constructor for creating cancellation
  factory OrderCancellation.create({
    required String orderId,
    required String reason,
    String? customReason,
    required String cancelledBy,
    double refundAmount = 0.0,
    String refundStatus = 'not_applicable',
    String? refundNotes,
    Map<String, dynamic>? additionalData,
  }) {
    final now = DateTime.now();
    final id = 'CANCEL_${now.millisecondsSinceEpoch}';
    
    return OrderCancellation(
      id: id,
      orderId: orderId,
      reason: reason,
      customReason: customReason,
      cancelledBy: cancelledBy,
      cancelledAt: now,
      refundAmount: refundAmount,
      refundStatus: refundStatus,
      refundNotes: refundNotes,
      additionalData: additionalData ?? {},
    );
  }

  /// Create from database map
  factory OrderCancellation.fromMap(Map<String, dynamic> map) {
    return OrderCancellation(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      customReason: map['custom_reason']?.toString(),
      cancelledBy: map['cancelled_by']?.toString() ?? '',
      cancelledAt: map['cancelled_at'] != null ? 
        DateTime.parse(map['cancelled_at']) : 
        DateTime.now(),
      refundAmount: (map['refund_amount'] as num?)?.toDouble() ?? 0.0,
      refundStatus: map['refund_status']?.toString() ?? 'not_applicable',
      refundNotes: map['refund_notes']?.toString(),
      additionalData: map['additional_data'] != null ? 
        (map['additional_data'] is String ? 
          jsonDecode(map['additional_data']) : 
          Map<String, dynamic>.from(map['additional_data'])) : {},
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'order_id': orderId,
      'reason': reason,
      'custom_reason': customReason,
      'cancelled_by': cancelledBy,
      'cancelled_at': cancelledAt.toIso8601String(),
      'refund_amount': refundAmount,
      'refund_status': refundStatus,
      'refund_notes': refundNotes,
      'additional_data': jsonEncode(additionalData),
      'created_at': now,
      'updated_at': now,
    };
  }

  /// Create a copy with updated fields
  OrderCancellation copyWith({
    String? id,
    String? orderId,
    String? reason,
    String? customReason,
    String? cancelledBy,
    DateTime? cancelledAt,
    double? refundAmount,
    String? refundStatus,
    String? refundNotes,
    Map<String, dynamic>? additionalData,
  }) {
    return OrderCancellation(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      reason: reason ?? this.reason,
      customReason: customReason ?? this.customReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      refundAmount: refundAmount ?? this.refundAmount,
      refundStatus: refundStatus ?? this.refundStatus,
      refundNotes: refundNotes ?? this.refundNotes,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Get display text for reason
  String get reasonDisplayText {
    switch (reason) {
      case 'customer_request':
        return 'Customer Request';
      case 'material_unavailable':
        return 'Material Unavailable';
      case 'design_complexity':
        return 'Design Too Complex';
      case 'time_constraints':
        return 'Time Constraints';
      case 'quality_issues':
        return 'Quality Issues';
      case 'payment_issues':
        return 'Payment Issues';
      case 'other':
        return customReason ?? 'Other';
      default:
        return 'Unknown Reason';
    }
  }

  /// Check if refund is required
  bool get requiresRefund {
    return refundAmount > 0;
  }

  /// Check if refund is pending
  bool get isRefundPending {
    return refundStatus == 'pending';
  }

  /// Check if refund is completed
  bool get isRefundCompleted {
    return refundStatus == 'completed';
  }

  @override
  String toString() {
    return 'OrderCancellation(id: $id, orderId: $orderId, reason: $reason, refundAmount: $refundAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderCancellation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}