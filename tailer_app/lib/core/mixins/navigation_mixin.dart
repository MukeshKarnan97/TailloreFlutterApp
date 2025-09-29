import 'package:flutter/material.dart';
import 'package:tailer_app/core/services/navigation_service.dart';

/// Mixin to provide common navigation functionality to any screen
/// Usage: class MyScreen extends StatefulWidget with NavigationMixin
mixin NavigationMixin {
  /// Handle bottom navigation for any screen
  void handleBottomNavigation(
    BuildContext context,
    int index,
    int currentIndex,
    Function(int) onIndexChanged, {
    List<String?>? customRoutes,
    List<String>? customDestinations,
  }) {
    NavigationService.handleBottomNavigation(
      context,
      index,
      currentIndex,
      onIndexChanged,
      routes: customRoutes,
      destinations: customDestinations,
    );
  }

  /// Navigate to any destination
  void navigateTo(
    BuildContext context,
    String destination, {
    String? route,
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
    Object? extra,
  }) {
    NavigationService.navigateToDestination(
      context,
      destination,
      route: route,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Show navigation message
  void showNavigationMessage(
    BuildContext context,
    String destination, {
    Color? backgroundColor,
    Duration? duration,
    String? customMessage,
  }) {
    NavigationService.showNavigationMessage(
      context,
      destination,
      backgroundColor: backgroundColor,
      duration: duration,
      customMessage: customMessage,
    );
  }

  /// Quick navigation to common destinations
  void navigateToDashboard(BuildContext context) {
    NavigationService.navigateToDestination(
      context,
      NavigationDestinations.dashboard,
      route: NavigationRoutes.dashboard,
    );
  }

  void navigateToCustomers(BuildContext context) {
    NavigationService.navigateToDestination(
      context,
      NavigationDestinations.customers,
      route: NavigationRoutes.customers,
    );
  }

  void navigateToCustomerProfile(BuildContext context) {
    NavigationService.navigateToDestination(
      context,
      NavigationDestinations.customerProfile,
    );
  }

  void navigateToMeasurements(BuildContext context) {
    NavigationService.navigateToDestination(
      context,
      NavigationDestinations.measurements,
    );
  }

  void navigateToOrders(BuildContext context) {
    NavigationService.navigateToDestination(
      context,
      NavigationDestinations.orders,
    );
  }

  void navigateToSettings(BuildContext context) {
    NavigationService.navigateToDestination(
      context,
      NavigationDestinations.settings,
    );
  }
}