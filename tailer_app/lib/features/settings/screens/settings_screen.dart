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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with NavigationMixin {
  int _currentNavIndex = 3; // Settings is index 3
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: DashboardHeader(
        title: 'Settings',
        backgroundColor: const Color(AppConstants.primaryTeal),
        notificationCount: 3,
        onBackPressed: () {
          context.goNamed(RouteNames.dashboard);
        },
        onNotificationTap: () {
          showNavigationMessage(context, 'Notifications');
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
  }

  Widget _buildHeaderSection() {
    final currentUser = _authService.currentUser;
    
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
                    'Active',
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
    return _buildSection(
      title: 'Account',
      icon: Icons.person_outline_rounded,
      children: [
        _buildSettingsItem(
          icon: Icons.edit_rounded,
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          onTap: () {
            showNavigationMessage(context, 'Edit Profile', 
                customMessage: 'Profile editing feature coming soon!');
          },
        ),
        _buildSettingsItem(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: () {
            showNavigationMessage(context, 'Change Password', 
                customMessage: 'Password change feature coming soon!');
          },
        ),
        _buildSettingsItem(
          icon: Icons.security_rounded,
          title: 'Privacy & Security',
          subtitle: 'Manage your privacy settings',
          onTap: () {
            showNavigationMessage(context, 'Privacy & Security', 
                customMessage: 'Privacy settings coming soon!');
          },
        ),
        _buildDivider(),
        _buildSettingsItem(
          icon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          iconColor: Colors.red,
          titleColor: Colors.red,
          showTrailing: false,
          onTap: _showLogoutDialog,
        ),
      ],
    );
  }

  Widget _buildAppPreferencesSection() {
    return _buildSection(
      title: 'App Preferences',
      icon: Icons.tune_rounded,
      children: [
        _buildSettingsItem(
          icon: Icons.dark_mode_rounded,
          title: 'Theme',
          subtitle: 'Light, dark, or system default',
          trailing: Text(
            'System',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          onTap: () {
            showNavigationMessage(context, 'Theme Settings', 
                customMessage: 'Theme selection coming soon!');
          },
        ),
        _buildSettingsItem(
          icon: Icons.language_rounded,
          title: 'Language',
          subtitle: 'Choose your preferred language',
          trailing: Text(
            'English',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          onTap: () {
            showNavigationMessage(context, 'Language Settings', 
                customMessage: 'Language selection coming soon!');
          },
        ),
        _buildSettingsItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
          onTap: () {
            showNavigationMessage(context, 'Notification Settings', 
                customMessage: 'Notification settings coming soon!');
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSection(
      title: 'Support',
      icon: Icons.help_outline_rounded,
      children: [
        _buildSettingsItem(
          icon: Icons.help_center_rounded,
          title: 'Help Center',
          subtitle: 'FAQs and user guides',
          onTap: () {
            showNavigationMessage(context, 'Help Center', 
                customMessage: 'Help center coming soon!');
          },
        ),
        _buildSettingsItem(
          icon: Icons.feedback_rounded,
          title: 'Send Feedback',
          subtitle: 'Share your thoughts with us',
          onTap: () {
            showNavigationMessage(context, 'Send Feedback', 
                customMessage: 'Feedback feature coming soon!');
          },
        ),
        _buildSettingsItem(
          icon: Icons.bug_report_rounded,
          title: 'Report a Bug',
          subtitle: 'Let us know about any issues',
          onTap: () {
            showNavigationMessage(context, 'Report Bug', 
                customMessage: 'Bug reporting coming soon!');
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About',
      icon: Icons.info_outline_rounded,
      children: [
        _buildSettingsItem(
          icon: Icons.privacy_tip_rounded,
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          onTap: () {
            context.goNamed(RouteNames.privacyPolicy);
          },
        ),
        _buildSettingsItem(
          icon: Icons.description_rounded,
          title: 'Terms of Service',
          subtitle: 'Read our terms of service',
          onTap: () {
            showNavigationMessage(context, 'Terms of Service', 
                customMessage: 'Terms of service coming soon!');
          },
        ),
        _buildSettingsItem(
          icon: Icons.info_rounded,
          title: 'App Version',
          subtitle: 'Current version information',
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
                'Logout',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout? You will need to sign in again to access your account.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
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
                      'Logout',
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
          'Logged Out',
          customMessage: 'You have been successfully logged out.',
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
          'Logout Failed',
          customMessage: 'Failed to logout. Please try again.',
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
        null, // Orders - not implemented yet
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