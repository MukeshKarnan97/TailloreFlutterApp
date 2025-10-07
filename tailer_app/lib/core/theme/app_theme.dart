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
        primary: AppSystemColors.primary,
        primaryContainer: AppSystemColors.primaryLight,
        secondary: AppSystemColors.secondary,
        secondaryContainer: AppSystemColors.secondaryLight,
        tertiary: AppSystemColors.accent,
        error: AppSystemColors.error,
        surface: AppSystemColors.background,
        surfaceContainer: AppSystemColors.panel,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppSystemColors.textPrimary,
        onSurfaceVariant: AppSystemColors.textSecondary,
        outline: AppSystemColors.border,
        shadow: AppSystemColors.shadow,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppSystemColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppSystemColors.shadow,
        titleTextStyle: AppTextStyles.appBarTitle,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppSystemColors.panel,
        elevation: 2,
        shadowColor: AppSystemColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppSystemColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppSystemColors.shadow,
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
          foregroundColor: AppSystemColors.primary,
          side: BorderSide(color: AppSystemColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.button.copyWith(color: AppSystemColors.primary),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppSystemColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.button.copyWith(color: AppSystemColors.primary),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppSystemColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppSystemColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppSystemColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppSystemColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: AppTextStyles.labelMedium,
        hintStyle: AppTextStyles.caption,
        errorStyle: AppTextStyles.error,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppSystemColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppSystemColors.primary,
        unselectedItemColor: AppSystemColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppSystemColors.primary,
        unselectedLabelColor: AppSystemColors.textHint,
        indicatorColor: AppSystemColors.primary,
        labelStyle: AppTextStyles.tab,
        unselectedLabelStyle: AppTextStyles.tab,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppSystemColors.divider,
        thickness: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppSystemColors.secondaryPanel,
        selectedColor: AppSystemColors.primary,
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
        primary: AppColorsDark.primary,
        primaryContainer: AppColorsDark.primaryLight,
        secondary: AppColorsDark.secondary,
        secondaryContainer: AppColorsDark.secondaryLight,
        tertiary: AppColorsDark.accent,
        error: AppColorsDark.error,
        surface: AppColorsDark.background,
        surfaceContainer: AppColorsDark.panel,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColorsDark.textPrimary,
        onSurfaceVariant: AppColorsDark.textSecondary,
        outline: AppColorsDark.border,
        shadow: AppColorsDark.shadow,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.panel,
        foregroundColor: AppColorsDark.textPrimary,
        elevation: 2,
        shadowColor: AppColorsDark.shadow,
        titleTextStyle: AppTextStyles.appBarTitle.copyWith(color: AppColorsDark.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColorsDark.panel,
        elevation: 2,
        shadowColor: AppColorsDark.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColorsDark.shadow,
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
          foregroundColor: AppColorsDark.primary,
          side: BorderSide(color: AppColorsDark.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.button.copyWith(color: AppColorsDark.primary),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.button.copyWith(color: AppColorsDark.primary),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.secondaryPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsDark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsDark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsDark.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsDark.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: AppColorsDark.textSecondary),
        hintStyle: AppTextStyles.caption.copyWith(color: AppColorsDark.textHint),
        errorStyle: AppTextStyles.error.copyWith(color: AppColorsDark.error),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColorsDark.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.panel,
        selectedItemColor: AppColorsDark.primary,
        unselectedItemColor: AppColorsDark.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(color: AppColorsDark.primary),
        unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(color: AppColorsDark.textHint),
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColorsDark.primary,
        unselectedLabelColor: AppColorsDark.textHint,
        indicatorColor: AppColorsDark.primary,
        labelStyle: AppTextStyles.tab.copyWith(color: AppColorsDark.primary),
        unselectedLabelStyle: AppTextStyles.tab.copyWith(color: AppColorsDark.textHint),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColorsDark.divider,
        thickness: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsDark.secondaryPanel,
        selectedColor: AppColorsDark.primary,
        labelStyle: AppTextStyles.chip.copyWith(color: AppColorsDark.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Text Theme with Dark Colors
      textTheme: TextTheme(
        displayLarge: AppTextStyles.heading1.copyWith(color: AppColorsDark.textPrimary),
        displayMedium: AppTextStyles.heading2.copyWith(color: AppColorsDark.textPrimary),
        displaySmall: AppTextStyles.heading3.copyWith(color: AppColorsDark.textPrimary),
        headlineLarge: AppTextStyles.heading2.copyWith(color: AppColorsDark.textPrimary),
        headlineMedium: AppTextStyles.heading3.copyWith(color: AppColorsDark.textPrimary),
        headlineSmall: AppTextStyles.heading4.copyWith(color: AppColorsDark.textPrimary),
        titleLarge: AppTextStyles.heading4.copyWith(color: AppColorsDark.textPrimary),
        titleMedium: AppTextStyles.labelLarge.copyWith(color: AppColorsDark.textPrimary),
        titleSmall: AppTextStyles.labelMedium.copyWith(color: AppColorsDark.textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColorsDark.textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColorsDark.textPrimary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColorsDark.textSecondary),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColorsDark.textPrimary),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColorsDark.textPrimary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColorsDark.textSecondary),
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