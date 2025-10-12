import 'dart:convert';
import 'dart:math';

/// Order model for managing customer orders
class Order {
  final String id;
  final String uniqueId;
  final String customerId;
  final String tailorId;
  final String serviceType; // This will be dress type
  final String status;
  final String paymentStatus; // Added payment status
  final DateTime deliveryDate;
  final String notes;
  final String? designImageUrl;
  final double totalAmount;
  final double advancePaid;
  final double balanceAmount;
  final Map<String, double> measurements; // Store measurements for this order
  final String? measurementId; // Reference to measurement table (NEW)
  final String? imagePath1; // First garment image
  final String? imagePath2; // Second garment image
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const Order({
    required this.id,
    required this.uniqueId,
    required this.customerId,
    required this.tailorId,
    required this.serviceType,
    required this.status,
    required this.paymentStatus,
    required this.deliveryDate,
    required this.notes,
    this.designImageUrl,
    required this.totalAmount,
    required this.advancePaid,
    required this.balanceAmount,
    required this.measurements,
    this.measurementId, // NEW: Optional reference to measurement
    this.imagePath1, // Optional first garment image
    this.imagePath2, // Optional second garment image
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  /// Generate stylish 10-character unique ID: ORD + 7 random characters
  static String _generateStylishId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String suffix = '';
    for (int i = 0; i < 7; i++) {
      suffix += chars[random.nextInt(chars.length)];
    }
    return 'ORD$suffix';
  }

  /// Create a new order instance
  factory Order.create({
    required String customerId,
    required String tailorId,
    required String serviceType,
    required String status,
    String paymentStatus = 'pending',
    required DateTime deliveryDate,
    required String notes,
    String? designImageUrl,
    required double totalAmount,
    required double advancePaid,
    required double balanceAmount,
    required Map<String, double> measurements,
    String? measurementId, // NEW: Optional measurement reference
    String? imagePath1, // Optional first garment image
    String? imagePath2, // Optional second garment image
  }) {
    final now = DateTime.now();
    final uniqueId = _generateStylishId();
    
    return Order(
      id: uniqueId,
      uniqueId: uniqueId,
      customerId: customerId,
      tailorId: tailorId,
      serviceType: serviceType,
      status: status,
      paymentStatus: paymentStatus,
      deliveryDate: deliveryDate,
      notes: notes,
      designImageUrl: designImageUrl,
      totalAmount: totalAmount,
      advancePaid: advancePaid,
      balanceAmount: balanceAmount,
      measurements: Map<String, double>.from(measurements),
      measurementId: measurementId, // NEW
      imagePath1: imagePath1, // NEW
      imagePath2: imagePath2, // NEW
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }

  /// Create from database map
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id']?.toString() ?? '',
      uniqueId: map['unique_id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      tailorId: map['tailor_id']?.toString() ?? '',
      serviceType: map['service_type']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      paymentStatus: map['payment_status']?.toString() ?? 'pending',
      deliveryDate: DateTime.parse(map['delivery_date']?.toString() ?? DateTime.now().toIso8601String()),
      notes: map['notes']?.toString() ?? '',
      designImageUrl: map['design_image_url']?.toString(),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      advancePaid: (map['advance_paid'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (map['balance_amount'] as num?)?.toDouble() ?? 0.0,
      measurements: _parseMeasurements(map['measurements']),
      measurementId: map['measurement_id']?.toString(), // NEW
      imagePath1: map['image_path_1']?.toString(), // NEW
      imagePath2: map['image_path_2']?.toString(), // NEW
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  /// Parse measurements from JSON string or map
  static Map<String, double> _parseMeasurements(dynamic measurementsData) {
    if (measurementsData == null) return <String, double>{};
    
    try {
      Map<String, dynamic> parsedData;
      if (measurementsData is String) {
        parsedData = jsonDecode(measurementsData);
      } else if (measurementsData is Map<String, dynamic>) {
        parsedData = measurementsData;
      } else {
        return <String, double>{};
      }
      
      return parsedData.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      return <String, double>{};
    }
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unique_id': uniqueId,
      'customer_id': customerId,
      'tailor_id': tailorId,
      'service_type': serviceType,
      'status': status,
      'payment_status': paymentStatus,
      'delivery_date': deliveryDate.toIso8601String(),
      'notes': notes,
      'design_image_url': designImageUrl,
      'total_amount': totalAmount,
      'advance_paid': advancePaid,
      'balance_amount': balanceAmount,
      'measurements': jsonEncode(measurements),
      'measurement_id': measurementId, // NEW
      'image_path_1': imagePath1, // NEW
      'image_path_2': imagePath2, // NEW
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  /// Convert to JSON string
  String toJson() => jsonEncode(toMap());

  /// Create from JSON string
  factory Order.fromJson(String source) => Order.fromMap(jsonDecode(source));

  /// Copy with new values
  Order copyWith({
    String? id,
    String? uniqueId,
    String? customerId,
    String? tailorId,
    String? serviceType,
    String? status,
    String? paymentStatus,
    DateTime? deliveryDate,
    String? notes,
    String? designImageUrl,
    double? totalAmount,
    double? advancePaid,
    double? balanceAmount,
    Map<String, double>? measurements,
    String? measurementId, // NEW
    String? imagePath1, // NEW
    String? imagePath2, // NEW
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Order(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      customerId: customerId ?? this.customerId,
      tailorId: tailorId ?? this.tailorId,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      designImageUrl: designImageUrl ?? this.designImageUrl,
      totalAmount: totalAmount ?? this.totalAmount,
      advancePaid: advancePaid ?? this.advancePaid,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      measurements: measurements ?? Map<String, double>.from(this.measurements),
      measurementId: measurementId ?? this.measurementId, // NEW
      imagePath1: imagePath1 ?? this.imagePath1, // NEW
      imagePath2: imagePath2 ?? this.imagePath2, // NEW
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Get a specific measurement value
  double? getMeasurement(String measurementKey) {
    return measurements[measurementKey];
  }

  /// Check if measurement exists
  bool hasMeasurement(String measurementKey) {
    return measurements.containsKey(measurementKey) && 
           measurements[measurementKey] != null &&
           measurements[measurementKey]! > 0;
  }

  /// Get formatted measurement value with unit
  String getFormattedMeasurement(String measurementKey, {String unit = 'inches'}) {
    final value = getMeasurement(measurementKey);
    if (value == null || value <= 0) return 'Not specified';
    return '${value.toStringAsFixed(1)} $unit';
  }

  /// Get status color
  String getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA726'; // Orange
      case 'in_progress':
        return '#42A5F5'; // Blue
      case 'completed':
        return '#66BB6A'; // Green
      case 'delivered':
        return '#4CAF50'; // Dark Green
      case 'cancelled':
        return '#EF5350'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Get status display name
  String getStatusDisplayName() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Get payment status display name
  String getPaymentStatusDisplayName() {
    switch (paymentStatus.toLowerCase()) {
      case 'pending':
        return 'Payment Pending';
      case 'partial':
        return 'Partially Paid';
      case 'paid':
        return 'Fully Paid';
      case 'overdue':
        return 'Overdue';
      default:
        return paymentStatus;
    }
  }

  /// Get payment status color
  String getPaymentStatusColor() {
    switch (paymentStatus.toLowerCase()) {
      case 'pending':
        return '#FFA726'; // Orange
      case 'partial':
        return '#42A5F5'; // Blue
      case 'paid':
        return '#66BB6A'; // Green
      case 'overdue':
        return '#EF5350'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Check if payment is pending
  bool get isPaymentPending => paymentStatus.toLowerCase() == 'pending';

  /// Check if payment is partial
  bool get isPaymentPartial => paymentStatus.toLowerCase() == 'partial';

  /// Check if payment is complete
  bool get isPaymentComplete => paymentStatus.toLowerCase() == 'paid';

  /// Check if payment is overdue
  bool get isPaymentOverdue => paymentStatus.toLowerCase() == 'overdue';

  /// Get remaining balance amount
  double get remainingBalance => totalAmount - advancePaid;

  /// Check if order has balance amount
  bool get hasBalance => remainingBalance > 0;

  /// Get payment completion percentage
  double get paymentPercentage => totalAmount > 0 ? (advancePaid / totalAmount) * 100 : 0;

  @override
  String toString() {
    return 'Order(id: $id, uniqueId: $uniqueId, customerId: $customerId, '
           'tailorId: $tailorId, serviceType: $serviceType, status: $status, '
           'deliveryDate: $deliveryDate, totalAmount: $totalAmount, '
           'measurements: $measurements, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Order &&
           other.uniqueId == uniqueId &&
           other.customerId == customerId &&
           other.serviceType == serviceType;
  }

  @override
  int get hashCode {
    return uniqueId.hashCode ^ customerId.hashCode ^ serviceType.hashCode;
  }
}
