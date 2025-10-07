import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/utils/transition_helper.dart';
import 'package:tailer_app/features/auth/screens/otp_screen.dart';
import 'package:tailer_app/features/auth/screens/password_reset.dart';
import 'package:tailer_app/features/splash/splash_screen_manager.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/signin_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/privacy/privacy_policy_screen.dart';
import '../features/onboarding/get_started_screen.dart';
import '../features/home/home_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/customers/screens/customers_main_screen.dart';
import '../features/customers/screens/customer_profile_screen.dart';
import '../features/customers/screens/add_customer_screen.dart';
import '../features/customers/screens/view_customers_screen.dart';
import '../features/customers/screens/customer_details_screen.dart';
import '../features/customers/screens/edit_customer_screen.dart';
import '../features/measurements/screens/measurement_list_screen.dart';
import '../features/measurements/screens/measurement_category_screen.dart';
import '../features/measurements/screens/add_measurement_screen.dart';
import '../features/measurements/screens/edit_measurement_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/profile/edit_profile_screen.dart';
import '../features/settings/screens/profile/change_password_screen.dart';
import '../features/settings/screens/preferences/theme_selection_screen.dart';
import '../features/settings/screens/preferences/notification_settings_screen.dart';
import '../features/settings/screens/support/help_center_screen.dart';
import '../features/settings/screens/support/feedback_screen.dart';
import '../features/settings/screens/support/bug_report_screen.dart';
import '../features/settings/screens/legal/terms_of_service_screen.dart';
import '../features/settings/screens/privacy/privacy_security_screen.dart';
import '../features/demo/simple_language_demo_screen.dart';
import '../features/language/screens/language_selection_screen.dart';
import '../features/orders/screens/add_order_screen.dart';
import '../features/orders/screens/order_list_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/orders/screens/orders_main_screen.dart';
import '../features/payments/screens/payment_collection_screen.dart';
import '../features/payments/screens/payment_history_screen.dart';
import '../features/payments/screens/order_payment_history_screen.dart';
import '../screens/payment_reports_screen.dart';
import '../screens/refund_management_screen.dart';
import '../screens/receipt_management_screen.dart';
import '../data/models/order_model.dart';
import 'package:flutter/foundation.dart';

// Export route names for easy access
export 'route_names.dart';

class AppRoutes {
  static final router = GoRouter(
    initialLocation: '/splash', // Set splash as initial route
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Page Not Found', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text('Path: ${state.matchedLocation}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // Splash Screen Route
      GoRoute(
        name: 'splash',
        path: '/splash',
        pageBuilder: (context, state) => buildPage(
          const SplashScreenManager(
            mainAppBuilder: HomeScreen.new,
            authScreenBuilder: SignIn.new,
          ), 
          state
        ),
      ),
      
      // Auth routes
      GoRoute(
        name: 'onBoarding',
        path: '/auth/on-boarding',
        pageBuilder: (context, state) =>
            buildPage(const WelcomeScreen(), state),
      ),
      GoRoute(
        name: 'signIn',
        path: '/auth/sign-in',
        pageBuilder: (context, state) => buildPage(SignIn(), state),
      ),
      GoRoute(
        name: 'signUp',
        path: '/auth/sign-up',
        pageBuilder: (context, state) => buildPage(SignUp(), state),
      ),
      GoRoute(
        name: 'forgotPassword',
        path: '/auth/forgot_password',
        pageBuilder: (context, state) => buildPage(ForgotPassword(), state),
      ),
      GoRoute(
        name: 'otp',
        path: '/auth/otp',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          return buildPage(
            VerificationScreen(
              firstTitle: extra?['firstTitle'] as String? ?? 'Verification',
              secondTitle: extra?['secondTitle'] as String? ?? 'OTP',
              emailText: extra?['emailText'] as String? ?? '',
              email: extra?['email'] as String?,
              onVerified: extra?['onVerified'] as VoidCallback? ?? () {},
            ),
            state,
          );
        },
      ),

