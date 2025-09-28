import 'package:uuid/uuid.dart';

class Measurement {
  final String id;
  final String uniqueId;
  final String customerId;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;

  Measurement({
    required this.id,
    required this.uniqueId,
    required this.customerId,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Measurement.create({
    required String customerId,
    required String type,
    required Map<String, dynamic> data,
  }) {
    final uuid = Uuid();
    return Measurement(
      id: uuid.v4(),
      uniqueId: uuid.v4(),
      customerId: customerId,
      type: type,
      data: data,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
