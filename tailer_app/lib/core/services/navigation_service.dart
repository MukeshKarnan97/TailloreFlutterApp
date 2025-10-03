import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';

/// Common navigation service for the entire app
/// Handles all navigation logic and messaging in one place
class NavigationService {
  /// Show a navigation message with optional custom styling
  static void showNavigationMessage(
    BuildContext context,
    String destination, {
    Color? backgroundColor,
    Duration? duration,
    String? customMessage,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(customMessage ?? 'Navigate to $destination'),
        backgroundColor: backgroundColor ?? const Color(AppConstants.primaryTeal),
        duration: duration ?? const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Navigate to a destination with optional route
  /// If route is provided, performs actual navigation
  /// Otherwise shows a placeholder message
  static void navigateToDestination(
    BuildContext context,
    String destination, {
    String? route,
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
    Object? extra,
  }) {
    if (route != null) {
      if (pathParameters != null || queryParameters != null || extra != null) {
        context.goNamed(
          route,
          pathParameters: pathParameters ?? {},
          queryParameters: queryParameters ?? {},
          extra: extra,
        );
      } else {
        context.go(route);
      }
    } else {
      // Show placeholder message for unimplemented routes
      final backgroundColor = _getDestinationColor(destination);
      showNavigationMessage(context, destination, backgroundColor: backgroundColor);
    }
  }

  /// Navigate and replace current route
  static void navigateAndReplace(
    BuildContext context,
    String route, {
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
    Object? extra,
  }) {
    if (pathParameters != null || queryParameters != null || extra != null) {
      context.goNamed(
        route,
        pathParameters: pathParameters ?? {},
        queryParameters: queryParameters ?? {},
        extra: extra,
      );
    } else {
      context.go(route);
    }
  }

  /// Push a new route on top of current route
  static void pushRoute(
    BuildContext context,
    String route, {
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
    Object? extra,
  }) {
    if (pathParameters != null || queryParameters != null || extra != null) {
      context.pushNamed(
        route,
        pathParameters: pathParameters ?? {},
        queryParameters: queryParameters ?? {},
        extra: extra,
      );
    } else {
      context.push(route);
    }
  }

  /// Pop current route
  static void pop(BuildContext context, [Object? result]) {
    context.pop(result);
  }

  /// Handle bottom navigation with index-based routing
  static void handleBottomNavigation(
    BuildContext context,
    int index,
    int currentIndex,
    Function(int) onIndexChanged, {
    List<String?>? routes,
    List<String>? destinations,
  }) {
    if (index == currentIndex) {
      // If already on the current tab, do nothing
      return;
    }

    onIndexChanged(index);

    // Use RouteNames for proper navigation - no more null routes!
    final defaultRoutes = [
      NavigationRoutes.dashboard,
      NavigationRoutes.customers, 
      NavigationRoutes.orders,
      NavigationRoutes.settings
    ];
    final defaultDestinations = ['Dashboard', 'Customers', 'Orders', 'Settings'];

    final navigationRoutes = routes ?? defaultRoutes;
    final navigationDestinations = destinations ?? defaultDestinations;

    if (index < navigationRoutes.length) {
      final route = navigationRoutes[index];
      final destination = index < navigationDestinations.length 
          ? navigationDestinations[index] 
          : 'Page ${index + 1}';

      if (route != null) {
        // Perform actual navigation
        try {
          if (context.mounted) {
            context.go(route);
          }
        } catch (e) {
          // Fallback to showing message if navigation fails
          navigateToDestination(context, destination);
        }
      } else {
        // For unimplemented routes, show message
        navigateToDestination(context, destination);
      }
    }
  }

  /// Get appropriate color for different destinations
  static Color _getDestinationColor(String destination) {
    switch (destination.toLowerCase()) {
      case 'customer profile':
      case 'customers':
      case 'dashboard':
        return const Color(AppConstants.primaryTeal);
      case 'measurements':
        return const Color(AppConstants.primaryOrange);
      case 'orders':
        return const Color(AppConstants.primaryTeal);
      case 'settings':
        return Colors.grey[600] ?? Colors.grey;
      default:
        return const Color(AppConstants.primaryTeal);
    }
  }
}

/// Common navigation routes
class NavigationRoutes {
  static const String dashboard = '/dashboard';
  static const String customers = '/customers';
  static const String customerProfile = '/customers/profile';
  static const String addCustomer = '/customers/add';
  static const String viewCustomers = '/customers/view';
  static const String customerDetails = '/customers/details';
  static const String editCustomer = '/customers/edit';
  static const String measurements = '/customers/measurements';
  static const String orders = '/orders';
  static const String settings = '/settings';
  static const String login = '/login';
  static const String signup = '/signup';
}

/// Common destination names
class NavigationDestinations {
  static const String dashboard = 'Dashboard';
  static const String customers = 'Customers';
  static const String customerProfile = 'Customer Profile';
  static const String measurements = 'Measurements';
  static const String orders = 'Orders';
  static const String settings = 'Settings';
  static const String login = 'Login';
  static const String signup = 'Sign Up';
}