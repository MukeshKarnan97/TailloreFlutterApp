import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/routes/app_routes.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/privacy_policy_helper.dart';

/// PrivacyPolicyScreen - User Agreement and Privacy Policy
/// 
/// This screen shows the user agreement and privacy policy.
/// Once accepted, it won't show again for the same user.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  static const String _className = 'PrivacyPolicyScreen';
  
  bool _isAccepted = false;

  @override
  void initState() {
    super.initState();
    Logger.startTrace(_className, 'initState');
    Logger.endTrace(_className, 'initState');
  }

  /// Accepts the privacy policy and stores the acceptance in shared preferences
  Future<void> _acceptPrivacyPolicy() async {
    try {
      Logger.info(_className, 'User accepted privacy policy');
      
      final success = await PrivacyPolicyHelper.setAccepted();
      
      if (success) {
        Logger.debug(_className, 'Privacy policy acceptance stored successfully');
        
        if (mounted) {
          // Navigate to the sign-in screen using GoRouter
          context.goNamed(RouteNames.signIn);
        }
      } else {
        throw Exception('Failed to store acceptance');
      }
    } catch (e) {
      Logger.error(_className, 'Failed to store privacy policy acceptance: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save acceptance. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Declines the privacy policy and exits the app
  void _declinePrivacyPolicy() {
    Logger.info(_className, 'User declined privacy policy');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy Required'),
        content: const Text(
          'You must accept our Privacy Policy to use this app. The app will now close.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Logger.info(_className, 'Exiting app due to privacy policy decline');
              Navigator.of(context).pop();
              // In a real app, you might want to use SystemNavigator.pop() or similar
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    Logger.debug(_className, 'Building privacy policy screen');
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy & User Agreement'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.panel,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.security,
                            size: 40,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your Privacy Matters',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please read and accept our privacy policy to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.indigo.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Privacy Policy Content
                    _buildPrivacyPolicyContent(),
                    
                    const SizedBox(height: 24),
                    
                    // User Agreement Content
                    _buildUserAgreementContent(),
                    
                    const SizedBox(height: 24),
                    
                    // Acceptance Checkbox
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isAccepted,
                            onChanged: (value) {
                              setState(() {
                                _isAccepted = value ?? false;
                              });
                              Logger.debug(_className, 'Privacy policy acceptance checkbox changed: $_isAccepted');
                            },
                            activeColor: Colors.indigo.shade600,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'I have read and accept the Privacy Policy and User Agreement',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
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
            
            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _declinePrivacyPolicy,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade600, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAccepted ? _acceptPrivacyPolicy : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: _isAccepted ? 5 : 0,
                      ),
                      child: const Text(
                        'Accept & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Skip to Sign In option
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: TextButton(
                onPressed: () {
                  Logger.info(_className, 'User chose to skip to sign-in');
                  context.goNamed(RouteNames.signIn);
                },
                child: Text(
                  'Skip to Sign In',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Privacy Policy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade800,
            ),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Data Collection & Usage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• We collect customer information, measurements, and order details you provide\n'
            '• All data is stored locally on your device for your privacy\n'
            '• No personal data is shared with third parties without consent\n'
            '• You can export or delete your data at any time',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Data Security',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• All data is encrypted and stored securely\n'
            '• We use industry-standard security practices\n'
            '• Regular security updates are provided\n'
            '• Backup and restore features protect your data',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAgreementContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📜 User Agreement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade800,
            ),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Terms of Use',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• This app is provided for professional tailoring use\n'
            '• You agree to use the app responsibly and legally\n'
            '• Features and services may be updated or modified\n'
            '• Support is provided on a best-effort basis',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Liability & Warranty',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• The app is provided "as is" without warranty\n'
            '• We are not liable for data loss or business disruption\n'
            '• Users are responsible for backing up their data\n'
            '• Professional advice should be sought for critical decisions',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}