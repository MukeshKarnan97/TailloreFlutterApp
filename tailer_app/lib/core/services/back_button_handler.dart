import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper service for handling Android back button behavior
class BackButtonHandler {
  
  /// Handle back button for main screens (Dashboard, Home, etc.)
  /// Shows confirmation dialog and provides options for navigation
  static Future<bool> handleMainScreenBack(
    BuildContext context, {
    String title = 'Navigation',
    String message = 'What would you like to do?',
    String homeOption = 'Go to Home',
    String exitOption = 'Exit App',
    String cancelOption = 'Cancel',
    String? homeRoute,
  }) async {
    if (!context.mounted) return false;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: Text(cancelOption),
          ),
          if (homeRoute != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop('home'),
              child: Text(homeOption),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('exit'),
            child: Text(exitOption),
          ),
        ],
      ),
    );
    
    switch (result) {
      case 'home':
        if (context.mounted && homeRoute != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            homeRoute,
            (route) => false,
          );
        }
        return false;
      case 'exit':
        SystemNavigator.pop();
        return true;
      default:
        return false;
    }
  }
  
  /// Simple exit confirmation for home screen
  static Future<bool> handleHomeScreenBack(BuildContext context) async {
    if (!context.mounted) return false;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      SystemNavigator.pop();
    }
    
    return false; // Always return false to prevent default pop behavior
  }
  
  /// Handle back button for detail screens
  /// Simply allows normal back navigation
  static bool handleDetailScreenBack(BuildContext context) {
    return true; // Allow normal back navigation
  }
  
  /// Create a PopScope widget with appropriate back handling
  static Widget wrapWithBackHandler({
    required Widget child,
    required BackHandlerType type,
    BuildContext? context,
    String? homeRoute,
  }) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop || context == null) return;
        
        switch (type) {
          case BackHandlerType.home:
            await handleHomeScreenBack(context);
            break;
          case BackHandlerType.main:
            await handleMainScreenBack(
              context,
              homeRoute: homeRoute ?? '/home',
            );
            break;
          case BackHandlerType.detail:
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            break;
        }
      },
      child: child,
    );
  }
}

enum BackHandlerType {
  home,    // For home screen - shows exit confirmation
  main,    // For main screens like dashboard - shows home/exit options  
  detail,  // For detail screens - allows normal back navigation
}