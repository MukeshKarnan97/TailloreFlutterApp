import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite/sqflite.dart';
import 'animated_splash_screen.dart';


import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/onboarding_helper.dart';
import '../../data/services/local_db_service.dart';

/// SplashScreenManager - Manages splash screen flow and app initialization
/// 
/// This widget handles:
/// - App initialization tasks
/// - Database setup
/// - Configuration validation
/// - Authentication state checking
/// - Smooth transition to main app
/// - Error handling during initialization
class SplashScreenManager extends StatefulWidget {
  final Widget Function() mainAppBuilder;
  final Widget Function()? authScreenBuilder;
  final Duration splashDuration;
  
  const SplashScreenManager({
    Key? key,
    required this.mainAppBuilder,
    this.authScreenBuilder,
    this.splashDuration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<SplashScreenManager> createState() => _SplashScreenManagerState();
}

class _SplashScreenManagerState extends State<SplashScreenManager> {
  static const String _className = 'SplashScreenManager';
  
  bool _isInitialized = false;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    Logger.startTrace(_className, 'initState');
    
    _initializeApp();
    
    Logger.endTrace(_className, 'initState');
  }

  /// Initialize the application
  Future<void> _initializeApp() async {
    return Logger.traceAsyncMethod(_className, '_initializeApp', () async {
      try {
        Logger.header('App Initialization Starting');
        
        // Set preferred orientations
        await _setPreferredOrientations();
        
        // Initialize configuration if not already done
        if (!AppConfig.isInitialized) {
          await AppConfig.initialize();
        }
        
        // Validate configuration
        await _validateConfiguration();
        
        // Initialize database
        await _initializeDatabase();
        
        // Check authentication state
        await _checkAuthenticationState();
        
        // Perform any additional initialization
        await _performAdditionalInitialization();
        
        Logger.info(_className, 'App initialization completed successfully');
        Logger.header('App Ready');
        
        setState(() {
          _isInitialized = true;
        });
        
      } catch (e, stackTrace) {
        Logger.error(_className, 'App initialization failed', error: e, stackTrace: stackTrace);
        
        setState(() {
          _hasError = true;
        });
      }
    });
  }

  /// Set preferred device orientations
  Future<void> _setPreferredOrientations() async {
    Logger.debug(_className, 'Setting preferred orientations');
    
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    Logger.debug(_className, 'Preferred orientations set to portrait only');
  }

  /// Validate application configuration
  Future<void> _validateConfiguration() async {
    return Logger.traceAsyncMethod(_className, '_validateConfiguration', () async {
      Logger.info(_className, 'Validating application configuration');
      
      final isValid = AppConfig.validateConfig();
      if (!isValid) {
        throw Exception('Configuration validation failed');
      }
      
      // Log current configuration
      Logger.info(_className, 'App: ${AppConfig.appName} v${AppConfig.appVersion}');
      Logger.info(_className, 'Environment: ${AppConfig.environment}');
      Logger.info(_className, 'Database: ${AppConfig.databaseName}');
      
      Logger.info(_className, 'Configuration validation passed');
    });
  }

  /// Initialize local database
  /// Creates database file, tables, indexes, and verifies connectivity
  Future<void> _initializeDatabase() async {
    return Logger.traceAsyncMethod(_className, '_initializeDatabase', () async {
      Logger.info(_className, 'Starting database initialization');
      Logger.separator(title: 'Database Setup');
      
      final dbService = LocalDatabaseService();
      
      try {
        // Initialize database connection and create tables
        final db = await dbService.database;
        Logger.info(_className, '✅ Database file created: ${AppConfig.databaseName}');
        Logger.info(_className, '✅ Database version: ${AppConfig.databaseVersion}');
        
        // Verify database connectivity
        await db.rawQuery('SELECT 1');
        Logger.info(_className, '✅ Database connectivity verified');
        
        // Verify that all required tables exist
        await _verifyDatabaseTables(db);
        
        // Get comprehensive database statistics
        final stats = await dbService.getDatabaseStats();
        Logger.info(_className, '📊 Database statistics:');
        
        // Log table counts
        stats.forEach((table, count) {
          Logger.info(_className, '   • $table: $count records');
        });
        
        // Verify foreign key constraints are enabled
        final foreignKeyResult = await db.rawQuery('PRAGMA foreign_keys');
        final foreignKeysEnabled = foreignKeyResult.first['foreign_keys'] == 1;
        Logger.info(_className, '🔐 Foreign key constraints: ${foreignKeysEnabled ? "✅ Enabled" : "❌ Disabled"}');
        
        // Check database size and performance
        final dbSize = await _getDatabaseSize();
        Logger.info(_className, '💾 Database size: ${dbSize}KB');
        
        Logger.info(_className, '🎉 Database initialization completed successfully');
        Logger.separator();
        
      } catch (e, stackTrace) {
        Logger.error(_className, 'Database initialization failed', error: e, stackTrace: stackTrace);
        
        // Attempt database recovery
        Logger.warning(_className, 'Attempting database recovery...');
        try {
          // Close and delete the problematic database
          await dbService.closeDatabase();
          await dbService.deleteDatabase();
          Logger.info(_className, '🗑️ Deleted problematic database');
          
          // Recreate database with tables
          final newDb = await dbService.database;
          Logger.info(_className, '✅ Database recreated successfully');
          
          // Verify tables were created in the new database
          await _verifyDatabaseTables(newDb);
          Logger.info(_className, '✅ All tables verified in new database');
          
          Logger.info(_className, '✅ Database recovery completed successfully');
        } catch (recoveryError) {
          Logger.error(_className, 'Database recovery failed', error: recoveryError);
          rethrow;
        }
      }
    });
  }
  
  /// Verify that all required database tables exist
  Future<void> _verifyDatabaseTables(Database db) async {
    final requiredTables = [
      'tailor',
      'customer', 
      'measurement',
      'orders',
      'payment',
      'users',
      'auth_sessions',
      'user_preferences',
      'login_history'
    ];
    
    Logger.info(_className, '🔍 Verifying database tables...');
    
    for (final tableName in requiredTables) {
      try {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName]
        );
        
        if (result.isEmpty) {
          throw Exception('Required table "$tableName" does not exist');
        }
        
        // Test table structure by counting records
        await db.rawQuery('SELECT COUNT(*) FROM $tableName');
        Logger.debug(_className, '   ✅ Table "$tableName" exists and accessible');
        
      } catch (e) {
        Logger.error(_className, '   ❌ Table "$tableName" verification failed: $e');
        throw Exception('Database table verification failed for "$tableName": $e');
      }
    }
    
