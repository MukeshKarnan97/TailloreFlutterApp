// Example usage of the new color system
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/text_styles.dart';
import '../constants/app_strings.dart';

/// Example screen showing how to use the new color system
class ColorSystemExample extends StatelessWidget {
  const ColorSystemExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.theme),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary Colors Section
            Text(
              'Primary Colors',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ColorCard(
                  color: AppColors.primary,
                  name: 'Primary',
                  textColor: Colors.white,
                ),
                const SizedBox(width: 12),
                _ColorCard(
                  color: AppColors.primaryLight,
                  name: 'Primary Light',
                  textColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Secondary Colors Section
            Text(
              'Secondary Colors',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ColorCard(
                  color: AppColors.secondary,
                  name: 'Secondary',
                  textColor: Colors.white,
                ),
                const SizedBox(width: 12),
                _ColorCard(
                  color: AppColors.secondaryLight,
                  name: 'Secondary Light',
                  textColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Text Colors Section
            Text(
              'Text Colors',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primary Text - This is the main text style',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secondary Text - This is for supporting information',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hint Text - This is for placeholders and hints',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status Colors Section
            Text(
              'Status Colors',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatusChip(
                  color: AppColors.success,
                  label: 'Success',
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  color: AppColors.warning,
                  label: 'Warning',
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  color: AppColors.error,
                  label: 'Error',
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  color: AppColors.info,
                  label: 'Info',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // UI Elements Example
            Text(
              'UI Elements',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panel Example',
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is an example of using panel background with border.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorCard extends StatelessWidget {
  final Color color;
  final String name;
  final Color textColor;

  const _ColorCard({
    required this.color,
    required this.name,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            name,
            style: AppTextStyles.labelMedium.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusChip({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      ),
    );
  }
}