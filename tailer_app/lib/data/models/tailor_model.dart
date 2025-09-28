import 'package:uuid/uuid.dart';

class Tailor {
  final String id;
  final String uniqueId;
  final String name;
  final String shopName;
  final String email;
  final String phone;
  final String passwordHash;
  final String authProvider;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tailor({
    required this.id,
    required this.uniqueId,
    required this.name,
    required this.shopName,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.authProvider,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tailor.create({
    required String name,
    required String shopName,
    required String email,
    required String phone,
    required String passwordHash,
    required String authProvider,
    required String address,
  }) {
    final uuid = Uuid();
    return Tailor(
      id: uuid.v4(),
      uniqueId: uuid.v4(),
      name: name,
      shopName: shopName,
      email: email,
      phone: phone,
      passwordHash: passwordHash,
      authProvider: authProvider,
      address: address,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
