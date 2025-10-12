import 'package:flutter/material.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'core/config/app_config.dart';
import 'core/utils/logger.dart';
import 'core/constants/app_colors.dart';
import 'force_db_migration.dart';

void main() async {
  return Logger.traceAsyncMethod('Main', 'main', () async {
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize application configuration
    await AppConfig.initialize();
    
    // FORCE DATABASE MIGRATION - Remove after first successful run
    await forceDatabaseMigration();
    
    // Set up logger based on configuration
    Logger.setLogLevel(AppConfig.logLevel);
    
    // Validate configuration
    final isConfigValid = AppConfig.validateConfig();
    if (!isConfigValid) {
      Logger.error('Main', 'Configuration validation failed - some features may not work properly');
    }
    
    Logger.header('Application Starting');
    Logger.info('Main', 'App: ${AppConfig.appName} v${AppConfig.appVersion}');
    Logger.info('Main', 'Environment: ${AppConfig.environment}');
    Logger.info('Main', 'Debug logs: ${AppConfig.enableDebugLogs}');
    
    runApp(const TailorApp());
  });
}

class TailorApp extends StatelessWidget {
  const TailorApp({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.info('TailorApp', 'Building application widget');
    
    return MaterialApp.router(
      debugShowCheckedModeBanner: !AppConfig.isProduction,
      title: AppConfig.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        // Enable dark mode based on configuration
        brightness: AppConfig.enableDarkMode ? Brightness.dark : Brightness.light,
      ),
      routerConfig: AppRoutes.router,
    );
  }
}

