import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Text styles for the app
class AppTextStyles {
  // Base font family
  static const String _fontFamily = 'Roboto';

  // -----------------------------
  // Headings
  // -----------------------------
  
  /// Large heading - 32px
  static TextStyle get heading1 => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: _fontFamily,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// Medium heading - 28px
  static TextStyle get heading2 => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    fontFamily: _fontFamily,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// Small heading - 24px
  static TextStyle get heading3 => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// Extra small heading - 20px
  static TextStyle get heading4 => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // -----------------------------
  // Body Text
  // -----------------------------

  /// Large body text - 18px
  static TextStyle get bodyLarge => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    fontFamily: _fontFamily,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Medium body text - 16px
  static TextStyle get bodyMedium => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: _fontFamily,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Small body text - 14px
  static TextStyle get bodySmall => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontFamily: _fontFamily,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // -----------------------------
  // Labels & Captions
  // -----------------------------

  /// Button labels - 16px
  static TextStyle get labelLarge => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Form labels - 14px
  static TextStyle get labelMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamily,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Small labels - 12px
  static TextStyle get labelSmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamily,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  /// Caption text - 12px
  static TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: _fontFamily,
    color: AppColors.textHint,
    height: 1.3,
  );

  /// Overline text - 10px
  static TextStyle get overline => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamily,
    color: AppColors.textHint,
    height: 1.3,
    letterSpacing: 1.5,
  );

  // -----------------------------
  // Special Text Styles
  // -----------------------------

  /// Button text style
  static TextStyle get button => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: Colors.white,
    height: 1.2,
  );

  /// Link text style
  static TextStyle get link => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamily,
    color: AppColors.primary,
    height: 1.4,
    decoration: TextDecoration.underline,
  );

  /// Error text style
  static TextStyle get error => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: _fontFamily,
    color: AppColors.error,
    height: 1.3,
  );

  /// Success text style
  static TextStyle get success => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamily,
    color: AppColors.success,
    height: 1.3,
  );

  /// Warning text style
  static TextStyle get warning => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamily,
    color: AppColors.warning,
    height: 1.3,
  );

  /// App bar title style
  static TextStyle get appBarTitle => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: Colors.white,
    height: 1.2,
  );

  /// Tab text style
  static TextStyle get tab => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    height: 1.2,
  );

  /// Chip text style
  static TextStyle get chip => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamily,
    height: 1.2,
  );

  // -----------------------------
  // Utility Methods
  // -----------------------------

  /// Get text style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Get text style with custom size
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Get text style with custom weight
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Get text style with custom height
  static TextStyle withHeight(TextStyle style, double height) {
    return style.copyWith(height: height);
  }
}