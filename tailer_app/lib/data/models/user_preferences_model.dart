class UserPreferencesModel {
  final int? id;
  final int userId;
  final String themeMode;
  final String language;
  final String measurementUnit; // 'inches' or 'cm'
  final bool notificationsEnabled;
  final bool biometricEnabled;
  final bool rememberMe;
  final int autoLogoutDuration; // in minutes
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPreferencesModel({
    this.id,
    required this.userId,
    this.themeMode = 'system',
    this.language = 'en',
    this.measurementUnit = 'inches',
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
    this.rememberMe = false,
    this.autoLogoutDuration = 30,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for creating from database map
  factory UserPreferencesModel.fromMap(Map<String, dynamic> map) {
    return UserPreferencesModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      themeMode: map['theme_mode'] as String? ?? 'system',
      language: map['language'] as String? ?? 'en',
      measurementUnit: map['measurement_unit'] as String? ?? 'inches',
      notificationsEnabled: (map['notifications_enabled'] as int? ?? 1) == 1,
      biometricEnabled: (map['biometric_enabled'] as int? ?? 0) == 1,
      rememberMe: (map['remember_me'] as int? ?? 0) == 1,
      autoLogoutDuration: map['auto_logout_duration'] as int? ?? 30,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'theme_mode': themeMode,
      'language': language,
      'measurement_unit': measurementUnit,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'biometric_enabled': biometricEnabled ? 1 : 0,
      'remember_me': rememberMe ? 1 : 0,
      'auto_logout_duration': autoLogoutDuration,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create copy with updated fields
  UserPreferencesModel copyWith({
    int? id,
    int? userId,
    String? themeMode,
    String? language,
    String? measurementUnit,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    bool? rememberMe,
    int? autoLogoutDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferencesModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      rememberMe: rememberMe ?? this.rememberMe,
      autoLogoutDuration: autoLogoutDuration ?? this.autoLogoutDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserPreferencesModel(userId: $userId, themeMode: $themeMode, '
           'language: $language, measurementUnit: $measurementUnit, rememberMe: $rememberMe)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferencesModel && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  // Factory constructor for default preferences
  factory UserPreferencesModel.defaultPreferences(int userId) {
    final now = DateTime.now();
    return UserPreferencesModel(
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Validation methods
  bool get isValidThemeMode {
    return ['light', 'dark', 'system'].contains(themeMode);
  }

  bool get isValidLanguage {
    return ['en', 'es', 'fr', 'de', 'hi', 'ar'].contains(language);
  }

  bool get isValidMeasurementUnit {
    return ['inches', 'cm'].contains(measurementUnit);
  }

  bool get isValidAutoLogoutDuration {
    return autoLogoutDuration >= 5 && autoLogoutDuration <= 1440; // 5 min to 24 hours
  }

  // Helper methods
  Duration get autoLogoutDurationAsDuration {
    return Duration(minutes: autoLogoutDuration);
  }

  String get themeDisplayName {
    switch (themeMode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System';
      default:
        return 'Unknown';
    }
  }

  String get languageDisplayName {
    switch (language) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'hi':
        return 'हिंदी';
      case 'ar':
        return 'العربية';
      default:
        return 'Unknown';
    }
  }

  String get measurementUnitDisplayName {
    switch (measurementUnit) {
      case 'inches':
        return 'Inches (in)';
      case 'cm':
        return 'Centimeters (cm)';
      default:
        return 'Unknown';
    }
  }

  String get measurementUnitSymbol {
    switch (measurementUnit) {
      case 'inches':
        return 'in';
      case 'cm':
        return 'cm';
      default:
        return 'in';
    }
  }
}