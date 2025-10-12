import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:tailer_app/core/theme/text_styles.dart';
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
          backgroundColor: AppColors.background,
          appBar: DashboardHeader(
            title: locale.translate('settings'),
            backgroundColor: AppColors.primary,
            notificationCount: 3,
            onBackPressed: () {
              context.goNamed(RouteNames.dashboard);
            },
            onNotificationTap: () {
              showNavigationMessage(context, locale.translate('notifications'));
            },
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.03),
                  AppColors.background,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildUserAccountSection(),
                    const SizedBox(height: 20),
                    _buildPaymentManagementSection(),
                    const SizedBox(height: 20),
                    _buildSupportSection(),
                    const SizedBox(height: 20),
                    _buildAboutSection(),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: AnimatedBottomNavigation(
            currentIndex: _currentNavIndex,
            onTap: _onNavTap,
            items: TailorAppBottomNavItems.defaultItems,
            selectedItemColor: AppColors.primary,
            backgroundColor: AppColors.background,
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
            AppColors.primaryLight.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.panel.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
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
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
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
                  currentUser?.name ?? 'User',
                  style: AppTextStyles.heading4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?.email ?? 'user@example.com',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    locale.translate('active'),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
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
      color: AppColors.primary,
      children: [
        _buildSettingsItem(
          icon: Icons.edit_rounded,
          title: locale.translate('editProfile'),
          subtitle: locale.translate('updatePersonalInformation'),
          iconBgColor: AppColors.primary.withOpacity(0.1),
          iconColor: AppColors.primary,
          onTap: () {
            context.pushNamed(RouteNames.editProfile);
          },
        ),
        _buildSettingsItem(
          icon: Icons.lock_outline_rounded,
          title: locale.translate('changePassword'),
          subtitle: locale.translate('updateAccountPassword'),
          iconBgColor: AppColors.secondary.withOpacity(0.1),
          iconColor: AppColors.secondary,
          onTap: () {
            context.pushNamed(RouteNames.changePassword);
          },
        ),
        const SizedBox(height: 12),
        _buildDivider(),
        const SizedBox(height: 12),
        _buildSettingsItem(
          icon: Icons.logout_rounded,
          title: locale.translate('logout'),
          subtitle: locale.translate('signOutOfAccount'),
          iconBgColor: Colors.red.withOpacity(0.1),
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
      color: AppColors.secondary,
      children: [
        _buildSettingsItem(
          icon: Icons.analytics_outlined,
          title: 'Payment Reports',
          subtitle: 'View payment analytics and reports',
          iconBgColor: AppColors.secondary.withOpacity(0.1),
          iconColor: AppColors.secondary,
          onTap: () {
            context.goNamed(RouteNames.paymentReports);
          },
        ),
        _buildSettingsItem(
          icon: Icons.money_off_outlined,
          title: 'Refund Management',
          subtitle: 'Manage refunds and cancellations',
          iconBgColor: AppColors.warning.withOpacity(0.1),
          iconColor: AppColors.warning,
          onTap: () {
            context.goNamed(RouteNames.refundManagement);
          },
        ),
        _buildSettingsItem(
          icon: Icons.receipt_long_outlined,
          title: 'Receipt Management',
          subtitle: 'Generate and manage receipts',
          iconBgColor: AppColors.accent.withOpacity(0.1),
          iconColor: AppColors.accent,
          onTap: () {
            context.goNamed(RouteNames.receiptManagement);
          },
        ),
      ],
    );
  }

  // Widget _buildAppPreferencesSection() {
  //   final locale = AppLocalizations.of(_localeProvider.languageCode);
  //   return _buildSection(
  //     title: locale.translate('appPreferences'),
  //     icon: Icons.tune_rounded,
  //     children: [
  //       _buildSettingsItem(
  //         icon: Icons.dark_mode_rounded,
  //         title: locale.translate('theme'),
  //         subtitle: locale.translate('lightDarkSystemDefault'),
  //         trailing: Text(
  //           locale.translate('system'),
  //           style: AppTextStyles.bodyMedium.copyWith(
  //             color: AppColors.textSecondary,
  //           ),
  //         ),
  //         onTap: () {
  //           context.pushNamed(RouteNames.themeSelection);
  //         },
  //       ),
  //       _buildSettingsItem(
  //         icon: Icons.language_rounded,
  //         title: locale.translate('language'),
  //         subtitle: locale.translate('choosePreferredLanguage'),
  //         trailing: Text(
  //           _getCurrentLanguageName(),
  //           style: AppTextStyles.bodyMedium.copyWith(
  //             color: AppColors.textSecondary,
  //           ),
  //         ),
  //         onTap: () {
  //           _showLanguageSelection(context);
  //         },
  //       ),
  //       _buildSettingsItem(
  //         icon: Icons.notifications_outlined,
  //         title: locale.translate('notifications'),
  //         subtitle: locale.translate('manageNotificationPreferences'),
  //         onTap: () {
  //           context.pushNamed(RouteNames.notificationSettings);
  //         },
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSupportSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    return _buildSection(
      title: locale.translate('support'),
      icon: Icons.help_outline_rounded,
      color: AppColors.accent,
      children: [
        _buildSettingsItem(
          icon: Icons.help_center_rounded,
          title: locale.translate('helpCenter'),
          subtitle: locale.translate('faqsAndUserGuides'),
          iconBgColor: AppColors.accent.withOpacity(0.1),
          iconColor: AppColors.accent,
          onTap: () {
            context.pushNamed(RouteNames.helpCenter);
          },
        ),
        _buildSettingsItem(
          icon: Icons.feedback_rounded,
          title: locale.translate('sendFeedback'),
          subtitle: locale.translate('shareThoughtsWithUs'),
          iconBgColor: AppColors.info.withOpacity(0.1),
          iconColor: AppColors.info,
          onTap: () {
            context.pushNamed(RouteNames.feedback);
          },
        ),
        _buildSettingsItem(
          icon: Icons.bug_report_rounded,
          title: locale.translate('reportABug'),
          subtitle: locale.translate('letUsKnowAboutIssues'),
          iconBgColor: AppColors.error.withOpacity(0.1),
          iconColor: AppColors.error,
          onTap: () {
            context.pushNamed(RouteNames.bugReport);
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
      color: AppColors.info,
      children: [
        _buildSettingsItem(
          icon: Icons.privacy_tip_rounded,
          title: locale.translate('privacyPolicy'),
          subtitle: locale.translate('readOurPrivacyPolicy'),
          iconBgColor: AppColors.info.withOpacity(0.1),
          iconColor: AppColors.info,
          onTap: () {
            context.goNamed(RouteNames.privacyPolicy);
          },
        ),
        _buildSettingsItem(
          icon: Icons.description_rounded,
          title: locale.translate('termsOfService'),
          subtitle: locale.translate('readOurTermsOfService'),
          iconBgColor: AppColors.secondary.withOpacity(0.1),
          iconColor: AppColors.secondary,
          onTap: () {
            context.pushNamed(RouteNames.termsOfService);
          },
        ),
        _buildSettingsItem(
          icon: Icons.info_rounded,
          title: locale.translate('appVersion'),
          subtitle: locale.translate('currentVersionInformation'),
          iconBgColor: AppColors.primary.withOpacity(0.1),
          iconColor: AppColors.primary,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'v1.0.0',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
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
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (color ?? AppColors.primary).withOpacity(0.15),
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
          // Modern Section header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (color ?? AppColors.primary).withOpacity(0.08),
                  (color ?? AppColors.primary).withOpacity(0.03),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color ?? AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (color ?? AppColors.primary).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.background,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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
    Color? iconBgColor,
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor ?? (iconColor ?? AppColors.primary).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor ?? AppColors.primary,
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
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              if (showTrailing)
                trailing ?? 
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
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
      color: AppColors.border,
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
                style: AppTextStyles.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            locale.translate('logoutConfirmation'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                locale.translate('cancel'),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
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
                      style: AppTextStyles.labelMedium.copyWith(
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

}