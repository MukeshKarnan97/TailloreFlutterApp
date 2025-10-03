import 'dart:convert';
import 'dart:math';
import '../enums/payment_method.dart';

/// Payment model for managing payment transactions
class Payment {
  final String id;
  final String uniqueId;
  final String orderId;
  final double amount;
  final PaymentMethod method;
  final String notes;
  final String? transactionId;
  final DateTime paidOn;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const Payment({
    required this.id,
    required this.uniqueId,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.notes,
    this.transactionId,
    required this.paidOn,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  /// Generate stylish 10-character unique ID: PAY + 7 random characters
  static String _generateStylishId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String suffix = '';
    for (int i = 0; i < 7; i++) {
      suffix += chars[random.nextInt(chars.length)];
    }
    return 'PAY$suffix';
  }

  /// Create a new payment instance
  factory Payment.create({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String notes = '',
    String? transactionId,
    DateTime? paidOn,
  }) {
    final now = DateTime.now();
    final uniqueId = _generateStylishId();
    
    return Payment(
      id: uniqueId,
      uniqueId: uniqueId,
      orderId: orderId,
      amount: amount,
      method: method,
      notes: notes,
      transactionId: transactionId,
      paidOn: paidOn ?? now,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }

  /// Create from database map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id']?.toString() ?? '',
      uniqueId: map['unique_id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      method: PaymentMethod.fromString(map['method']?.toString() ?? 'cash'),
      notes: map['notes']?.toString() ?? '',
      transactionId: map['transaction_id']?.toString(),
      paidOn: DateTime.parse(map['paid_on']?.toString() ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unique_id': uniqueId,
      'order_id': orderId,
      'amount': amount,
      'method': method.value,
      'notes': notes,
      'transaction_id': transactionId,
      'paid_on': paidOn.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  /// Convert to JSON string
  String toJson() => jsonEncode(toMap());

  /// Create from JSON string
  factory Payment.fromJson(String source) => Payment.fromMap(jsonDecode(source));

  /// Copy with new values
  Payment copyWith({
    String? id,
    String? uniqueId,
    String? orderId,
    double? amount,
    PaymentMethod? method,
    String? notes,
    String? transactionId,
    DateTime? paidOn,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Payment(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      notes: notes ?? this.notes,
      transactionId: transactionId ?? this.transactionId,
      paidOn: paidOn ?? this.paidOn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Get formatted amount
  String getFormattedAmount({String currency = '₹'}) {
    return '$currency${amount.toStringAsFixed(2)}';
  }

  /// Get method display name
  String getMethodDisplayName() {
    return method.displayName;
  }

  /// Get formatted date
  String getFormattedDate() {
    return '${paidOn.day}/${paidOn.month}/${paidOn.year}';
  }

  /// Get formatted date and time
  String getFormattedDateTime() {
    return '${getFormattedDate()} at ${paidOn.hour.toString().padLeft(2, '0')}:${paidOn.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Payment(id: $id, uniqueId: $uniqueId, orderId: $orderId, '
           'amount: $amount, method: ${method.value}, paidOn: $paidOn, '
           'isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Payment &&
           other.uniqueId == uniqueId &&
           other.orderId == orderId &&
           other.amount == amount &&
           other.paidOn == paidOn;
  }

  @override
  int get hashCode {
    return uniqueId.hashCode ^ orderId.hashCode ^ amount.hashCode ^ paidOn.hashCode;
  }
}