      GoRoute(
        name: 'passwordReset',
        path: '/auth/password-reset',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String?;
          return buildPage(PasswordReset(email: email), state);
        },
      ),

      // Get Started Screen
      GoRoute(
        name: 'getStarted',
        path: '/get-started',
        pageBuilder: (context, state) => buildPage(const GetStartedScreen(), state),
      ),

      // Privacy Policy
      GoRoute(
        name: 'privacyPolicy',
        path: '/privacy-policy',
        pageBuilder: (context, state) => buildPage(const PrivacyPolicyScreen(), state),
      ),

      // Home Screen
      GoRoute(
        name: 'home',
        path: '/home',
        pageBuilder: (context, state) => buildPage(const HomeScreen(), state),
      ),

      // Dashboard Screen
      GoRoute(
        name: 'dashboard',
        path: '/dashboard',
        pageBuilder: (context, state) => buildPage(const DashboardScreen(), state),
      ),

      // Customers Screen
      GoRoute(
        name: 'customers',
        path: '/customers',
        pageBuilder: (context, state) => buildPage(const CustomersMainScreen(), state),
      ),

      // Customer Profile Screen
      GoRoute(
        name: 'customerProfile',
        path: '/customers/profile',
        pageBuilder: (context, state) => buildPage(const CustomerProfileScreen(), state),
      ),

      // Add Customer Screen
      GoRoute(
        name: 'addCustomer',
        path: '/customers/add',
        pageBuilder: (context, state) => buildPage(const AddCustomerScreen(), state),
      ),

      // View Customers Screen
      GoRoute(
        name: 'viewCustomers',
        path: '/customers/view',
        pageBuilder: (context, state) => buildPage(const ViewCustomersScreen(), state),
      ),

      // Customer Details Screen
      GoRoute(
        name: 'customerDetails',
        path: '/customers/details/:customerId',
        pageBuilder: (context, state) {
          final customerId = state.pathParameters['customerId']!;
          return buildPage(CustomerDetailsScreen(customerId: customerId), state);
        },
      ),

      // Edit Customer Screen
      GoRoute(
        name: 'editCustomer',
        path: '/customers/edit/:customerId',
        pageBuilder: (context, state) {
          final customerId = state.pathParameters['customerId']!;
          return buildPage(EditCustomerScreen(customerId: customerId), state);
        },
      ),

      // Measurement List Screen
      GoRoute(
        name: 'measurementList',
        path: '/measurements/list/:customerId',
        pageBuilder: (context, state) {
          final customerId = state.pathParameters['customerId']!;
          return buildPage(MeasurementListScreen(customerId: customerId), state);
        },
      ),

      // Measurement Category Screen (Dress Type Selection)
      GoRoute(
        name: 'measurementCategory',
        path: '/measurements/category/:customerId',
        pageBuilder: (context, state) {
          final customerId = state.pathParameters['customerId']!;
          return buildPage(MeasurementCategoryScreen(customerId: customerId), state);
        },
      ),

      // Add Measurement Screen
      GoRoute(
        name: 'addMeasurement',
        path: '/measurements/add/:customerId',
        pageBuilder: (context, state) {
          final customerId = state.pathParameters['customerId']!;
          final dressType = state.uri.queryParameters['dressType'];
          return buildPage(AddMeasurementScreen(customerId: customerId, dressType: dressType), state);
        },
      ),

      // Edit Measurement Screen
      GoRoute(
        name: 'editMeasurement',
        path: '/measurements/edit/:measurementId',
        pageBuilder: (context, state) {
          final measurementId = state.pathParameters['measurementId']!;
          return buildPage(EditMeasurementScreen(measurementId: measurementId), state);
        },
      ),

      // Settings Screen
      GoRoute(
        name: 'settings',
        path: '/settings',
        pageBuilder: (context, state) => buildPage(const SettingsScreen(), state),
      ),

      // Settings Sub-screens
      GoRoute(
        name: 'editProfile',
        path: '/settings/edit-profile',
        pageBuilder: (context, state) => buildPage(const EditProfileScreen(), state),
      ),
      GoRoute(
        name: 'changePassword',
        path: '/settings/change-password',
        pageBuilder: (context, state) => buildPage(const ChangePasswordScreen(), state),
      ),
      GoRoute(
        name: 'themeSelection',
        path: '/settings/theme',
        pageBuilder: (context, state) => buildPage(const ThemeSelectionScreen(), state),
      ),
      GoRoute(
        name: 'notificationSettings',
        path: '/settings/notifications',
        pageBuilder: (context, state) => buildPage(const NotificationSettingsScreen(), state),
      ),
      GoRoute(
        name: 'helpCenter',
        path: '/settings/help',
        pageBuilder: (context, state) => buildPage(const HelpCenterScreen(), state),
      ),
      GoRoute(
        name: 'feedback',
        path: '/settings/feedback',
        pageBuilder: (context, state) => buildPage(const FeedbackScreen(), state),
      ),
      GoRoute(
        name: 'bugReport',
        path: '/settings/bug-report',
        pageBuilder: (context, state) => buildPage(const BugReportScreen(), state),
      ),
      GoRoute(
        name: 'termsOfService',
        path: '/settings/terms',
        pageBuilder: (context, state) => buildPage(const TermsOfServiceScreen(), state),
      ),
      GoRoute(
        name: 'privacySecurity',
        path: '/settings/privacy-security',
        pageBuilder: (context, state) => buildPage(const PrivacySecurityScreen(), state),
      ),

      // Language Demo Screen
      GoRoute(
        name: 'languageDemo',
        path: '/demo/language',
        pageBuilder: (context, state) => buildPage(const SimpleLanguageDemoScreen(), state),
      ),

      // Language Selection Screen
      GoRoute(
        name: 'languageSelection',
        path: '/language/selection',
        pageBuilder: (context, state) => buildPage(const LanguageSelectionScreen(), state),
      ),

      // GoRoute(path: '/profile-setup', builder: (context, state) => ProfileSetupScreen()),

      // // Customers
      // GoRoute(path: '/customers', builder: (context, state) => CustomerListScreen()),

      // // Orders
      GoRoute(
        name: 'orders',
        path: '/orders',
        pageBuilder: (context, state) => buildPage(const OrdersMainScreen(), state),
      ),
      GoRoute(
        name: 'orderList',
        path: '/orders/list',
        pageBuilder: (context, state) => buildPage(const OrderListScreen(), state),
      ),
      GoRoute(
        name: 'addOrder',
        path: '/orders/add',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return buildPage(AddOrderScreen(extra: extra), state);
        },
      ),
      GoRoute(
        name: 'orderDetails',
        path: '/orders/details',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null && extra['order'] != null) {
            final orderData = extra['order'] as Map<String, dynamic>;
            final order = Order.fromMap(orderData);
            return buildPage(OrderDetailScreen(order: order), state);
          }
          // Fallback - redirect to dashboard if no order data
          return buildPage(const DashboardScreen(), state);
        },
      ),
      GoRoute(
        name: 'orderDetail',
        path: '/orders/detail',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null && extra['order'] != null) {
            final order = extra['order'] as Order;
            return buildPage(OrderDetailScreen(order: order), state);
          }
          // Fallback - go back if no order provided
          return buildPage(const OrderListScreen(), state);
        },
      ),

      // Payments
      GoRoute(
        name: 'paymentCollection',
        path: '/payments/collection',
        pageBuilder: (context, state) => buildPage(const PaymentCollectionScreen(), state),
      ),
      GoRoute(
        name: 'paymentHistory',
        path: '/payments/history',
        pageBuilder: (context, state) => buildPage(const PaymentHistoryScreen(), state),
      ),
      GoRoute(
        name: 'orderPaymentHistory',
        path: '/payments/order-history',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null && extra['orderId'] != null) {
            final orderId = extra['orderId'] as String;
            final order = extra['order'] as Order?;
            return buildPage(OrderPaymentHistoryScreen(orderId: orderId, order: order), state);
          }
          // Fallback - redirect to payment collection if no order provided
          return buildPage(const PaymentCollectionScreen(), state);
        },
      ),
      GoRoute(
        name: 'paymentReports',
        path: '/payments/reports',
        pageBuilder: (context, state) => buildPage(const PaymentReportsScreen(), state),
      ),
      GoRoute(
        name: 'refundManagement',
        path: '/payments/refunds',
        pageBuilder: (context, state) => buildPage(const RefundManagementScreen(), state),
      ),
      GoRoute(
        name: 'receiptManagement',
        path: '/payments/receipts',
        pageBuilder: (context, state) => buildPage(const ReceiptManagementScreen(), state),
      ),

      // // Measurements
      // GoRoute(path: '/measurements', builder: (context, state) => MeasurementListScreen()),

      // // Reports
      // GoRoute(path: '/reports', builder: (context, state) => ReportsScreen()),

      // // Settings
      // GoRoute(path: '/settings', builder: (context, state) => SettingsScreen()),
    ],
  );
}
