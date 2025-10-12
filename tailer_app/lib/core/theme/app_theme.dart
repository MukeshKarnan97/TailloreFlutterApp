import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'text_styles.dart';

/// App theme configuration
class AppTheme {
  // -----------------------------
  // System Theme (Light)
  // -----------------------------
  static ThemeData get systemTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppLightTheme.primary,
        primaryContainer: AppLightTheme.primaryLight,
        secondary: AppLightTheme.secondary,
        secondaryContainer: AppLightTheme.secondaryLight,
        tertiary: AppLightTheme.accent,
        error: AppLightTheme.error,
        surface: AppLightTheme.background,
        surfaceContainer: AppLightTheme.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppLightTheme.textPrimary,
        onSurfaceVariant: AppLightTheme.textSecondary,
        outline: AppLightTheme.border,
        shadow: AppLightTheme.shadow,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppLightTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppLightTheme.shadow,
        titleTextStyle: AppTextStyles.appBarTitle,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppLightTheme.surface,
        elevation: 2,
        shadowColor: AppLightTheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppLightTheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppLightTheme.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppLightTheme.primary,
          side: BorderSide(color: AppLightTheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.button.copyWith(color: AppLightTheme.primary),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppLightTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.button.copyWith(color: AppLightTheme.primary),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppLightTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppLightTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppLightTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppLightTheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: AppTextStyles.labelMedium,
        hintStyle: AppTextStyles.caption,
        errorStyle: AppTextStyles.error,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppLightTheme.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppLightTheme.primary,
        unselectedItemColor: AppLightTheme.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppLightTheme.primary,
        unselectedLabelColor: AppLightTheme.textHint,
        indicatorColor: AppLightTheme.primary,
        labelStyle: AppTextStyles.tab,
        unselectedLabelStyle: AppTextStyles.tab,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppLightTheme.divider,
        thickness: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppLightTheme.surfaceVariant,
        selectedColor: AppLightTheme.primary,
        labelStyle: AppTextStyles.chip,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.heading1,
        displayMedium: AppTextStyles.heading2,
        displaySmall: AppTextStyles.heading3,
        headlineLarge: AppTextStyles.heading2,
        headlineMedium: AppTextStyles.heading3,
        headlineSmall: AppTextStyles.heading4,
        titleLarge: AppTextStyles.heading4,
        titleMedium: AppTextStyles.labelLarge,
        titleSmall: AppTextStyles.labelMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
    );
  }

  // -----------------------------
  // Dark Theme
  // -----------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: AppDarkTheme.primary,
        primaryContainer: AppDarkTheme.primaryLight,
        secondary: AppDarkTheme.secondary,
        secondaryContainer: AppDarkTheme.secondaryLight,
        tertiary: AppDarkTheme.accent,
        error: AppDarkTheme.error,
        surface: AppDarkTheme.background,
        surfaceContainer: AppDarkTheme.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppDarkTheme.textPrimary,
        onSurfaceVariant: AppDarkTheme.textSecondary,
        outline: AppDarkTheme.border,
        shadow: AppDarkTheme.shadow,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppDarkTheme.surface,
        foregroundColor: AppDarkTheme.textPrimary,
        elevation: 2,
        shadowColor: AppDarkTheme.shadow,
        titleTextStyle: AppTextStyles.appBarTitle.copyWith(color: AppDarkTheme.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppDarkTheme.surface,
        elevation: 2,
        shadowColor: AppDarkTheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDarkTheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppDarkTheme.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDarkTheme.primary,
          side: BorderSide(color: AppDarkTheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.button.copyWith(color: AppDarkTheme.primary),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppDarkTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.button.copyWith(color: AppDarkTheme.primary),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDarkTheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppDarkTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppDarkTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppDarkTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppDarkTheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: AppDarkTheme.textSecondary),
        hintStyle: AppTextStyles.caption.copyWith(color: AppDarkTheme.textHint),
        errorStyle: AppTextStyles.error.copyWith(color: AppDarkTheme.error),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppDarkTheme.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppDarkTheme.surface,
        selectedItemColor: AppDarkTheme.primary,
        unselectedItemColor: AppDarkTheme.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(color: AppDarkTheme.primary),
        unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(color: AppDarkTheme.textHint),
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppDarkTheme.primary,
        unselectedLabelColor: AppDarkTheme.textHint,
        indicatorColor: AppDarkTheme.primary,
        labelStyle: AppTextStyles.tab.copyWith(color: AppDarkTheme.primary),
        unselectedLabelStyle: AppTextStyles.tab.copyWith(color: AppDarkTheme.textHint),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppDarkTheme.divider,
        thickness: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppDarkTheme.surfaceVariant,
        selectedColor: AppDarkTheme.primary,
        labelStyle: AppTextStyles.chip.copyWith(color: AppDarkTheme.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Text Theme with Dark Colors
      textTheme: TextTheme(
        displayLarge: AppTextStyles.heading1.copyWith(color: AppDarkTheme.textPrimary),
        displayMedium: AppTextStyles.heading2.copyWith(color: AppDarkTheme.textPrimary),
        displaySmall: AppTextStyles.heading3.copyWith(color: AppDarkTheme.textPrimary),
        headlineLarge: AppTextStyles.heading2.copyWith(color: AppDarkTheme.textPrimary),
        headlineMedium: AppTextStyles.heading3.copyWith(color: AppDarkTheme.textPrimary),
        headlineSmall: AppTextStyles.heading4.copyWith(color: AppDarkTheme.textPrimary),
        titleLarge: AppTextStyles.heading4.copyWith(color: AppDarkTheme.textPrimary),
        titleMedium: AppTextStyles.labelLarge.copyWith(color: AppDarkTheme.textPrimary),
        titleSmall: AppTextStyles.labelMedium.copyWith(color: AppDarkTheme.textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppDarkTheme.textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppDarkTheme.textPrimary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppDarkTheme.textSecondary),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: AppDarkTheme.textPrimary),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: AppDarkTheme.textPrimary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: AppDarkTheme.textSecondary),
      ),
    );
  }

  // -----------------------------
  // Helper Methods
  // -----------------------------

  /// Get theme based on theme mode
  static ThemeData getTheme(ThemeMode themeMode, Brightness platformBrightness) {
    switch (themeMode) {
      case ThemeMode.dark:
        AppColors.setDarkMode(true);
        return darkTheme;
      case ThemeMode.system:
        final isDark = platformBrightness == Brightness.dark;
        AppColors.setDarkMode(isDark);
        return isDark ? darkTheme : systemTheme;
      default:
        AppColors.setDarkMode(false);
        return systemTheme;
    }
  }

  /// Check if current theme is dark
  static bool isDarkTheme(ThemeMode themeMode, Brightness platformBrightness) {
    switch (themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return platformBrightness == Brightness.dark;
      default:
        return false;
    }
  }
}