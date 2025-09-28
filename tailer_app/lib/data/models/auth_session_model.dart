class AuthSessionModel {
  final int? id;
  final String sessionId;
  final int userId;
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? deviceInfo;
  final bool isActive;

  const AuthSessionModel({
    this.id,
    required this.sessionId,
    required this.userId,
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
    required this.createdAt,
    this.deviceInfo,
    this.isActive = true,
  });

  // Factory constructor for creating from database map
  factory AuthSessionModel.fromMap(Map<String, dynamic> map) {
    return AuthSessionModel(
      id: map['id'] as int?,
      sessionId: map['session_id'] as String,
      userId: map['user_id'] as int,
      accessToken: map['access_token'] as String,
      refreshToken: map['refresh_token'] as String?,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      deviceInfo: map['device_info'] as String?,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'device_info': deviceInfo,
      'is_active': isActive ? 1 : 0,
    };
  }

  // Create copy with updated fields
  AuthSessionModel copyWith({
    int? id,
    String? sessionId,
    int? userId,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    DateTime? createdAt,
    String? deviceInfo,
    bool? isActive,
  }) {
    return AuthSessionModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'AuthSessionModel(id: $id, sessionId: $sessionId, userId: $userId, '
           'isActive: $isActive, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthSessionModel && 
           other.sessionId == sessionId &&
           other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(sessionId, userId);

  // Helper methods
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get isValid => isActive && !isExpired;
  
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
  
  Duration get age => DateTime.now().difference(createdAt);
  
  bool get needsRefresh {
    final timeLeft = timeUntilExpiry;
    return timeLeft.inMinutes < 15; // Refresh if less than 15 minutes left
  }

  // Create a new session with extended expiry
  AuthSessionModel renewSession({
    String? newAccessToken,
    String? newRefreshToken,
    Duration? extendBy,
  }) {
    return copyWith(
      accessToken: newAccessToken ?? accessToken,
      refreshToken: newRefreshToken ?? refreshToken,
      expiresAt: DateTime.now().add(extendBy ?? const Duration(hours: 24)),
    );
  }

  // Deactivate session
  AuthSessionModel deactivate() {
    return copyWith(isActive: false);
  }
}