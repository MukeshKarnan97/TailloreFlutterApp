import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/routes/app_routes.dart';

void main() {
  runApp(DebugNavigationApp());
}

class DebugNavigationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Navigation Debug',
      routerConfig: AppRoutes.router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class NavigationTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Navigation Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                debugPrint('Testing navigation to /auth/sign-up');
                try {
                  context.go('/auth/sign-up');
                  debugPrint('Navigation to sign-up successful');
                } catch (e) {
                  debugPrint('Navigation to sign-up failed: $e');
                }
              },
              child: Text('Go to Sign Up'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                debugPrint('Testing navigation to /auth/forgot_password');
                try {
                  context.go('/auth/forgot_password');
                  debugPrint('Navigation to forgot password successful');
                } catch (e) {
                  debugPrint('Navigation to forgot password failed: $e');
                }
              },
              child: Text('Go to Forgot Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                debugPrint('Testing navigation to /auth/sign-in');
                try {
                  context.go('/auth/sign-in');
                  debugPrint('Navigation to sign-in successful');
                } catch (e) {
                  debugPrint('Navigation to sign-in failed: $e');
                }
              },
              child: Text('Go to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}