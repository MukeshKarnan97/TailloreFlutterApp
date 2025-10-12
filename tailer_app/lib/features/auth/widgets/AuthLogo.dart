// logo_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class LogoWidget extends StatelessWidget {
  final double height_;
  final double width_;

  // Constructor
  const LogoWidget({
    Key? key,
    required this.height_,
    required this.width_,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width_,
      height: height_,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
            AppColors.secondary.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(width_ * 0.2), // 20% of width for rounded corners
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width_ * 0.2),
        child: Padding(
          padding: EdgeInsets.all(width_ * 0.15), // 15% padding
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: width_ * 0.7,
            height: height_ * 0.7,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image fails to load
              return Icon(
                Icons.content_cut,
                size: width_ * 0.5,
                color: Colors.white,
              );
            },
          ),
        ),
      ),
    );
  }
}
