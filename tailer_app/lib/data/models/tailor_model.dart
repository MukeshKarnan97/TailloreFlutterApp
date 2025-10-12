import 'dart:math';

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
  final String? profileImagePath; // Path to locally stored profile image
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

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
    this.profileImagePath,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
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

  factory Tailor.create({
    required String name,
    required String shopName,
    required String email,
    required String phone,
    required String passwordHash,
    String authProvider = 'email',
    String address = '',
    String? profileImagePath,
  }) {
    final stylishId = _generateStylishId();
    return Tailor(
      id: stylishId,
      uniqueId: stylishId,
      name: name,
      shopName: shopName,
      email: email,
      phone: phone,
      passwordHash: passwordHash,
      authProvider: authProvider,
      address: address,
      profileImagePath: profileImagePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDeleted: false,
    );
  }

  /// Create from database map
  factory Tailor.fromMap(Map<String, dynamic> map) {
    return Tailor(
      id: map['id'] as String,
      uniqueId: map['unique_id'] as String,
      name: map['name'] as String,
      shopName: map['shop_name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      passwordHash: map['password_hash'] as String,
      authProvider: map['auth_provider'] as String? ?? 'email',
      address: map['address'] as String? ?? '',
      profileImagePath: map['profile_image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unique_id': uniqueId,
      'name': name,
      'shop_name': shopName,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'auth_provider': authProvider,
      'address': address,
      'profile_image_path': profileImagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  /// Create a copy with modified fields
  Tailor copyWith({
    String? id,
    String? uniqueId,
    String? name,
    String? shopName,
    String? email,
    String? phone,
    String? passwordHash,
    String? authProvider,
    String? address,
    String? profileImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Tailor(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      name: name ?? this.name,
      shopName: shopName ?? this.shopName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      authProvider: authProvider ?? this.authProvider,
      address: address ?? this.address,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'Tailor(id: $id, name: $name, shopName: $shopName, email: $email, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tailor && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
