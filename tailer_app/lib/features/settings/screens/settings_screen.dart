import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/widgets/custom_bottom_navigation.dart';
import 'package:tailer_app/core/services/navigation_service.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/core/utils/logger.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with NavigationMixin {
  int _currentNavIndex = 3; // Settings is index 3
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: DashboardHeader(
            title: locale.translate('settings'),
            backgroundColor: const Color(AppConstants.primaryTeal),
            notificationCount: 3,
            onBackPressed: () {
              context.goNamed(RouteNames.dashboard);
            },
            onNotificationTap: () {
              showNavigationMessage(context, locale.translate('notifications'));
            },
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildUserAccountSection(),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildPaymentManagementSection(),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildAppPreferencesSection(),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildSupportSection(),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildAboutSection(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: AnimatedBottomNavigation(
            currentIndex: _currentNavIndex,
            onTap: _onNavTap,
            items: TailorAppBottomNavItems.defaultItems,
            selectedItemColor: const Color(AppConstants.primaryTeal),
            backgroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection() {
    final currentUser = _authService.currentUser;
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppConstants.primaryTeal).withOpacity(0.1),
            const Color(AppConstants.primaryTeal).withOpacity(0.05),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(AppConstants.primaryTeal).withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(AppConstants.primaryTeal),
                  const Color(AppConstants.primaryTeal).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(AppConstants.primaryTeal).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.username ?? 'User',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?.email ?? 'user@example.com',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    locale.translate('active'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAccountSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    return _buildSection(
      title: locale.translate('account'),
      icon: Icons.person_outline_rounded,
      children: [
        _buildSettingsItem(
          icon: Icons.edit_rounded,
          title: locale.translate('editProfile'),
          subtitle: locale.translate('updatePersonalInformation'),
          onTap: () {
            showNavigationMessage(context, locale.translate('editProfile'), 
                customMessage: locale.translate('profileEditingComingSoon'));
          },
        ),
        _buildSettingsItem(
          icon: Icons.lock_outline_rounded,
          title: locale.translate('changePassword'),
          subtitle: locale.translate('updateAccountPassword'),
          onTap: () {
            showNavigationMessage(context, locale.translate('changePassword'), 
                customMessage: locale.translate('passwordChangeComingSoon'));
          },
        ),
        _buildSettingsItem(
          icon: Icons.security_rounded,
          title: locale.translate('privacyAndSecurity'),
          subtitle: locale.translate('managePrivacySettings'),
          onTap: () {
            showNavigationMessage(context, locale.translate('privacyAndSecurity'), 
                customMessage: locale.translate('privacySettingsComingSoon'));
          },
        ),
        _buildDivider(),
        _buildSettingsItem(
          icon: Icons.logout_rounded,
          title: locale.translate('logout'),
          subtitle: locale.translate('signOutOfAccount'),
          iconColor: Colors.red,
          titleColor: Colors.red,
          showTrailing: false,
          onTap: _showLogoutDialog,
        ),
      ],
    );
  }

  Widget _buildPaymentManagementSection() {
    return _buildSection(
      title: 'Payment Management',
      icon: Icons.payment_rounded,
      children: [
        _buildSettingsItem(
          icon: Icons.analytics_outlined,
          title: 'Payment Reports',
          subtitle: 'View payment analytics and reports',
          onTap: () {
            context.goNamed(RouteNames.paymentReports);
          },
        ),
        _buildSettingsItem(
          icon: Icons.money_off_outlined,
          title: 'Refund Management',
          subtitle: 'Manage refunds and cancellations',
          onTap: () {
            context.goNamed(RouteNames.refundManagement);
          },
        ),
        _buildSettingsItem(
          icon: Icons.receipt_long_outlined,
          title: 'Receipt Management',
          subtitle: 'Generate and manage receipts',
          onTap: () {
            context.goNamed(RouteNames.receiptManagement);
          },
        ),
      ],
    );
  }

  Widget _buildAppPreferencesSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    return _buildSection(
      title: locale.translate('appPreferences'),
      icon: Icons.tune_rounded,
      children: [
        _buildSettingsItem(
          icon: Icons.dark_mode_rounded,
          title: locale.translate('theme'),
          subtitle: locale.translate('lightDarkSystemDefault'),
          trailing: Text(
            locale.translate('system'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          onTap: () {
            showNavigationMessage(context, locale.translate('theme'), 
                customMessage: locale.translate('themeSelectionComingSoon'));
          },
        ),
        _buildSettingsItem(
          icon: Icons.language_rounded,
          title: locale.translate('language'),
          subtitle: locale.translate('choosePreferredLanguage'),
          trailing: Text(
            _getCurrentLanguageName(),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          onTap: () {
            _showLanguageSelection(context);
          },
        ),
        _buildSettingsItem(
          icon: Icons.notifications_outlined,
          title: locale.translate('notifications'),
          subtitle: locale.translate('manageNotificationPreferences'),
          onTap: () {
            showNavigationMessage(context, locale.translate('notifications'), 
                customMessage: locale.translate('notificationSettingsComingSoon'));
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    return _buildSection(
      title: locale.translate('support'),
      icon: Icons.help_outline_rounded,
      children: [
        _buildSettingsItem(
          icon: Icons.help_center_rounded,
          title: locale.translate('helpCenter'),
          subtitle: locale.translate('faqsAndUserGuides'),
          onTap: () {
            showNavigationMessage(context, locale.translate('helpCenter'), 
                customMessage: locale.translate('helpCenterComingSoon'));
          },
        ),
        _buildSettingsItem(
          icon: Icons.feedback_rounded,
          title: locale.translate('sendFeedback'),
          subtitle: locale.translate('shareThoughtsWithUs'),
          onTap: () {
            showNavigationMessage(context, locale.translate('sendFeedback'), 
                customMessage: locale.translate('feedbackFeatureComingSoon'));
          },
        ),
        _buildSettingsItem(
          icon: Icons.bug_report_rounded,
          title: locale.translate('reportABug'),
          subtitle: locale.translate('letUsKnowAboutIssues'),
          onTap: () {
            showNavigationMessage(context, locale.translate('reportABug'), 
                customMessage: locale.translate('bugReportingComingSoon'));
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    return _buildSection(
      title: locale.translate('about'),
      icon: Icons.info_outline_rounded,
      children: [
        _buildSettingsItem(
          icon: Icons.privacy_tip_rounded,
          title: locale.translate('privacyPolicy'),
          subtitle: locale.translate('readOurPrivacyPolicy'),
          onTap: () {
            context.goNamed(RouteNames.privacyPolicy);
          },
        ),
        _buildSettingsItem(
          icon: Icons.description_rounded,
          title: locale.translate('termsOfService'),
          subtitle: locale.translate('readOurTermsOfService'),
          onTap: () {
            showNavigationMessage(context, locale.translate('termsOfService'), 
                customMessage: locale.translate('termsOfServiceComingSoon'));
          },
        ),
        _buildSettingsItem(
          icon: Icons.info_rounded,
          title: locale.translate('appVersion'),
          subtitle: locale.translate('currentVersionInformation'),
          trailing: Text(
            'v1.0.0',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          showTrailing: false,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(AppConstants.primaryTeal),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Section content
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    Widget? trailing,
    bool showTrailing = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? const Color(AppConstants.primaryTeal)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? const Color(AppConstants.primaryTeal),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (showTrailing)
                trailing ?? 
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Colors.grey[200],
    );
  }

  void _showLogoutDialog() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                locale.translate('logout'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Text(
            locale.translate('logoutConfirmation'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                locale.translate('cancel'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoggingOut
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      locale.translate('logout'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    final locale = AppLocalizations.of(_localeProvider.languageCode);

    try {
      setState(() => _isLoggingOut = true);

      // Close dialog first
      Navigator.of(context).pop();

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(AppConstants.primaryTeal),
          ),
        ),
      );

      // Perform logout
      await _authService.signOut(clearRememberMe: false);

      Logger.info('SettingsScreen', 'User logged out successfully');

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to sign in screen
      if (mounted) {
        context.goNamed(RouteNames.signIn);
        
        // Show success message
        showNavigationMessage(
          context,
          locale.translate('loggedOut'),
          customMessage: locale.translate('loggedOutSuccessfully'),
          backgroundColor: Colors.green,
        );
      }
    } catch (e, stackTrace) {
      Logger.error('SettingsScreen', 'Logout failed', 
                  error: e, stackTrace: stackTrace);
      
      setState(() => _isLoggingOut = false);
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        showNavigationMessage(
          context,
          locale.translate('logoutFailed'),
          customMessage: locale.translate('logoutFailedMessage'),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _onNavTap(int index) {
    handleBottomNavigation(
      context,
      index,
      _currentNavIndex,
      (newIndex) => setState(() => _currentNavIndex = newIndex),
      customRoutes: [
        NavigationRoutes.dashboard,
        NavigationRoutes.customers,
        NavigationRoutes.orders, // Use proper route instead of null
        NavigationRoutes.settings, // Current settings page
      ],
      customDestinations: [
        NavigationDestinations.dashboard,
        NavigationDestinations.customers,
        NavigationDestinations.orders,
        NavigationDestinations.settings,
      ],
    );
  }

  String _getCurrentLanguageName() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    switch (_localeProvider.languageCode) {
      case 'ta':
        return locale.translate('tamil');
      case 'hi':
        return locale.translate('hindi');
      case 'en':
      default:
        return locale.translate('english');
    }
  }

  void _showLanguageSelection(BuildContext context) {
    // Navigate to the existing language selection screen
    context.pushNamed(RouteNames.languageSelection);
  }
}