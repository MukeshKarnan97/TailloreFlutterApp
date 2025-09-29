import 'dart:math';

class Order {
  final String id;
  final String uniqueId;
  final String customerId;
  final String tailorId;
  final String serviceType;
  final String status;
  final DateTime deliveryDate;
  final String notes;
  final String? designImageUrl;
  final double totalAmount;
  final double advancePaid;
  final double balanceAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.uniqueId,
    required this.customerId,
    required this.tailorId,
    required this.serviceType,
    required this.status,
    required this.deliveryDate,
    required this.notes,
    this.designImageUrl,
    required this.totalAmount,
    required this.advancePaid,
    required this.balanceAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Generate stylish 10-character unique ID: MAT + 7 random characters
  static String _generateStylishId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String suffix = '';
    for (int i = 0; i < 7; i++) {
      suffix += chars[random.nextInt(chars.length)];
    }
    return 'MAT$suffix';
  }

  factory Order.create({
    required String customerId,
    required String tailorId,
    required String serviceType,
    required String status,
    required DateTime deliveryDate,
    required String notes,
    String? designImageUrl,
    required double totalAmount,
    required double advancePaid,
    required double balanceAmount,
  }) {
    final stylishId = _generateStylishId();
    return Order(
      id: stylishId,
      uniqueId: stylishId,
      customerId: customerId,
      tailorId: tailorId,
      serviceType: serviceType,
      status: status,
      deliveryDate: deliveryDate,
      notes: notes,
      designImageUrl: designImageUrl,
      totalAmount: totalAmount,
      advancePaid: advancePaid,
      balanceAmount: balanceAmount,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
