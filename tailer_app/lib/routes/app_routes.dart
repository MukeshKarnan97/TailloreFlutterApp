import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/utils/transition_helper.dart';
import 'package:tailer_app/features/auth/screens/otp_screen.dart';
import 'package:tailer_app/features/auth/screens/password_reset.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/signin_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import 'package:flutter/foundation.dart';
// import '../features/auth/screens/profile_setup_screen.dart';
// import '../features/dashboard/screens/dashboard_screen.dart';
// import '../features/customers/screens/customer_list_screen.dart';
// import '../features/orders/screens/order_list_screen.dart';
// import '../features/orders/screens/add_order_screen.dart';
// import '../features/measurements/screens/measurement_list_screen.dart';
// import '../features/reports/screens/reports_screen.dart';
// import '../features/settings/screens/settings_screen.dart';

class AppRoutes {
  static final router = GoRouter(
    initialLocation:
        '/auth/password_reset', // Set initial route here - FIRST SCREEN
    routes: [
      // GoRoute(path: '/splash', builder: (context, state) => WelcomeScreen()),
      // GoRoute(path: '/login', builder: (context, state) => LogIn()),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            buildPage(const WelcomeScreen(), state),
      ),
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
              onVerified: extra?['onVerified'] as VoidCallback? ?? () {},
            ),
            state,
          );
        },
      ),

      GoRoute(
        path: '/auth/password_reset',
        pageBuilder: (context, state) => buildPage(PasswordReset(), state),
      ),

      // GoRoute(path: '/profile-setup', builder: (context, state) => ProfileSetupScreen()),
      // GoRoute(path: '/dashboard', builder: (context, state) => DashboardScreen()),

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
