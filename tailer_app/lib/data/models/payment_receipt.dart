import 'dart:convert';

/// Payment receipt model for generating and managing receipts
class PaymentReceipt {
  final String id;
  final String uniqueId;
  final String paymentId;
  final String orderId;
  final String customerId;
  final ReceiptType type;
  final double amount;
  final String paymentMethod;
  final DateTime receiptDate;
  final String receiptNumber;
  final Map<String, dynamic> businessDetails;
  final Map<String, dynamic> customerDetails;
  final Map<String, dynamic> itemDetails;
  final String? notes;
  final String? filePath;
  final bool isEmailSent;
  final bool isPrinted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentReceipt({
    required this.id,
    required this.uniqueId,
    required this.paymentId,
    required this.orderId,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.paymentMethod,
    required this.receiptDate,
    required this.receiptNumber,
    required this.businessDetails,
    required this.customerDetails,
    required this.itemDetails,
    this.notes,
    this.filePath,
    this.isEmailSent = false,
    this.isPrinted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Generate unique receipt number
  static String _generateReceiptNumber(ReceiptType type) {
    final now = DateTime.now();
    final prefix = type == ReceiptType.payment ? 'RCP' : 
                   type == ReceiptType.refund ? 'REF' : 'ADV';
    final datePart = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timePart = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '$prefix$datePart$timePart';
  }

  /// Generate unique ID for receipt
  static String _generateReceiptId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'RECEIPT_$timestamp';
  }

  /// Create a new payment receipt
  factory PaymentReceipt.create({
    required String paymentId,
    required String orderId,
    required String customerId,
    required ReceiptType type,
    required double amount,
    required String paymentMethod,
    required Map<String, dynamic> businessDetails,
    required Map<String, dynamic> customerDetails,
    required Map<String, dynamic> itemDetails,
    String? notes,
  }) {
    final now = DateTime.now();
    final uniqueId = _generateReceiptId();
    final receiptNumber = _generateReceiptNumber(type);
    
    return PaymentReceipt(
      id: uniqueId,
      uniqueId: uniqueId,
      paymentId: paymentId,
      orderId: orderId,
      customerId: customerId,
      type: type,
      amount: amount,
      paymentMethod: paymentMethod,
      receiptDate: now,
      receiptNumber: receiptNumber,
      businessDetails: businessDetails,
      customerDetails: customerDetails,
      itemDetails: itemDetails,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from database map
  factory PaymentReceipt.fromMap(Map<String, dynamic> map) {
    return PaymentReceipt(
      id: map['id']?.toString() ?? '',
      uniqueId: map['unique_id']?.toString() ?? '',
      paymentId: map['payment_id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      type: ReceiptType.fromString(map['type']?.toString() ?? 'payment'),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method']?.toString() ?? '',
      receiptDate: map['receipt_date'] != null ? 
        DateTime.parse(map['receipt_date']) : DateTime.now(),
      receiptNumber: map['receipt_number']?.toString() ?? '',
      businessDetails: map['business_details'] != null ? 
        (map['business_details'] is String ? 
          jsonDecode(map['business_details']) : 
          Map<String, dynamic>.from(map['business_details'])) : {},
      customerDetails: map['customer_details'] != null ? 
        (map['customer_details'] is String ? 
          jsonDecode(map['customer_details']) : 
          Map<String, dynamic>.from(map['customer_details'])) : {},
      itemDetails: map['item_details'] != null ? 
        (map['item_details'] is String ? 
          jsonDecode(map['item_details']) : 
          Map<String, dynamic>.from(map['item_details'])) : {},
      notes: map['notes']?.toString(),
      filePath: map['file_path']?.toString(),
      isEmailSent: (map['is_email_sent'] as int?) == 1,
      isPrinted: (map['is_printed'] as int?) == 1,
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
      'payment_id': paymentId,
      'order_id': orderId,
      'customer_id': customerId,
      'type': type.value,
      'amount': amount,
      'payment_method': paymentMethod,
      'receipt_date': receiptDate.toIso8601String(),
      'receipt_number': receiptNumber,
      'business_details': jsonEncode(businessDetails),
      'customer_details': jsonEncode(customerDetails),
      'item_details': jsonEncode(itemDetails),
      'notes': notes,
      'file_path': filePath,
      'is_email_sent': isEmailSent ? 1 : 0,
      'is_printed': isPrinted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  PaymentReceipt copyWith({
    String? id,
    String? uniqueId,
    String? paymentId,
    String? orderId,
    String? customerId,
    ReceiptType? type,
    double? amount,
    String? paymentMethod,
    DateTime? receiptDate,
    String? receiptNumber,
    Map<String, dynamic>? businessDetails,
    Map<String, dynamic>? customerDetails,
    Map<String, dynamic>? itemDetails,
    String? notes,
    String? filePath,
    bool? isEmailSent,
    bool? isPrinted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentReceipt(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      paymentId: paymentId ?? this.paymentId,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptDate: receiptDate ?? this.receiptDate,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      businessDetails: businessDetails ?? this.businessDetails,
      customerDetails: customerDetails ?? this.customerDetails,
      itemDetails: itemDetails ?? this.itemDetails,
      notes: notes ?? this.notes,
      filePath: filePath ?? this.filePath,
      isEmailSent: isEmailSent ?? this.isEmailSent,
      isPrinted: isPrinted ?? this.isPrinted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Mark receipt as emailed
  PaymentReceipt markAsEmailed([String? filePath]) {
    return copyWith(
      isEmailSent: true,
      filePath: filePath ?? this.filePath,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark receipt as printed
  PaymentReceipt markAsPrinted() {
    return copyWith(
      isPrinted: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Get display text for type
  String get typeDisplayText => type.displayName;

  /// Get formatted receipt number
  String get formattedReceiptNumber => receiptNumber;

  /// Get formatted amount
  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';

  @override
  String toString() {
    return 'PaymentReceipt(number: $receiptNumber, amount: $amount, type: ${type.value})';
  }
}

/// Receipt type enum
enum ReceiptType {
  payment('payment', 'Payment Receipt'),
  refund('refund', 'Refund Receipt'),
  advance('advance', 'Advance Receipt');

  const ReceiptType(this.value, this.displayName);

  final String value;
  final String displayName;

  static ReceiptType fromString(String value) {
    return ReceiptType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => ReceiptType.payment,
    );
  }
}