/// Enum for different payment methods
enum PaymentMethod {
  cash('cash', 'Cash'),
  card('card', 'Card'),
  upi('upi', 'UPI'),
  bank('bank', 'Bank Transfer');

  const PaymentMethod(this.value, this.displayName);

  final String value;
  final String displayName;

  /// Get enum from string value
  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value.toLowerCase(),
      orElse: () => PaymentMethod.cash,
    );
  }

  /// Get all payment method values
  static List<String> get allValues => PaymentMethod.values.map((e) => e.value).toList();

  /// Get all display names
  static List<String> get allDisplayNames => PaymentMethod.values.map((e) => e.displayName).toList();

  @override
  String toString() => value;
}