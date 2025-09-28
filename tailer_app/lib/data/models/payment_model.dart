import 'package:uuid/uuid.dart';

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

  factory Payment.create({
    required String orderId,
    required double amount,
    required String method,
  }) {
    final uuid = Uuid();
    return Payment(
      id: uuid.v4(),
      uniqueId: uuid.v4(),
      orderId: orderId,
      amount: amount,
      method: method,
      paidOn: DateTime.now(),
    );
  }
}
