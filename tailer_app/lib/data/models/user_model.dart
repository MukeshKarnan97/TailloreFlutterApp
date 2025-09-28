class UserModel {
  final int? id;
  final String username;
  final String email;
  final String? phone;
  final String passwordHash;
  final String? profilePicture;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;
  final int loginCount;

  const UserModel({
    this.id,
    required this.username,
    required this.email,
    this.phone,
    required this.passwordHash,
    this.profilePicture,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
    this.loginCount = 0,
  });

  // Factory constructor for creating from database map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      passwordHash: map['password_hash'] as String,
      profilePicture: map['profile_picture'] as String?,
      isEmailVerified: (map['is_email_verified'] as int) == 1,
      isPhoneVerified: (map['is_phone_verified'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastLogin: map['last_login'] != null 
        ? DateTime.parse(map['last_login'] as String) 
        : null,
      loginCount: map['login_count'] as int? ?? 0,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'profile_picture': profilePicture,
      'is_email_verified': isEmailVerified ? 1 : 0,
      'is_phone_verified': isPhoneVerified ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'login_count': loginCount,
    };
  }

  // Convert to map without sensitive data (for UI display)
  Map<String, dynamic> toSafeMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'profile_picture': profilePicture,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'login_count': loginCount,
    };
  }

  // Create copy with updated fields
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? phone,
    String? passwordHash,
    String? profilePicture,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    int? loginCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      profilePicture: profilePicture ?? this.profilePicture,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      loginCount: loginCount ?? this.loginCount,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, '
           'isEmailVerified: $isEmailVerified, loginCount: $loginCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && 
           other.id == id &&
           other.username == username &&
           other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, username, email);

  // Validation methods
  bool get isProfileComplete {
    return username.isNotEmpty && 
           email.isNotEmpty && 
           isEmailVerified;
  }

  String? validateUsername() {
    if (username.isEmpty) return 'Username is required';
    if (username.length < 3) return 'Username must be at least 3 characters';
    if (username.length > 30) return 'Username must not exceed 30 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  String? validateEmail() {
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePhone() {
    if (phone == null || phone!.isEmpty) return null; // Phone is optional
    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone!)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // Helper methods
  String get displayName => username;
  
  String get initials {
    final parts = username.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : '';
  }

  bool get hasProfilePicture => profilePicture != null && profilePicture!.isNotEmpty;

  Duration get accountAge => DateTime.now().difference(createdAt);
  
  Duration? get timeSinceLastLogin => 
    lastLogin != null ? DateTime.now().difference(lastLogin!) : null;
}