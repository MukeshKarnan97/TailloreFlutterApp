import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/widgets/custom_bottom_navigation.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/services/navigation_service.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> with NavigationMixin {
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  final TextEditingController _searchController = TextEditingController();
  
  int _currentNavIndex = 3; // Settings is index 3
  String _searchQuery = '';

  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'How do I place an order?',
      answer: 'To place an order, navigate to the "New Order" section from the main menu. Fill in the customer details, select the service type, add measurements, and confirm your order.',
    ),
    FAQItem(
      question: 'How can I track my orders?',
      answer: 'You can track all your orders from the "Orders" section in the main menu. Each order shows its current status and expected completion date.',
    ),
    FAQItem(
      question: 'How do I add customer measurements?',
      answer: 'When creating an order, you can add measurements in the measurement section. You can save commonly used measurements as templates for future use.',
    ),
    FAQItem(
      question: 'Can I edit an order after placing it?',
      answer: 'Orders can be edited only before they are marked as "In Progress". Once work has started, contact customer service for any changes.',
    ),
    FAQItem(
      question: 'How do I manage customer information?',
      answer: 'Customer information can be managed from the "Customers" section. You can add, edit, and view customer details and order history.',
    ),
    FAQItem(
      question: 'What payment methods are accepted?',
      answer: 'We accept cash, card payments, and digital payments. Payment details can be recorded when completing an order.',
    ),
    FAQItem(
      question: 'How do I generate invoices?',
      answer: 'Invoices are automatically generated when an order is completed. You can view and print invoices from the order details page.',
    ),
    FAQItem(
      question: 'Can I backup my data?',
      answer: 'Yes, you can backup your data from the Settings > Data Management section. Regular backups are recommended.',
    ),
    FAQItem(
      question: 'How do I change my password?',
      answer: 'Go to Settings > Change Password to update your password. Enter your current password and new password to make changes.',
    ),
    FAQItem(
      question: 'What should I do if I forgot my password?',
      answer: 'Use the "Forgot Password" option on the login screen to reset your password. You will receive reset instructions via email.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FAQItem> get _filteredFAQs {
    if (_searchQuery.isEmpty) return _faqItems;
    return _faqItems.where((faq) =>
      faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      faq.answer.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
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
          appBar: DashboardHeader(
            title: locale.translate('helpCenter'),
            backgroundColor: AppColors.primary,
            notificationCount: 3,
            onBackPressed: () {
              context.pop();
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
              child: Column(
                children: [
                  _buildSearchSection(isSmallScreen),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      child: Column(
                        children: [
                          _buildQuickActions(isSmallScreen),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          _buildFAQSection(isSmallScreen),
                          const SizedBox(height: 100), // Space for bottom nav
                        ],
                      ),
                    ),
                  ),
                ],
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

  Widget _buildSearchSection(bool isSmallScreen) {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : 16,
        0,
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 20 : 24,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: locale.translate('searchHelp'),
            hintStyle: GoogleFonts.inter(
              fontSize: isSmallScreen ? 13 : 14,
              color: AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: isSmallScreen ? 20 : 24,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.textSecondary,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 10 : 12,
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 13 : 15,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isSmallScreen) {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Text(
                locale.translate('quickActions'),
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 15 : 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.phone_outlined,
                  title: locale.translate('callSupport'),
                  subtitle: locale.translate('speakWithAgent'),
                  onTap: () => _callSupport(),
                  isSmallScreen: isSmallScreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.email_outlined,
                  title: locale.translate('emailSupport'),
                  subtitle: locale.translate('sendMessage'),
                  onTap: () => _emailSupport(),
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.chat_outlined,
                  title: locale.translate('liveChat'),
                  subtitle: locale.translate('chatNow'),
                  onTap: () => _startLiveChat(),
                  isSmallScreen: isSmallScreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.videocam_outlined,
                  title: locale.translate('videoCall'),
                  subtitle: locale.translate('scheduleCall'),
                  onTap: () => _scheduleVideoCall(),
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: isSmallScreen ? 40 : 48,
              height: isSmallScreen ? 40 : 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
              ),
              child: Icon(
                icon,
                color: AppColors.accent,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 9 : 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(bool isSmallScreen) {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    final filteredFAQs = _filteredFAQs;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(
          color: AppColors.info.withOpacity(0.15),
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
          // FAQ Header
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withOpacity(0.08),
                  AppColors.info.withOpacity(0.03),
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
                    color: AppColors.info,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.info.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.quiz_rounded,
                    color: Colors.white,
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 12),
                Expanded(
                  child: Text(
                    locale.translate('frequentlyAskedQuestions'),
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 15 : 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // FAQ List
          if (filteredFAQs.isEmpty)
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 32 : 40),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: isSmallScreen ? 40 : 48,
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Text(
                    locale.translate('noResultsFound'),
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...filteredFAQs.asMap().entries.map((entry) {
              final index = entry.key;
              final faq = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
                      height: 1,
                      color: AppColors.border.withOpacity(0.5),
                    ),
                  _buildFAQItem(faq, isSmallScreen),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq, bool isSmallScreen) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: GoogleFonts.inter(
          fontSize: isSmallScreen ? 13 : 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      iconColor: AppColors.info,
      collapsedIconColor: AppColors.textSecondary,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 12 : 16,
            0,
            isSmallScreen ? 12 : 16,
            isSmallScreen ? 12 : 16,
          ),
          child: Text(
            faq.answer,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 12 : 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  void _callSupport() async {
    _showSnackBar('Phone support: +1234567890');
  }

  void _emailSupport() async {
    _showSnackBar('Email support: support@tailerapp.com');
  }

  void _startLiveChat() {
    _showSnackBar('Live chat feature coming soon');
  }

  void _scheduleVideoCall() {
    _showSnackBar('Video call scheduling coming soon');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(AppConstants.primaryTeal),
      ),
    );
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
        NavigationRoutes.orders,
        NavigationRoutes.settings,
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

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}