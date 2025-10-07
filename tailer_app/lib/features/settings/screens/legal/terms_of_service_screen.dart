import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import '../../../../widgets/custom_header.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> with NavigationMixin {
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  final ScrollController _scrollController = ScrollController();
  
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    setState(() {
      _showScrollToTop = _scrollController.offset > 500;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomHeader(
            title: locale.translate('termsOfService'),
            showBackButton: true,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildContent(),
                    const SizedBox(height: 100), // Extra space for FAB
                  ],
                ),
              ),
              if (_showScrollToTop)
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                    backgroundColor: const Color(AppConstants.primaryTeal),
                    child: const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo,
                  Colors.indigo.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.article_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            locale.translate('termsOfService'),
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${locale.translate('lastUpdated')}: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: '1. Acceptance of Terms',
            content: '''By downloading, installing, or using the Tailer App ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the App.

These Terms constitute a legally binding agreement between you and Tailer App ("we," "us," or "our"). Your use of the App is also governed by our Privacy Policy, which is incorporated by reference into these Terms.''',
          ),
          _buildSection(
            title: '2. Description of Service',
            content: '''Tailer App is a mobile application designed to help tailoring businesses manage their operations, including:
• Customer management
• Order tracking and management
• Measurement recording and storage
• Invoice generation
• Business analytics and reporting
• Appointment scheduling

The App is intended for use by tailoring professionals and businesses in the textile and clothing industry.''',
          ),
          _buildSection(
            title: '3. User Accounts and Registration',
            content: '''To use certain features of the App, you must create an account. When creating an account, you agree to:
• Provide accurate and complete information
• Maintain the security of your account credentials
• Promptly update any changes to your information
• Accept responsibility for all activities under your account
• Notify us immediately of any unauthorized use

You are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account.''',
          ),
          _buildSection(
            title: '4. Acceptable Use',
            content: '''You agree to use the App only for lawful purposes and in accordance with these Terms. You agree not to:
• Use the App for any illegal or unauthorized purpose
• Violate any applicable laws or regulations
• Infringe upon the rights of others
• Upload or transmit malicious code or viruses
• Attempt to gain unauthorized access to our systems
• Interfere with the App's functionality or security
• Use the App to harm minors in any way
• Impersonate any person or entity''',
          ),
          _buildSection(
            title: '5. Data and Privacy',
            content: '''Your privacy is important to us. Our collection and use of personal information is governed by our Privacy Policy. By using the App, you consent to:
• The collection and use of information as described in our Privacy Policy
• The storage of your data on our secure servers
• The processing of your data for service provision and improvement

You retain ownership of any data you input into the App. We will not share your personal data with third parties except as described in our Privacy Policy or as required by law.''',
          ),
          _buildSection(
            title: '6. Intellectual Property',
            content: '''The App and its original content, features, and functionality are owned by Tailer App and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.

You are granted a limited, non-exclusive, non-transferable license to use the App for your personal or business use in accordance with these Terms.''',
          ),
          _buildSection(
            title: '7. Payment Terms',
            content: '''If you purchase a premium subscription or paid features:
• All fees are charged in advance and are non-refundable
• Subscriptions automatically renew unless cancelled
• Price changes will be communicated with 30 days notice
• Refunds may be provided at our sole discretion
• You are responsible for all applicable taxes''',
          ),
          _buildSection(
            title: '8. Limitation of Liability',
            content: '''To the fullest extent permitted by law, Tailer App shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses.

Our total liability to you for any claim arising out of or relating to these Terms or the App shall not exceed the amount you paid us in the twelve (12) months preceding the claim.''',
          ),
          _buildSection(
            title: '9. Warranty Disclaimer',
            content: '''The App is provided "as is" and "as available" without warranties of any kind, either express or implied. We disclaim all warranties, including but not limited to:
• Merchantability
• Fitness for a particular purpose
• Non-infringement
• Uninterrupted or error-free operation
• Security or accuracy of data

We do not warrant that the App will meet your requirements or be available at all times.''',
          ),
          _buildSection(
            title: '10. Termination',
            content: '''We may terminate or suspend your account and access to the App immediately, without prior notice, for conduct that we believe:
• Violates these Terms
• Is harmful to other users or us
• Is fraudulent or illegal

Upon termination, your right to use the App will cease immediately. All provisions of these Terms which should survive termination shall survive.''',
          ),
          _buildSection(
            title: '11. Changes to Terms',
            content: '''We reserve the right to modify these Terms at any time. We will notify you of any changes by:
• Posting the new Terms in the App
• Sending you an email notification
• Displaying a notice when you next access the App

Your continued use of the App after any modifications constitutes acceptance of the new Terms.''',
          ),
          _buildSection(
            title: '12. Contact Information',
            content: '''If you have any questions about these Terms of Service, please contact us:

Email: legal@tailerapp.com
Phone: +1 (555) 123-4567
Address: 123 Business Street, Suite 100, City, State 12345

For technical support, please use the Help Center in the App or email support@tailerapp.com.''',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
              bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
            ),
          ),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(AppConstants.primaryTeal),
            ),
          ),
        ),
        if (!isLast)
          Container(
            padding: const EdgeInsets.all(20),
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[700],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[700],
              ),
            ),
          ),
        if (!isLast)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 1,
            color: Colors.grey[200],
          ),
      ],
    );
  }
}