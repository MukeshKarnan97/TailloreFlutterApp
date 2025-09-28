import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_constants.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final String? subtitle;

  const DashboardCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = const Color(AppConstants.primaryTeal),
    this.backgroundColor = Colors.white,
    this.onTap,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Title Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.spacingS),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            // Value
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            // Subtitle (optional)
            if (subtitle != null) ...[
              const SizedBox(height: AppConstants.spacingXS),
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}