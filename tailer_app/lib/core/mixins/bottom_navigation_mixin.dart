import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/widgets/custom_bottom_navigation.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';

/// Mixin to provide standardized bottom navigation functionality
/// This ensures consistent navigation behavior across all screens
mixin BottomNavigationMixin<T extends StatefulWidget> on State<T> {
  
  /// Current navigation index - override in your widget
  int get currentNavIndex;
  
  /// Set the navigation index - implement in your widget
  void setNavIndex(int index);
  
  /// Get localized navigation items
  List<BottomNavItem> getNavigationItems(AppLocalizations locale) {
    return TailorAppBottomNavItems.getLocalizedItems(
      dashboardLabel: locale.t('dashboard'),
      customersLabel: locale.t('customers'), 
      ordersLabel: locale.t('orders'),
      settingsLabel: locale.t('settings'),
    );
  }
  
  /// Standardized navigation handler
  /// This fixes the popup-only issue by ensuring proper navigation
  void handleNavigation(int index) {
    // Prevent navigation to same tab
    if (index == currentNavIndex) return;
    
    // Update current index immediately for UI feedback
    setNavIndex(index);
    
    // Perform actual navigation with proper error handling
    try {
      switch (index) {
        case 0: // Dashboard
          if (mounted) context.goNamed(RouteNames.dashboard);
          break;
        case 1: // Customers  
          if (mounted) context.goNamed(RouteNames.customers);
          break;
        case 2: // Orders
          if (mounted) context.goNamed(RouteNames.orders);
          break;
        case 3: // Settings
          if (mounted) context.goNamed(RouteNames.settings);
          break;
        default:
          debugPrint('Unknown navigation index: $index');
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Show error feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  /// Build the standardized bottom navigation
  Widget buildBottomNavigation(AppLocalizations locale) {
    return AnimatedBottomNavigation(
      currentIndex: currentNavIndex,
      onTap: handleNavigation,
      items: getNavigationItems(locale),
      backgroundColor: Colors.white,
      selectedItemColor: const Color(AppConstants.primaryTeal),
      unselectedItemColor: Colors.grey.shade600,
      elevation: 15.0,
      animationDuration: const Duration(milliseconds: 200),
    );
  }
}