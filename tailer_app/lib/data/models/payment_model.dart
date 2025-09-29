import 'dart:math';

class Payment {
  final String id;
  final String uniqueId;
  final String orderId;
  final double amount;
  final String method;
  final DateTime paidOn;

  Payment({
    required this.id,
    required this.uniqueId,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.paidOn,
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

  factory Payment.create({
    required String orderId,
    required double amount,
    required String method,
  }) {
    final stylishId = _generateStylishId();
    return Payment(
      id: stylishId,
      uniqueId: stylishId,
      orderId: orderId,
      amount: amount,
      method: method,
      paidOn: DateTime.now(),
    );
  }
}
