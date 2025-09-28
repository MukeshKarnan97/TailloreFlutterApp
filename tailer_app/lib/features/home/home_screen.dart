import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/onboarding_helper.dart';



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

  @override
  void initState() {
    super.initState();
    Logger.startTrace(_className, 'initState');
    
    _initializeAnimations();
    
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

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Logger.debug(_className, 'Building home screen');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appName),
        elevation: 0,
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
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
                Colors.indigo.shade600,
                Colors.indigo.shade400,
                Colors.blue.shade300,
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
                  _buildWelcomeSection(),
                  
                  const SizedBox(height: 40),
                  
                  // Feature cards
                  _buildFeatureCards(),
                  
                  const SizedBox(height: 40),
                  
                  // Action buttons
                  _buildActionButtons(),
                  
                  const SizedBox(height: 20),
                  
                  // App info
                  _buildAppInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
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
        
        const Text(
          'Welcome to Tailor App!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        Text(
          'Your digital assistant for perfect tailoring',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureCards() {
    final features = [
      {
        'icon': Icons.people,
        'title': 'Manage Customers',
        'description': 'Keep track of all your customers',
      },
      {
        'icon': Icons.straighten,
        'title': 'Store Measurements',
        'description': 'Record precise measurements',
      },
      {
        'icon': Icons.assignment,
        'title': 'Track Orders',
        'description': 'Monitor order progress',
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

  Widget _buildActionButtons() {
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
            child: const Text(
              'Get Started',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfo() {
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
            'App Version: ${AppConfig.appVersion}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Environment: ${AppConfig.environment}',
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
                child: const Text(
                  'Debug Mode - Tap for info',
                  style: TextStyle(
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
                child: const Text(
                  'Reset Onboarding Flow',
                  style: TextStyle(
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
      
      // Navigate to Privacy Policy screen
      if (mounted) {
        context.go('/privacy-policy');
      }
    } catch (e) {
      Logger.error(_className, 'Failed to navigate to privacy policy: $e');
      
      // Fallback - show a message if navigation fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDebugInfo() {
    Logger.info(_className, 'Showing debug information');
    
    final config = AppConfig.getAllConfig(includeSensitive: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuration:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...config.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openDebugResetScreen() {
    Logger.info(_className, 'Opening debug reset screen');
    
    // For now, we'll navigate to privacy policy as we don't have a debug route
    // In a real app, you would add a debug route to AppRoutes
    context.go('/privacy-policy');
  }
}