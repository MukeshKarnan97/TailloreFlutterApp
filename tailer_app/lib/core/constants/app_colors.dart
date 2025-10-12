import 'package:flutter/material.dart';

/// Light Theme Colors - Professional Tailor App Design
class AppLightTheme {
  // Primary Brand Colors - Elegant Teal/Blue
  static const Color primary = Color(0xFF0D7377);        // Deep Teal - Main brand color
  static const Color primaryLight = Color(0xFF119D97);   // Bright Teal - Accents
  static const Color primaryDark = Color(0xFF06484A);    // Dark Teal - Deep elements
  
  // Secondary Colors - Warm Accents
  static const Color secondary = Color(0xFFFF6B35);      // Coral Orange - CTA buttons
  static const Color secondaryLight = Color(0xFFFF9770); // Light Coral - Highlights
  static const Color secondaryDark = Color(0xFFDB4A1F);  // Dark Coral - Emphasis
  
  // Accent Colors - Gold/Yellow for Premium Feel
  static const Color accent = Color(0xFFFDB44B);         // Golden Yellow - Premium features
  static const Color accentLight = Color(0xFFFFD17A);    // Light Gold - Subtle highlights
  static const Color accentDark = Color(0xFFE09F28);     // Dark Gold - Rich emphasis
  
  // Background Colors - Clean and Professional
  static const Color background = Color(0xFFF8F9FA);     // Off-white background
  static const Color surface = Color(0xFFFFFFFF);        // Pure white for cards
  static const Color surfaceVariant = Color(0xFFF1F3F5); // Light grey for panels
  
  // Text Colors - High Contrast for Readability
  static const Color textPrimary = Color(0xFF212529);    // Almost black
  static const Color textSecondary = Color(0xFF6C757D);  // Medium grey
  static const Color textTertiary = Color(0xFFADB5BD);   // Light grey
  static const Color textHint = Color(0xFFCED4DA);       // Very light grey
  
  // Status Colors - Clear Communication
  static const Color success = Color(0xFF28A745);        // Green - Completed orders
  static const Color warning = Color(0xFFFFC107);        // Yellow - Pending payments
  static const Color error = Color(0xFFDC3545);          // Red - Cancelled/overdue
  static const Color info = Color(0xFF17A2B8);           // Cyan - Information
  
  // UI Element Colors
  static const Color divider = Color(0xFFDEE2E6);
  static const Color border = Color(0xFFCED4DA);
  static const Color shadow = Color(0x1A000000);         // 10% black
  static const Color overlay = Color(0x80000000);        // 50% black
  static const Color ripple = Color(0x1A0D7377);         // 10% primary
  
  // Order Status Colors
  static const Color statusPending = Color(0xFFFFA726);   // Orange
  static const Color statusInProgress = Color(0xFF42A5F5); // Blue
  static const Color statusReady = Color(0xFF66BB6A);     // Green
  static const Color statusCompleted = Color(0xFF26A69A); // Teal
  static const Color statusCancelled = Color(0xFFEF5350); // Red
}

/// Dark Theme Colors - Modern Dark Mode for Tailor App
class AppDarkTheme {
  // Primary Brand Colors - Vibrant Teal for Dark Mode
  static const Color primary = Color(0xFF14FFEC);        // Bright Teal - Stands out in dark
  static const Color primaryLight = Color(0xFF5FFFF1);   // Very bright teal
  static const Color primaryDark = Color(0xFF0BB3A8);    // Medium teal
  
  // Secondary Colors - Warm Accents Adjusted for Dark
  static const Color secondary = Color(0xFFFF8A65);      // Softer Coral
  static const Color secondaryLight = Color(0xFFFFAB91); // Light Coral
  static const Color secondaryDark = Color(0xFFFF6E40);  // Vibrant Coral
  
  // Accent Colors - Gold Adjusted for Dark Mode
  static const Color accent = Color(0xFFFFD54F);         // Bright Gold
  static const Color accentLight = Color(0xFFFFE082);    // Light Gold
  static const Color accentDark = Color(0xFFFFCA28);     // Rich Gold
  
  // Background Colors - Dark Greys with Depth
  static const Color background = Color(0xFF0F1419);     // Very dark blue-grey
  static const Color surface = Color(0xFF1A1F26);        // Dark surface for cards
  static const Color surfaceVariant = Color(0xFF252C35); // Lighter surface variant
  
  // Text Colors - Optimized for Dark Background
  static const Color textPrimary = Color(0xFFE9ECEF);    // Almost white
  static const Color textSecondary = Color(0xFFADB5BD);  // Light grey
  static const Color textTertiary = Color(0xFF6C757D);   // Medium grey
  static const Color textHint = Color(0xFF495057);       // Dark grey
  
  // Status Colors - Slightly Muted for Dark Mode
  static const Color success = Color(0xFF4CAF50);        // Softer green
  static const Color warning = Color(0xFFFFA726);        // Softer yellow
  static const Color error = Color(0xFFEF5350);          // Softer red
  static const Color info = Color(0xFF29B6F6);           // Softer cyan
  
  // UI Element Colors
  static const Color divider = Color(0xFF343A40);
  static const Color border = Color(0xFF495057);
  static const Color shadow = Color(0x40000000);         // 25% black
  static const Color overlay = Color(0x99000000);        // 60% black
  static const Color ripple = Color(0x2614FFEC);         // 15% primary
  
