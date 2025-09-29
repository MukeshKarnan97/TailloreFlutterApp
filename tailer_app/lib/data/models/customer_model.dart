import 'dart:math';

class Customer {
  final String id;
  final String uniqueId;
  final String tailorId;
  final String name;
  final String? gender;
  final String phone;
  final String? email;
  final String address;
  final String? notes;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.uniqueId,
    required this.tailorId,
    required this.name,
    this.gender,
    required this.phone,
    this.email,
    required this.address,
    this.notes,
    this.isDeleted = false,
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

  factory Customer.create({
    required String tailorId,
    required String name,
    String? gender,
    required String phone,
    String? email,
    required String address,
    String? notes,
  }) {
    final stylishId = _generateStylishId();
    return Customer(
      id: stylishId,
      uniqueId: stylishId,
      tailorId: tailorId,
      name: name,
      gender: gender,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convert Customer to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unique_id': uniqueId,
      'tailor_id': tailorId,
      'name': name,
      'gender': gender,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create Customer from Map (database result)
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      uniqueId: map['unique_id'],
      tailorId: map['tailor_id'],
      name: map['name'],
      gender: map['gender'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      notes: map['notes'],
      isDeleted: (map['is_deleted'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Create a copy of Customer with updated fields
  Customer copyWith({
    String? id,
    String? uniqueId,
    String? tailorId,
    String? name,
    String? gender,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      tailorId: tailorId ?? this.tailorId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert Customer to JSON string
  String toJson() {
    return toString();
  }

  @override
  String toString() {
    return 'Customer{id: $id, uniqueId: $uniqueId, tailorId: $tailorId, name: $name, gender: $gender, phone: $phone, email: $email, address: $address, notes: $notes, isDeleted: $isDeleted, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.uniqueId == uniqueId;
  }

  @override
  int get hashCode => uniqueId.hashCode;
}
