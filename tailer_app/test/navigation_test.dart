import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:tailer_app/features/auth/screens/signin_screen.dart';

void main() {
  group('Navigation Tests', () {
    testWidgets('Should navigate to dashboard after sign-in', (WidgetTester tester) async {
      // Create a simple router for testing
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/signin',
            builder: (context, state) => const SignIn(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
        ],
        initialLocation: '/signin',
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Verify we start on sign-in screen
      expect(find.byType(SignIn), findsOneWidget);

      // Test navigation to dashboard
      router.go('/dashboard');
      await tester.pumpAndSettle();

      // Verify we're now on dashboard screen
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Dashboard screen should load without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );

      // Wait for any loading states to complete
      await tester.pumpAndSettle();

      // Verify dashboard elements are present
      expect(find.text('Welcome back to your tailoring business'), findsOneWidget);
      expect(find.text('Business Overview'), findsOneWidget);
      expect(find.text('Today\'s Overview'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('Dashboard should show business metrics', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Verify business metrics are displayed
      expect(find.text('Total Customers'), findsOneWidget);
      expect(find.text('Active Orders'), findsOneWidget);
      expect(find.text('Completed Orders'), findsOneWidget);
      expect(find.text('Total Revenue'), findsOneWidget);
    });

    testWidgets('Dashboard should show quick actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Verify quick actions are present
      expect(find.text('Add New Customer'), findsOneWidget);
      expect(find.text('Create Order'), findsOneWidget);
      expect(find.text('Take Measurements'), findsOneWidget);
    });
  });
}