  // Order Status Colors - Dark Mode Optimized
  static const Color statusPending = Color(0xFFFFB74D);   // Lighter orange
  static const Color statusInProgress = Color(0xFF64B5F6); // Lighter blue
  static const Color statusReady = Color(0xFF81C784);     // Lighter green
  static const Color statusCompleted = Color(0xFF4DB6AC); // Lighter teal
  static const Color statusCancelled = Color(0xFFE57373); // Lighter red
}

/// Main AppColors Class - Dynamic Theme Switching
class AppColors {
  static bool _isDarkMode = false;
  
  /// Set the current theme mode
  static void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
  }
  
  /// Get current theme mode
  static bool get isDarkMode => _isDarkMode;
  
  // ==================== Primary Colors ====================
  static Color get primary => _isDarkMode ? AppDarkTheme.primary : AppLightTheme.primary;
  static Color get primaryLight => _isDarkMode ? AppDarkTheme.primaryLight : AppLightTheme.primaryLight;
  static Color get primaryDark => _isDarkMode ? AppDarkTheme.primaryDark : AppLightTheme.primaryDark;
  
  // ==================== Secondary Colors ====================
  static Color get secondary => _isDarkMode ? AppDarkTheme.secondary : AppLightTheme.secondary;
  static Color get secondaryLight => _isDarkMode ? AppDarkTheme.secondaryLight : AppLightTheme.secondaryLight;
  static Color get secondaryDark => _isDarkMode ? AppDarkTheme.secondaryDark : AppLightTheme.secondaryDark;
  
  // ==================== Accent Colors ====================
  static Color get accent => _isDarkMode ? AppDarkTheme.accent : AppLightTheme.accent;
  static Color get accentLight => _isDarkMode ? AppDarkTheme.accentLight : AppLightTheme.accentLight;
  static Color get accentDark => _isDarkMode ? AppDarkTheme.accentDark : AppLightTheme.accentDark;
  
  // ==================== Background Colors ====================
  static Color get background => _isDarkMode ? AppDarkTheme.background : AppLightTheme.background;
  static Color get surface => _isDarkMode ? AppDarkTheme.surface : AppLightTheme.surface;
  static Color get surfaceVariant => _isDarkMode ? AppDarkTheme.surfaceVariant : AppLightTheme.surfaceVariant;
  
  // Legacy panel colors (kept for compatibility)
  static Color get panel => surface;
  static Color get secondaryPanel => surfaceVariant;
  
  // ==================== Text Colors ====================
  static Color get textPrimary => _isDarkMode ? AppDarkTheme.textPrimary : AppLightTheme.textPrimary;
  static Color get textSecondary => _isDarkMode ? AppDarkTheme.textSecondary : AppLightTheme.textSecondary;
  static Color get textTertiary => _isDarkMode ? AppDarkTheme.textTertiary : AppLightTheme.textTertiary;
  static Color get textHint => _isDarkMode ? AppDarkTheme.textHint : AppLightTheme.textHint;
  
  // ==================== Status Colors ====================
  static Color get success => _isDarkMode ? AppDarkTheme.success : AppLightTheme.success;
  static Color get warning => _isDarkMode ? AppDarkTheme.warning : AppLightTheme.warning;
  static Color get error => _isDarkMode ? AppDarkTheme.error : AppLightTheme.error;
  static Color get info => _isDarkMode ? AppDarkTheme.info : AppLightTheme.info;
  
  // ==================== UI Element Colors ====================
  static Color get divider => _isDarkMode ? AppDarkTheme.divider : AppLightTheme.divider;
  static Color get border => _isDarkMode ? AppDarkTheme.border : AppLightTheme.border;
  static Color get shadow => _isDarkMode ? AppDarkTheme.shadow : AppLightTheme.shadow;
  static Color get overlay => _isDarkMode ? AppDarkTheme.overlay : AppLightTheme.overlay;
  static Color get ripple => _isDarkMode ? AppDarkTheme.ripple : AppLightTheme.ripple;
  
  // ==================== Order Status Colors ====================
  static Color get statusPending => _isDarkMode ? AppDarkTheme.statusPending : AppLightTheme.statusPending;
  static Color get statusInProgress => _isDarkMode ? AppDarkTheme.statusInProgress : AppLightTheme.statusInProgress;
  static Color get statusReady => _isDarkMode ? AppDarkTheme.statusReady : AppLightTheme.statusReady;
  static Color get statusCompleted => _isDarkMode ? AppDarkTheme.statusCompleted : AppLightTheme.statusCompleted;
  static Color get statusCancelled => _isDarkMode ? AppDarkTheme.statusCancelled : AppLightTheme.statusCancelled;
  
  /// Get status color by status string
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return statusPending;
      case 'cutting':
      case 'stitching':
      case 'in_progress':
        return statusInProgress;
      case 'ready':
        return statusReady;
      case 'completed':
      case 'delivered':
        return statusCompleted;
      case 'cancelled':
        return statusCancelled;
      default:
        return textSecondary;
    }
  }
}

// Remove old classes for clean codebase
@Deprecated('Use AppLightTheme instead')
class AppSystemColors extends AppLightTheme {}

@Deprecated('Use AppDarkTheme instead')
class AppColorsDark extends AppDarkTheme {}