import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routes/app_routes.dart';

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final GoRouter _router = AppRoutes.router; // Centralized navigation

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Digitasdasfl Tailor',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      routerConfig: _router, // Connects all routes/screens
    );
  }
}
