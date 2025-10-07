import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/routes/app_routes.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/onboarding_helper.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import '../../data/services/notification_service.dart';
import '../notifications/widgets/notification_list_widget.dart';
import '../../core/constants/app_colors.dart';



/// HomeScreen - Main application home screen after splash
/// 
/// This is a temporary home screen that demonstrates the app structure
/// and shows that the splash screen transition is working correctly.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const String _className = 'HomeScreen';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    Logger.startTrace(_className, 'initState');
    
    _initializeAnimations();
    _initializeNotifications();
    
    Logger.endTrace(_className, 'initState');
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start fade in animation
    _fadeController.forward();
  }

  void _initializeNotifications() {
    // Initialize notification service
    _notificationService.initialize().catchError((error) {
      Logger.error(_className, 'Failed to initialize notifications', error: error);
    });
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _notificationService.markAllAsRead();
                  },
                  child: const Text('Mark All Read'),
                ),
              ],
            ),
            const Divider(),
            // Notification list
            const Expanded(
              child: NotificationListWidget(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Logger.debug(_className, 'Building home screen');
    
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Show exit confirmation for home screen
        final shouldExit = await _showExitConfirmation(context);
        if (shouldExit) {
          // Exit the app properly
          SystemNavigator.pop();
        }
      },
      child: AnimatedBuilder(
        animation: _localeProvider,
        builder: (context, child) {
          final locale = AppLocalizations.of(_localeProvider.languageCode);
          
          return Scaffold(
          appBar: AppBar(
            title: Text(AppConfig.appName),
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            centerTitle: true,
            actions: [
              NotificationBadge(
                notificationService: _notificationService,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: _showNotifications,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                    AppColors.secondary,
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Welcome section
                      _buildWelcomeSection(locale),
                      
                      const SizedBox(height: 40),
                      
                      // Feature cards
                      _buildFeatureCards(locale),
                      
                      const SizedBox(height: 40),
                      
                      // Action buttons
                      _buildActionButtons(locale),
                      
                      const SizedBox(height: 20),
                      
                      // App info
                      _buildAppInfo(locale),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ), // End of AnimatedBuilder
    ); // End of PopScope
  }

  /// Show exit confirmation dialog
  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildWelcomeSection(AppLocalizations locale) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.content_cut,
            size: 60,
            color: Colors.indigo,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          locale.translate('welcomeToTailorApp'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        Text(
          locale.translate('digitalAssistantForTailoring'),
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureCards(AppLocalizations locale) {
    final features = [
      {
        'icon': Icons.people,
        'title': locale.translate('manageCustomers'),
        'description': locale.translate('trackAllCustomers'),
      },
      {
        'icon': Icons.straighten,
        'title': locale.translate('storeMeasurements'),
        'description': locale.translate('recordPreciseMeasurements'),
      },
      {
        'icon': Icons.assignment,
        'title': locale.translate('trackOrders'),
        'description': locale.translate('monitorOrderProgress'),
      },
    ];

    return Row(
      children: features.map((feature) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  feature['icon'] as IconData,
                  size: 30,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  feature['title'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  feature['description'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(AppLocalizations locale) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Logger.info(_className, 'Get Started button pressed - navigating to sign-in');
              _navigateToSignIn();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 5,
            ),
            child: Text(
              locale.translate('getStarted'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfo(AppLocalizations locale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '${locale.translate('appVersion')}: ${AppConfig.appVersion}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${locale.translate('environment')}: ${AppConfig.environment}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          if (AppConfig.isDevelopment) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showDebugInfo,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Text(
                  locale.translate('debugModeTapForInfo'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _openDebugResetScreen,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red, width: 1),
                ),
                child: Text(
                  locale.translate('resetOnboardingFlow'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToSignIn() async {
    try {
      Logger.info(_className, 'Get Started button pressed - marking onboarding step completed');
      
      // Mark Get Started as completed
      await OnboardingHelper.setGetStartedCompleted();
      Logger.debug(_className, 'Get Started completion status saved');
      
      if (mounted) {
        Logger.info(_className, 'Navigating to sign-in screen');
        context.goNamed(RouteNames.signIn);
      }
    } catch (e, stackTrace) {
      Logger.error(_className, 'Failed to navigate to sign-in', 
                  error: e, stackTrace: stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDebugInfo() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(locale.translate('debugInformation')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${locale.translate('appName')}: ${AppConfig.appName}'),
                Text('${locale.translate('version')}: ${AppConfig.appVersion}'),
                Text('${locale.translate('environment')}: ${AppConfig.environment}'),
                Text('${locale.translate('debugMode')}: ${AppConfig.isDevelopment}'),
                const SizedBox(height: 10),
                Text(locale.translate('onboardingStatus')),
                FutureBuilder<bool>(
                  future: OnboardingHelper.isGetStartedCompleted(),
                  builder: (context, snapshot) {
                    return Text('${locale.translate('getStartedCompleted')}: ${snapshot.data ?? false}');
                  },
                ),
                Text('${locale.translate('privacyCompleted')}: false'), // Since no privacy method exists
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(locale.translate('close')),
            ),
          ],
        );
      },
    );
  }

  void _openDebugResetScreen() {
    Logger.info(_className, 'Opening debug reset screen');
    context.pushNamed('debugReset');
  }
}