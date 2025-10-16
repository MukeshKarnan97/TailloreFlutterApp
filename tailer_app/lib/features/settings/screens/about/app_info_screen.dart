import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:tailer_app/widgets/custom_header.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> with NavigationMixin {
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            title: locale.translate('aboutApp'),
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAppLogo(isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildAppName(isSmallScreen),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildAppVersion(isSmallScreen),
                SizedBox(height: isSmallScreen ? 24 : 32),
                _buildDescriptionCard(locale, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildFeaturesCard(locale, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildDeveloperCard(locale, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildContactCard(locale, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildLegalCard(locale, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildCopyright(isSmallScreen),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppLogo(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
            AppColors.secondary.withOpacity(0.3),
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
      child: Icon(
        Icons.checkroom_rounded,
        size: isSmallScreen ? 64 : 80,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAppName(bool isSmallScreen) {
    return Text(
      'Tailor Management',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: isSmallScreen ? 22 : 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAppVersion(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        'Version 1.0.0',
        style: GoogleFonts.inter(
          fontSize: isSmallScreen ? 12 : 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(AppLocalizations locale, bool isSmallScreen) {
    return _buildCard(
      title: locale.translate('about'),
      icon: Icons.info_outline_rounded,
      color: AppColors.info,
      isSmallScreen: isSmallScreen,
      child: Text(
        'A comprehensive tailor management application designed to streamline your tailoring business. Manage customers, orders, measurements, and payments all in one place.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: isSmallScreen ? 13 : 14,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFeaturesCard(AppLocalizations locale, bool isSmallScreen) {
    final features = [
      {'icon': Icons.people_outline, 'title': 'Customer Management', 'desc': 'Track all customer details'},
      {'icon': Icons.straighten_rounded, 'title': 'Measurements', 'desc': 'Store detailed measurements'},
      {'icon': Icons.shopping_bag_outlined, 'title': 'Order Tracking', 'desc': 'Manage orders efficiently'},
      {'icon': Icons.payment_rounded, 'title': 'Payment System', 'desc': 'Record and track payments'},
      {'icon': Icons.analytics_outlined, 'title': 'Reports', 'desc': 'Generate business insights'},
      {'icon': Icons.language_rounded, 'title': 'Multi-language', 'desc': 'Support multiple languages'},
    ];

    return _buildCard(
      title: 'Key Features',
      icon: Icons.stars_rounded,
      color: AppColors.accent,
      isSmallScreen: isSmallScreen,
      child: Column(
        children: [
          ...features.map((feature) => Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
            child: _buildFeatureItem(
              feature['icon'] as IconData,
              feature['title'] as String,
              feature['desc'] as String,
              isSmallScreen,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, bool isSmallScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: isSmallScreen ? 20 : 24,
            color: AppColors.accent,
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperCard(AppLocalizations locale, bool isSmallScreen) {
    return _buildCard(
      title: 'Developed By',
      icon: Icons.code_rounded,
      color: AppColors.secondary,
      isSmallScreen: isSmallScreen,
      child: Column(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 32 : 40,
            backgroundColor: AppColors.secondary.withOpacity(0.1),
            child: Icon(
              Icons.business_rounded,
              size: isSmallScreen ? 32 : 40,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'Tailor Tech Solutions',
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Professional Business Solutions',
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 12 : 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(AppLocalizations locale, bool isSmallScreen) {
    return _buildCard(
      title: 'Contact Us',
      icon: Icons.contact_support_rounded,
      color: AppColors.primary,
      isSmallScreen: isSmallScreen,
      child: Column(
        children: [
          _buildContactItem(
            Icons.email_rounded,
            'Email',
            'support@tailorapp.com',
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          _buildContactItem(
            Icons.phone_rounded,
            'Phone',
            '+1 (555) 123-4567',
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          _buildContactItem(
            Icons.language_rounded,
            'Website',
            'www.tailorapp.com',
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: isSmallScreen ? 16 : 18,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 12 : 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalCard(AppLocalizations locale, bool isSmallScreen) {
    return _buildCard(
      title: 'Legal',
      icon: Icons.gavel_rounded,
      color: AppColors.warning,
      isSmallScreen: isSmallScreen,
      child: Column(
        children: [
          _buildLegalItem(
            Icons.privacy_tip_rounded,
            locale.translate('privacyPolicy'),
            'Read our privacy policy',
            () => context.pushNamed('privacyPolicyViewer'),
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          _buildLegalItem(
            Icons.description_rounded,
            locale.translate('termsOfService'),
            'Read our terms of service',
            () => context.pushNamed('termsOfService'),
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          _buildLegalItem(
            Icons.security_rounded,
            'Licenses',
            'View open source licenses',
            () => showLicensePage(context: context),
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalItem(IconData icon, String title, String subtitle, VoidCallback onTap, bool isSmallScreen) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: isSmallScreen ? 20 : 22, color: AppColors.warning),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: isSmallScreen ? 14 : 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyright(bool isSmallScreen) {
    return Column(
      children: [
        const Divider(),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Text(
          '© 2025 Tailor Management App',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 11 : 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'All rights reserved',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 10 : 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    required bool isSmallScreen,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.08),
                  color.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmallScreen ? 14 : 16),
                topRight: Radius.circular(isSmallScreen ? 14 : 16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
