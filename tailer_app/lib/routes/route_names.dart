/// Route names for GoRouter navigation
/// Use these constants with context.goNamed() or context.pushNamed()
class RouteNames {
  // Splash & Onboarding
  static const String splash = 'splash';
  static const String onBoarding = 'onBoarding';
  static const String getStarted = 'getStarted';
  
  // Auth Routes
  static const String signIn = 'signIn';
  static const String signUp = 'signUp';
  static const String forgotPassword = 'forgotPassword';
  static const String otp = 'otp';
  static const String passwordReset = 'passwordReset';
  
  // Legal
  static const String privacyPolicy = 'privacyPolicy';
  
  // Main App
  static const String home = 'home';
  static const String dashboard = 'dashboard';
  static const String settings = 'settings';
  
  // Customers
  static const String customers = 'customers';
  static const String customerProfile = 'customerProfile';
  static const String addCustomer = 'addCustomer';
  static const String viewCustomers = 'viewCustomers';
  static const String customerDetails = 'customerDetails';
  static const String editCustomer = 'editCustomer';
  
  // Measurements
  static const String measurementList = 'measurementList';
  static const String measurementCategory = 'measurementCategory';
  static const String addMeasurement = 'addMeasurement';
  static const String editMeasurement = 'editMeasurement';
  
  // Orders
  static const String orders = 'orders';
  static const String orderList = 'orderList';
  static const String addOrder = 'addOrder';
  static const String orderDetails = 'orderDetails';
  static const String orderDetail = 'orderDetail';
  static const String editOrder = 'editOrder';
  
  // Demo
  static const String languageDemo = 'languageDemo';
  static const String languageSelection = 'languageSelection';
}

/// Extension to provide easy navigation methods
extension NavigationExtension on RouteNames {
  /// Example usage:
  /// ```dart
  /// // Simple navigation
  /// context.goNamed(RouteNames.dashboard);
  /// 
  /// // Navigation with path parameters
  /// context.goNamed(
  ///   RouteNames.customerDetails,
  ///   pathParameters: {'customerId': customer.uniqueId},
  /// );
  /// 
  /// // Navigation with query parameters
  /// context.goNamed(
  ///   RouteNames.addMeasurement,
  ///   pathParameters: {'customerId': customer.uniqueId},
  ///   queryParameters: {'dressType': 'shirt'},
  /// );
  /// ```
}
