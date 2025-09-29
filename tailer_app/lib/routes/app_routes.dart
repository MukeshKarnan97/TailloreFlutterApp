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
import 'package:flutter/foundation.dart';
// import '../features/auth/screens/profile_setup_screen.dart';
// import '../features/customers/screens/customer_list_screen.dart';
// import '../features/orders/screens/order_list_screen.dart';
// import '../features/orders/screens/add_order_screen.dart';
// import '../features/measurements/screens/measurement_list_screen.dart';
// import '../features/reports/screens/reports_screen.dart';
// import '../features/settings/screens/settings_screen.dart';

class AppRoutes {
  static final router = GoRouter(
    initialLocation: '/splash', // Set splash as initial route
    routes: [
      // Splash Screen Route
      GoRoute(
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
        path: '/auth/on-boarding',
        pageBuilder: (context, state) =>
            buildPage(const WelcomeScreen(), state),
      ),
      GoRoute(
        path: '/auth/sign-in',
        pageBuilder: (context, state) => buildPage(SignIn(), state),
      ),
      GoRoute(
        path: '/auth/sign-up',
        pageBuilder: (context, state) => buildPage(SignUp(), state),
      ),
      GoRoute(
        path: '/auth/forgot_password',
        pageBuilder: (context, state) => buildPage(ForgotPassword(), state),
      ),
      // GoRoute(
      //   path: '/auth/otp',
      //   pageBuilder: (context, state) => buildPage(VerificationScreen(firstTitle: '', secondTitle: '', subText: '', onVerified: () {  },), state),
      // ),
      GoRoute(
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
        path: '/auth/password-reset',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String?;
          return buildPage(PasswordReset(email: email), state);
        },
      ),

      // Get Started Screen
      GoRoute(
        path: '/get-started',
        pageBuilder: (context, state) => buildPage(const GetStartedScreen(), state),
      ),

      // Privacy Policy
      GoRoute(
        path: '/privacy-policy',
        pageBuilder: (context, state) => buildPage(const PrivacyPolicyScreen(), state),
      ),

      // Home Screen
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => buildPage(const HomeScreen(), state),
      ),

      // Dashboard Screen
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => buildPage(const DashboardScreen(), state),
      ),

      // Customers Screen
      GoRoute(
        path: '/customers',
        pageBuilder: (context, state) => buildPage(const CustomersMainScreen(), state),
      ),

      // Customer Profile Screen
      GoRoute(
        path: '/customers/profile',
        pageBuilder: (context, state) => buildPage(const CustomerProfileScreen(), state),
      ),

      // Add Customer Screen
      GoRoute(
        path: '/customers/add',
        pageBuilder: (context, state) => buildPage(const AddCustomerScreen(), state),
      ),

      // View Customers Screen
      GoRoute(
        path: '/customers/view',
        pageBuilder: (context, state) => buildPage(const ViewCustomersScreen(), state),
      ),

      // Customer Details Screen
      GoRoute(
        path: '/customers/details/:customerId',
        pageBuilder: (context, state) {
          final customerId = state.pathParameters['customerId']!;
          return buildPage(CustomerDetailsScreen(customerId: customerId), state);
        },
      ),

      // Edit Customer Screen
      GoRoute(
        path: '/customers/edit/:customerId',
        pageBuilder: (context, state) {
          final customerId = state.pathParameters['customerId']!;
          return buildPage(EditCustomerScreen(customerId: customerId), state);
        },
      ),

      // GoRoute(path: '/profile-setup', builder: (context, state) => ProfileSetupScreen()),

      // // Customers
      // GoRoute(path: '/customers', builder: (context, state) => CustomerListScreen()),

      // // Orders
      // GoRoute(path: '/orders', builder: (context, state) => OrderListScreen()),
      // GoRoute(path: '/orders/add', builder: (context, state) => AddOrderScreen()),

      // // Measurements
      // GoRoute(path: '/measurements', builder: (context, state) => MeasurementListScreen()),

      // // Reports
      // GoRoute(path: '/reports', builder: (context, state) => ReportsScreen()),

      // // Settings
      // GoRoute(path: '/settings', builder: (context, state) => SettingsScreen()),
    ],
  );
}
