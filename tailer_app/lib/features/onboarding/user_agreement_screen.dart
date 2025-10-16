import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/onboarding_helper.dart';
import '../../core/constants/app_colors.dart';
import 'package:tailer_app/routes/app_routes.dart';

/// UserAgreementScreen - User Agreement and Terms acceptance screen
/// 
/// This screen shows the user agreement and terms of service.
/// User must accept to continue using the app.
class UserAgreementScreen extends StatefulWidget {
  const UserAgreementScreen({super.key});

  @override
  State<UserAgreementScreen> createState() => _UserAgreementScreenState();
}

class _UserAgreementScreenState extends State<UserAgreementScreen> {
  static const String _className = 'UserAgreementScreen';
  
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _isAccepted = false;

  @override
  void initState() {
    super.initState();
    Logger.startTrace(_className, 'initState');
    _scrollController.addListener(_scrollListener);
    Logger.endTrace(_className, 'initState');
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      // User has scrolled to within 50 pixels of the bottom
      if (maxScroll - currentScroll <= 50 && !_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
        Logger.debug(_className, 'User scrolled to bottom of agreement');
      }
    }
  }

  Future<void> _handleAccept() async {
    try {
      Logger.info(_className, 'User accepted the agreement');
      
      // Mark agreement as accepted
      await OnboardingHelper.setUserAgreementAccepted();
      Logger.debug(_className, 'User agreement acceptance saved');
      
      if (mounted) {
        Logger.info(_className, 'Navigating to sign-in screen');
        context.goNamed(RouteNames.signIn);
      }
    } catch (e, stackTrace) {
      Logger.error(_className, 'Failed to save agreement acceptance', 
                  error: e, stackTrace: stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleReject() {
    Logger.info(_className, 'User rejected the agreement');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Terms Required'),
        content: const Text(
          'You must accept the User Agreement and Terms of Service to use this app. '
          'The app will now close.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Logger.info(_className, 'Closing app due to agreement rejection');
              SystemNavigator.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Logger.debug(_className, 'Building user agreement screen');
    
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation
        _handleReject();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'User Agreement',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.primary,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            // Agreement content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'User Agreement & Terms of Service',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last Updated: October 12, 2025',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Introduction
                    _buildSection(
                      'Welcome to ${AppConfig.appName}',
                      'By using this application, you agree to be bound by these Terms of Service. '
                      'Please read them carefully before proceeding.',
                    ),
                    
                    // Acceptance of Terms
                    _buildSection(
                      '1. Acceptance of Terms',
                      'By accessing and using ${AppConfig.appName}, you accept and agree to be bound by the terms '
                      'and provision of this agreement. If you do not agree to these terms, you must not use this app.',
                    ),
                    
                    // Use License
                    _buildSection(
                      '2. Use License',
                      'Permission is granted to temporarily use ${AppConfig.appName} for personal, '
                      'non-commercial tailoring business management purposes. This is the grant of a license, '
                      'not a transfer of title.',
                    ),
                    
                    // User Data
                    _buildSection(
                      '3. User Data and Privacy',
                      'Your data is stored locally on your device. We respect your privacy and do not collect, '
                      'transmit, or share your personal information without your explicit consent. '
                      'You are responsible for maintaining the confidentiality of your data and account.',
                    ),
                    
                    // Prohibited Uses
                    _buildSection(
                      '4. Prohibited Uses',
                      'You may not use this app:\n'
                      '• For any unlawful purpose\n'
                      '• To violate any regulations in your jurisdiction\n'
                      '• To transmit any harmful code\n'
                      '• To interfere with the security of the app',
                    ),
                    
                    // Disclaimer
                    _buildSection(
                      '5. Disclaimer',
                      'The materials in ${AppConfig.appName} are provided on an "as is" basis. '
                      'We make no warranties, expressed or implied, and hereby disclaim and negate all other warranties '
                      'including, without limitation, implied warranties or conditions of merchantability, '
                      'fitness for a particular purpose, or non-infringement of intellectual property.',
                    ),
                    
                    // Limitations
                    _buildSection(
                      '6. Limitations',
                      'In no event shall ${AppConfig.appName} or its suppliers be liable for any damages '
                      '(including, without limitation, damages for loss of data or profit, or due to business interruption) '
                      'arising out of the use or inability to use the app.',
                    ),
                    
                    // Changes to Terms
                    _buildSection(
                      '7. Modifications to Terms',
                      'We reserve the right to revise these terms of service at any time without notice. '
                      'By using this app you are agreeing to be bound by the then current version of these terms.',
                    ),
                    
                    // Contact Information
                    _buildSection(
                      '8. Contact Information',
                      'If you have any questions about these Terms, please contact us through the app settings.',
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Scroll instruction
                    if (!_hasScrolledToBottom)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Please scroll down to read the complete agreement',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Accept/Reject buttons
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkbox
                  CheckboxListTile(
                    value: _isAccepted,
                    onChanged: _hasScrolledToBottom
                        ? (value) {
                            setState(() {
                              _isAccepted = value ?? false;
                            });
                          }
                        : null,
                    title: const Text(
                      'I have read and agree to the User Agreement and Terms of Service',
                      style: TextStyle(fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Buttons
                  Row(
                    children: [
                      // Reject button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleReject,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.red.shade400, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Accept button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isAccepted && _hasScrolledToBottom
                              ? _handleAccept
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: _isAccepted && _hasScrolledToBottom ? 4 : 0,
                          ),
                          child: Text(
                            'Accept & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isAccepted && _hasScrolledToBottom
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
