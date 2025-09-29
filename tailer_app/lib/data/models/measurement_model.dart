import 'dart:math';

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

  factory Measurement.create({
    required String customerId,
    required String type,
    required Map<String, dynamic> data,
  }) {
    final stylishId = _generateStylishId();
    return Measurement(
      id: stylishId,
      uniqueId: stylishId,
      customerId: customerId,
      type: type,
      data: data,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
