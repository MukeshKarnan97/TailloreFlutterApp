import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:tailer_app/widgets/custom_header.dart';

class PrivacyPolicyViewerScreen extends StatefulWidget {
  const PrivacyPolicyViewerScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyViewerScreen> createState() => _PrivacyPolicyViewerScreenState();
}

class _PrivacyPolicyViewerScreenState extends State<PrivacyPolicyViewerScreen> with NavigationMixin {
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
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomHeaderWithProfile(
            title: locale.translate('privacyPolicy'),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isSmallScreen),
                    SizedBox(height: isSmallScreen ? 20 : 24),
                    _buildContent(isSmallScreen),
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
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.privacy_tip_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 28 : 32,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Text(
                  'Privacy Policy',
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'Last updated: October 13, 2025',
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 12 : 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            'Please read this privacy policy carefully to understand how we collect, use, and protect your personal information.',
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 12 : 13,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          '1. Information We Collect',
          [
            'Personal Information: Name, email address, phone number, and business details.',
            'Customer Data: Information about your customers including names, measurements, and order details.',
            'Usage Data: Information about how you use the application.',
            'Device Information: Device type, operating system, and app version.',
          ],
          isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        _buildSection(
          '2. How We Use Your Information',
          [
            'To provide and maintain our service',
            'To manage your customer database',
            'To process orders and payments',
            'To send you notifications about orders and updates',
            'To improve our application and user experience',
            'To provide customer support',
            'To comply with legal obligations',
          ],
          isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        _buildSection(
          '3. Data Storage and Security',
          [
            'Local Storage: Your data is primarily stored locally on your device.',
            'Cloud Backup: Optional cloud backup for data protection (if enabled).',
            'Encryption: All sensitive data is encrypted.',
            'Access Control: Only you have access to your business data.',
            'Regular Backups: We recommend regular backups to prevent data loss.',
          ],
          isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        _buildSection(
          '4. Data Sharing',
          [
            'We do not sell your personal information to third parties.',
            'We do not share customer data with unauthorized parties.',
            'Data may be shared with service providers who assist us in operating the app.',
            'We may disclose information if required by law.',
          ],
          isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        _buildSection(
          '5. Your Rights',
          [
            'Access: You can access all your data within the application.',
            'Correction: You can update or correct your information anytime.',
            'Deletion: You can delete your data by uninstalling the app.',
            'Export: You can export your data in various formats.',
            'Opt-out: You can opt-out of non-essential notifications.',
          ],
          isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        _buildSection(
          '6. Children\'s Privacy',
          [
            'This application is not intended for use by children under 13.',
            'We do not knowingly collect information from children.',
            'If you are a parent and believe your child has provided us with information, please contact us.',
          ],
          isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        _buildSection(
          '7. Cookies and Tracking',
          [
            'We use minimal tracking for app functionality.',
            'Analytics are used to improve user experience.',
            'You can disable analytics in the app settings.',
            'No third-party advertising cookies are used.',
          ],
          isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        _buildSection(
          '8. Third-Party Services',
          [
            'We may use third-party services for payment processing.',
            'These services have their own privacy policies.',
            'We ensure all third-party services comply with privacy standards.',
          ],
          isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        _buildSection(
          '9. Changes to Privacy Policy',
          [
            'We may update this privacy policy from time to time.',
            'You will be notified of any significant changes.',
            'Continued use of the app constitutes acceptance of changes.',
            'Always check the "Last updated" date at the top.',
          ],
          isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        _buildContactSection(isSmallScreen),
      ],
    );
  }

  Widget _buildSection(String title, List<String> points, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 4 : 5,
                height: isSmallScreen ? 20 : 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 15 : 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          ...points.map((point) => Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: isSmallScreen ? 5 : 6,
                  height: isSmallScreen ? 5 : 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 12),
                Expanded(
                  child: Text(
                    point,
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.1),
            AppColors.info.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_support_rounded,
                color: AppColors.info,
                size: isSmallScreen ? 24 : 28,
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Text(
                'Contact Us',
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'If you have any questions about this Privacy Policy, please contact us:',
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 12 : 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          _buildContactItem(Icons.email_rounded, 'privacy@tailorapp.com', isSmallScreen),
          SizedBox(height: isSmallScreen ? 6 : 8),
          _buildContactItem(Icons.phone_rounded, '+1 (555) 123-4567', isSmallScreen),
          SizedBox(height: isSmallScreen ? 6 : 8),
          _buildContactItem(Icons.language_rounded, 'www.tailorapp.com/privacy', isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, bool isSmallScreen) {
    return Row(
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 16 : 18,
          color: AppColors.info,
        ),
        SizedBox(width: isSmallScreen ? 8 : 10),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 12 : 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
