import 'package:flutter/material.dart';

/// App color palette for light theme (System theme)
class AppSystemColors {
  // -----------------------------
  // Primary Colors
  // -----------------------------
  static const Color primary = Color(0xFF4A90E2);      
  // Use for: main buttons, top app bar, active icons
  static const Color primaryLight = Color(0xFF7EC8E3); 
  // Use for: secondary buttons, hover states, subtle highlights

  // -----------------------------
  // Secondary Colors
  // -----------------------------
  static const Color secondary = Color(0xFF3EB489);    
  // Use for: success buttons, toggles, badges, secondary actions
  static const Color secondaryLight = Color(0xFF66C4C0); 
  // Use for: card backgrounds, panels, secondary highlights

  // -----------------------------
  // Accent Colors
  // -----------------------------
  static const Color accent = Color(0xFFFFB997);       
  // Use for: floating action buttons, notifications, highlights
  static const Color accentWarning = Color(0xFFFF6B6B); 
  // Use for: error states, delete buttons, warning highlights

  // -----------------------------
  // Background Colors
  // -----------------------------
  static const Color background = Color(0xFFFFFFFF);   
  // Use for: main screen background
  static const Color panel = Color(0xFFE8EAF6);        
  // Use for: cards, panels, secondary sections
  static const Color secondaryPanel = Color(0xFFFFF9E3); 
  // Use for: subtle highlights, secondary panels

  // -----------------------------
  // Text Colors
  // -----------------------------
  static const Color textPrimary = Color(0xFF212121);  
  // Use for: main text, headings, titles
  static const Color textSecondary = Color(0xFF666666);
  // Use for: subtitles, secondary info, less prominent text
  static const Color textHint = Color(0xFFB0B0B0);     
  // Use for: placeholders, disabled text, hints

  // -----------------------------
  // Status Colors
  // -----------------------------
  static const Color success = Color(0xFF28A745);      
  // Use for: success messages, confirmations
  static const Color warning = Color(0xFFFFC107);      
  // Use for: warnings, caution messages
  static const Color error = Color(0xFFDC3545);        
  // Use for: error messages, invalid actions
  static const Color info = Color(0xFF17A2B8);         
  // Use for: neutral informational messages

  // -----------------------------
  // Additional UI Colors
  // -----------------------------
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFD0D0D0);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x4D000000);
}

/// App color palette for dark theme
class AppColorsDark {
  // -----------------------------
  // Primary Colors
  // -----------------------------
  static const Color primary = Color(0xFF4A90E2);      
  // Use for: main buttons, app bar, active icons
  static const Color primaryLight = Color(0xFF7EC8E3); 
  // Use for: secondary buttons, highlights

  // -----------------------------
  // Secondary Colors
  // -----------------------------
  static const Color secondary = Color(0xFF3EB489);    
  // Use for: success buttons, toggles, badges
  static const Color secondaryLight = Color(0xFF66C4C0); 
  // Use for: card backgrounds, panels

  // -----------------------------
  // Accent Colors
  // -----------------------------
  static const Color accent = Color(0xFFFFB997);       
  // Use for: floating action buttons, notifications
  static const Color accentWarning = Color(0xFFFF6B6B); 
  // Use for: error states, warning highlights

  // -----------------------------
  // Background Colors
  // -----------------------------
  static const Color background = Color(0xFF121212);   
  // Use for: main screen background
  static const Color panel = Color(0xFF1E1E1E);        
  // Use for: cards, panels, secondary sections
  static const Color secondaryPanel = Color(0xFF2A2A2A); 
  // Use for: subtle highlights, secondary panels

  // -----------------------------
  // Text Colors
  // -----------------------------
  static const Color textPrimary = Color(0xFFFFFFFF);  
  // Use for: main text, headings, titles
  static const Color textSecondary = Color(0xFFCCCCCC);
  // Use for: subtitles, secondary info
  static const Color textHint = Color(0xFF888888);     
  // Use for: placeholders, disabled text

  // -----------------------------
  // Status Colors
  // -----------------------------
  static const Color success = Color(0xFF28A745);      
  // Use for: success messages, confirmations
  static const Color warning = Color(0xFFFFC107);      
  // Use for: warnings, caution messages
  static const Color error = Color(0xFFDC3545);        
  // Use for: error messages, invalid actions
  static const Color info = Color(0xFF17A2B8);         
  // Use for: neutral informational messages

  // -----------------------------
  // Additional UI Colors
  // -----------------------------
  static const Color divider = Color(0xFF333333);
  static const Color border = Color(0xFF404040);
  static const Color shadow = Color(0x3D000000);
  static const Color overlay = Color(0x66000000);
}

/// Helper class to get colors based on current theme
class AppColors {
  static bool _isDarkMode = false;
  
  static void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
  }

  // Primary Colors
  static Color get primary => _isDarkMode ? AppColorsDark.primary : AppSystemColors.primary;
  static Color get primaryLight => _isDarkMode ? AppColorsDark.primaryLight : AppSystemColors.primaryLight;

  // Secondary Colors
  static Color get secondary => _isDarkMode ? AppColorsDark.secondary : AppSystemColors.secondary;
  static Color get secondaryLight => _isDarkMode ? AppColorsDark.secondaryLight : AppSystemColors.secondaryLight;

  // Accent Colors
  static Color get accent => _isDarkMode ? AppColorsDark.accent : AppSystemColors.accent;
  static Color get accentWarning => _isDarkMode ? AppColorsDark.accentWarning : AppSystemColors.accentWarning;

  // Background Colors
  static Color get background => _isDarkMode ? AppColorsDark.background : AppSystemColors.background;
  static Color get panel => _isDarkMode ? AppColorsDark.panel : AppSystemColors.panel;
  static Color get secondaryPanel => _isDarkMode ? AppColorsDark.secondaryPanel : AppSystemColors.secondaryPanel;

  // Text Colors
  static Color get textPrimary => _isDarkMode ? AppColorsDark.textPrimary : AppSystemColors.textPrimary;
  static Color get textSecondary => _isDarkMode ? AppColorsDark.textSecondary : AppSystemColors.textSecondary;
  static Color get textHint => _isDarkMode ? AppColorsDark.textHint : AppSystemColors.textHint;

  // Status Colors
  static Color get success => _isDarkMode ? AppColorsDark.success : AppSystemColors.success;
  static Color get warning => _isDarkMode ? AppColorsDark.warning : AppSystemColors.warning;
  static Color get error => _isDarkMode ? AppColorsDark.error : AppSystemColors.error;
  static Color get info => _isDarkMode ? AppColorsDark.info : AppSystemColors.info;

  // Additional UI Colors
  static Color get divider => _isDarkMode ? AppColorsDark.divider : AppSystemColors.divider;
  static Color get border => _isDarkMode ? AppColorsDark.border : AppSystemColors.border;
  static Color get shadow => _isDarkMode ? AppColorsDark.shadow : AppSystemColors.shadow;
  static Color get overlay => _isDarkMode ? AppColorsDark.overlay : AppSystemColors.overlay;
}