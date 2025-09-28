import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// UserFeedbackService - Centralized service for user notifications
/// 
/// Provides consistent user feedback through various notification methods:
/// - Toast messages (SnackBar)
/// - Alert dialogs
/// - Bottom sheet notifications
/// - Haptic feedback
/// - Sound feedback
class UserFeedbackService {
  static final UserFeedbackService _instance = UserFeedbackService._internal();
  factory UserFeedbackService() => _instance;
  UserFeedbackService._internal();

  // ==================== TOAST MESSAGES ====================

  /// Show success toast message
  static void showSuccess(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      type: FeedbackType.success,
      icon: Icons.check_circle,
    );
  }

  /// Show error toast message
  static void showError(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      type: FeedbackType.error,
      icon: Icons.error,
    );
  }

  /// Show warning toast message
  static void showWarning(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      type: FeedbackType.warning,
      icon: Icons.warning,
    );
  }

  /// Show info toast message
  static void showInfo(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      type: FeedbackType.info,
      icon: Icons.info,
    );
  }

  /// Show loading toast message
  static void showLoading(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      type: FeedbackType.loading,
      icon: Icons.refresh,
      duration: const Duration(seconds: 5),
    );
  }

  // ==================== SPECIFIC USER MESSAGES ====================

  /// Show user not found message with helpful suggestions
  static void showUserNotFound(BuildContext context) {
    _showToast(
      context: context,
      message: "User not found. Please check your email address or sign up for a new account.",
      type: FeedbackType.error,
      icon: Icons.person_off,
      duration: const Duration(seconds: 4),
    );
    _triggerHapticFeedback(HapticType.error);
  }

  /// Show invalid credentials message
  static void showInvalidCredentials(BuildContext context) {
    _showToast(
      context: context,
      message: "Invalid email or password. Please check your credentials and try again.",
      type: FeedbackType.error,
      icon: Icons.lock_outline,
      duration: const Duration(seconds: 4),
    );
    _triggerHapticFeedback(HapticType.error);
  }

  /// Show account locked message
  static void showAccountLocked(BuildContext context) {
    _showToast(
      context: context,
      message: "Account temporarily locked due to multiple failed attempts. Try again later.",
      type: FeedbackType.warning,
      icon: Icons.lock,
      duration: const Duration(seconds: 5),
    );
    _triggerHapticFeedback(HapticType.warning);
  }

  /// Show network error message
  static void showNetworkError(BuildContext context) {
    _showToast(
      context: context,
      message: "Network error. Please check your connection and try again.",
      type: FeedbackType.error,
      icon: Icons.wifi_off,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show sign-in success message
  static void showSignInSuccess(BuildContext context, String userEmail) {
    _showToast(
      context: context,
      message: "Welcome back! Signed in successfully.",
      type: FeedbackType.success,
      icon: Icons.login,
      duration: const Duration(seconds: 3),
    );
    _triggerHapticFeedback(HapticType.success);
  }

  /// Show sign-up success message
  static void showSignUpSuccess(BuildContext context) {
    _showToast(
      context: context,
      message: "Account created successfully! Please verify your email.",
      type: FeedbackType.success,
      icon: Icons.person_add,
      duration: const Duration(seconds: 4),
    );
    _triggerHapticFeedback(HapticType.success);
  }

  // ==================== ALERT DIALOGS ====================

  /// Show confirmation dialog
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
              ],
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Show error dialog with detailed information
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? details,
    String buttonText = 'OK',
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (details != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Details: $details',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  // ==================== BOTTOM SHEET NOTIFICATIONS ====================

  /// Show bottom sheet notification for important messages
  static void showBottomSheetNotification({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    Color? color,
    List<Widget>? actions,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 28),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (actions != null) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: actions,
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ==================== PRIVATE HELPER METHODS ====================

  static void _showToast({
    required BuildContext context,
    required String message,
    required FeedbackType type,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final colors = _getColorsForType(type, context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colors.backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        action: type == FeedbackType.error || type == FeedbackType.warning
            ? SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
            : null,
      ),
    );
  }

  static _FeedbackColors _getColorsForType(FeedbackType type, BuildContext context) {
    switch (type) {
      case FeedbackType.success:
        return _FeedbackColors(
          backgroundColor: Colors.green[600]!,
          textColor: Colors.white,
        );
      case FeedbackType.error:
        return _FeedbackColors(
          backgroundColor: Colors.red[600]!,
          textColor: Colors.white,
        );
      case FeedbackType.warning:
        return _FeedbackColors(
          backgroundColor: Colors.orange[600]!,
          textColor: Colors.white,
        );
      case FeedbackType.info:
        return _FeedbackColors(
          backgroundColor: Colors.blue[600]!,
          textColor: Colors.white,
        );
      case FeedbackType.loading:
        return _FeedbackColors(
          backgroundColor: Colors.grey[600]!,
          textColor: Colors.white,
        );
    }
  }

  static void _triggerHapticFeedback(HapticType type) {
    switch (type) {
      case HapticType.success:
        HapticFeedback.lightImpact();
        break;
      case HapticType.error:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.warning:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }
}

// ==================== ENUMS AND MODELS ====================

enum FeedbackType {
  success,
  error,
  warning,
  info,
  loading,
}

enum HapticType {
  success,
  error,
  warning,
  selection,
}

class _FeedbackColors {
  final Color backgroundColor;
  final Color textColor;

  _FeedbackColors({
    required this.backgroundColor,
    required this.textColor,
  });
}