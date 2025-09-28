import 'package:uuid/uuid.dart';

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
    final uuid = Uuid();
    return Order(
      id: uuid.v4(),
      uniqueId: uuid.v4(),
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
