import 'dart:convert';

/// Refund transaction model for handling payment refunds
class RefundTransaction {
  final String id;
  final String uniqueId;
  final String originalPaymentId;
  final String orderId;
  final double refundAmount;
  final String reason;
  final RefundStatus status;
  final RefundMethod method;
  final String? transactionId;
  final String processedBy;
  final DateTime processedAt;
  final String? notes;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RefundTransaction({
    required this.id,
    required this.uniqueId,
    required this.originalPaymentId,
    required this.orderId,
    required this.refundAmount,
    required this.reason,
    required this.status,
    required this.method,
    this.transactionId,
    required this.processedBy,
    required this.processedAt,
    this.notes,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Generate unique ID for refund
  static String _generateRefundId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'REF_$timestamp';
  }

  /// Create a new refund transaction
  factory RefundTransaction.create({
    required String originalPaymentId,
    required String orderId,
    required double refundAmount,
    required String reason,
    required String processedBy,
    RefundMethod method = RefundMethod.original,
    String? transactionId,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final uniqueId = _generateRefundId();
    
    return RefundTransaction(
      id: uniqueId,
      uniqueId: uniqueId,
      originalPaymentId: originalPaymentId,
      orderId: orderId,
      refundAmount: refundAmount,
      reason: reason,
      status: RefundStatus.pending,
      method: method,
      transactionId: transactionId,
      processedBy: processedBy,
      processedAt: now,
      notes: notes,
      metadata: metadata ?? {},
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from database map
  factory RefundTransaction.fromMap(Map<String, dynamic> map) {
    return RefundTransaction(
      id: map['id']?.toString() ?? '',
      uniqueId: map['unique_id']?.toString() ?? '',
      originalPaymentId: map['original_payment_id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      refundAmount: (map['refund_amount'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason']?.toString() ?? '',
      status: RefundStatus.fromString(map['status']?.toString() ?? 'pending'),
      method: RefundMethod.fromString(map['method']?.toString() ?? 'original'),
      transactionId: map['transaction_id']?.toString(),
      processedBy: map['processed_by']?.toString() ?? '',
      processedAt: map['processed_at'] != null ? 
        DateTime.parse(map['processed_at']) : DateTime.now(),
      notes: map['notes']?.toString(),
      metadata: map['metadata'] != null ? 
        (map['metadata'] is String ? 
          jsonDecode(map['metadata']) : 
          Map<String, dynamic>.from(map['metadata'])) : {},
      createdAt: map['created_at'] != null ? 
        DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? 
        DateTime.parse(map['updated_at']) : DateTime.now(),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unique_id': uniqueId,
      'original_payment_id': originalPaymentId,
      'order_id': orderId,
      'refund_amount': refundAmount,
      'reason': reason,
      'status': status.value,
      'method': method.value,
      'transaction_id': transactionId,
      'processed_by': processedBy,
      'processed_at': processedAt.toIso8601String(),
      'notes': notes,
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  RefundTransaction copyWith({
    String? id,
    String? uniqueId,
    String? originalPaymentId,
    String? orderId,
    double? refundAmount,
    String? reason,
    RefundStatus? status,
    RefundMethod? method,
    String? transactionId,
    String? processedBy,
    DateTime? processedAt,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RefundTransaction(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      originalPaymentId: originalPaymentId ?? this.originalPaymentId,
      orderId: orderId ?? this.orderId,
      refundAmount: refundAmount ?? this.refundAmount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      method: method ?? this.method,
      transactionId: transactionId ?? this.transactionId,
      processedBy: processedBy ?? this.processedBy,
      processedAt: processedAt ?? this.processedAt,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Check if refund is completed
  bool get isCompleted => status == RefundStatus.completed;

  /// Check if refund is pending
  bool get isPending => status == RefundStatus.pending;

  /// Check if refund failed
  bool get isFailed => status == RefundStatus.failed;

  /// Get display text for status
  String get statusDisplayText => status.displayName;

  /// Get display text for method
  String get methodDisplayText => method.displayName;

  @override
  String toString() {
    return 'RefundTransaction(id: $id, amount: $refundAmount, status: ${status.value})';
  }
}

/// Refund status enum
enum RefundStatus {
  pending('pending', 'Pending'),
  processing('processing', 'Processing'),
  completed('completed', 'Completed'),
  failed('failed', 'Failed'),
  cancelled('cancelled', 'Cancelled');

  const RefundStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static RefundStatus fromString(String value) {
    return RefundStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => RefundStatus.pending,
    );
  }
}

/// Refund method enum
enum RefundMethod {
  original('original', 'Original Payment Method'),
  cash('cash', 'Cash'),
  bankTransfer('bank_transfer', 'Bank Transfer'),
  storeCredit('store_credit', 'Store Credit');

  const RefundMethod(this.value, this.displayName);

  final String value;
  final String displayName;

  static RefundMethod fromString(String value) {
    return RefundMethod.values.firstWhere(
      (method) => method.value == value.toLowerCase(),
      orElse: () => RefundMethod.original,
    );
  }
}