    Logger.info(_className, '✅ All required tables verified successfully');
  }
  
  /// Get database file size in KB
  Future<int> _getDatabaseSize() async {
    try {
      final dbService = LocalDatabaseService();
      final db = await dbService.database;
      final result = await db.rawQuery('PRAGMA page_count;');
      final pageCount = result.first['page_count'] as int;
      final pageSizeResult = await db.rawQuery('PRAGMA page_size;');
      final pageSize = pageSizeResult.first['page_size'] as int;
      return (pageCount * pageSize) ~/ 1024; // Convert to KB
    } catch (e) {
      Logger.warning('SplashScreenManager', 'Could not determine database size: $e');
      return 0;
    }
  }

  /// Check authentication state
  Future<void> _checkAuthenticationState() async {
    return Logger.traceAsyncMethod(_className, '_checkAuthenticationState', () async {
      Logger.info(_className, 'Checking authentication state');
      
      // TODO: Implement authentication state checking
      // This would typically involve:
      // - Checking for stored JWT tokens
      // - Validating token expiration
      // - Refreshing tokens if needed
      // - Setting up user session
      
      Logger.debug(_className, 'Authentication state check completed');
    });
  }

  /// Perform additional initialization tasks
  Future<void> _performAdditionalInitialization() async {
    return Logger.traceAsyncMethod(_className, '_performAdditionalInitialization', () async {
      Logger.debug(_className, 'Performing additional initialization tasks');
      
      // Simulate some initialization delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      // TODO: Add any additional initialization tasks here:
      // - Initialize analytics
      // - Set up crash reporting
      // - Initialize push notifications
      // - Load user preferences
      // - Sync offline data
      
      Logger.debug(_className, 'Additional initialization tasks completed');
    });
  }

  /// Handle splash screen animation completion
  void _onSplashAnimationComplete() {
    Logger.info(_className, 'Splash animation completed');
    
    if (_isInitialized && !_hasError) {
      Logger.info(_className, 'Transitioning to main app');
      _navigateToMainApp();
    } else if (_hasError) {
      Logger.warning(_className, 'Initialization failed, showing error screen');
      _showErrorScreen();
    } else {
      Logger.debug(_className, 'Still initializing, waiting for completion');
      // Wait for initialization to complete
      _waitForInitialization();
    }
  }

  /// Wait for initialization to complete
  void _waitForInitialization() {
    Logger.debug(_className, 'Waiting for app initialization to complete');
    
    // Check every 100ms if initialization is complete
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        if (_isInitialized && !_hasError) {
          _navigateToMainApp();
        } else if (_hasError) {
          _showErrorScreen();
        } else {
          _waitForInitialization();
        }
      }
    });
  }

  /// Navigate to main app
  void _navigateToMainApp() async {
    Logger.info(_className, 'Checking onboarding completion before navigation');
    
    try {
      // Check if complete onboarding flow is finished
      final onboardingComplete = await OnboardingHelper.isOnboardingComplete();
      
      if (mounted) {
        if (onboardingComplete) {
          Logger.info(_className, 'Onboarding complete, navigating to sign-in screen');
          if (mounted) {
            context.go('/auth/sign-in');
          }
        } else {
          // Check which step of onboarding to show
          final getStartedCompleted = await OnboardingHelper.isGetStartedCompleted();
          
          if (!getStartedCompleted) {
            Logger.info(_className, 'Get Started not completed, showing Home screen');
            if (mounted) {
              context.go('/home');
            }
          } else {
            Logger.info(_className, 'Get Started completed but privacy policy not accepted, showing privacy policy screen');
            if (mounted) {
              context.go('/privacy-policy');
            }
          }
        }
      }
    } catch (e) {
      Logger.error(_className, 'Error checking onboarding status: $e');
      
      // Fallback to privacy policy screen on error
      if (mounted) {
        Logger.info(_className, 'Falling back to privacy policy screen due to error');
        context.go('/privacy-policy');
      }
    }
  }

  /// Show error screen
  void _showErrorScreen() {
    Logger.warning(_className, 'Showing error screen due to initialization failure');
    
    if (mounted) {
      // For now, fallback to privacy policy screen on error
      // In a real app, you might want to create an error route
      context.go('/privacy-policy');
    }
  }



  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      onAnimationComplete: _onSplashAnimationComplete,
      splashDuration: widget.splashDuration,
    );
  }
}