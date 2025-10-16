import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:tailer_app/core/constants/app_constants.dart';

/// Reusable sub-header widget for screens
/// Displays contextual information below the main header
class SubHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;

  const SubHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.backgroundColor,
    this.textColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? AppColors.primary.withOpacity(0.1),
            (backgroundColor ?? AppColors.primary).withOpacity(0.05),
            AppColors.background.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: (backgroundColor ?? AppColors.primary).withOpacity(0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon section
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    backgroundColor ?? AppColors.primary,
                    (backgroundColor ?? AppColors.primary).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (backgroundColor ?? AppColors.primary).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
          ],
          
          // Text section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor ?? AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: (textColor ?? AppColors.textSecondary).withOpacity(0.8),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action section
          if (action != null) ...[
            const SizedBox(width: AppConstants.spacingS),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Predefined sub-header styles for common use cases
class SubHeaderStyles {
  static SubHeader info({
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return SubHeader(
      title: title,
      subtitle: subtitle,
      icon: Icons.info_outline,
      backgroundColor: AppColors.info,
      action: action,
    );
  }

  static SubHeader success({
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return SubHeader(
      title: title,
      subtitle: subtitle,
      icon: Icons.check_circle_outline,
      backgroundColor: AppColors.success,
      action: action,
    );
  }

  static SubHeader warning({
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return SubHeader(
      title: title,
      subtitle: subtitle,
      icon: Icons.warning_outlined,
      backgroundColor: AppColors.warning,
      action: action,
    );
  }

  static SubHeader feature({
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? action,
  }) {
    return SubHeader(
      title: title,
      subtitle: subtitle,
      icon: icon ?? Icons.star_outline,
      backgroundColor: AppColors.primary,
      action: action,
    );
  }
}