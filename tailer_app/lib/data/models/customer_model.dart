import 'package:uuid/uuid.dart';

class Customer {
  final String id;
  final String uniqueId;
  final String tailorId;
  final String name;
  final String phone;
  final String? email;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.uniqueId,
    required this.tailorId,
    required this.name,
    required this.phone,
    this.email,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.create({
    required String tailorId,
    required String name,
    required String phone,
    String? email,
    required String address,
  }) {
    final uuid = Uuid();
    return Customer(
      id: uuid.v4(),
      uniqueId: uuid.v4(),
      tailorId: tailorId,
      name: name,
      phone: phone,
      email: email,
      address: address,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
