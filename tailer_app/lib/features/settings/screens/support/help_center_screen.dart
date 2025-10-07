import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> with NavigationMixin {
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  final TextEditingController _searchController = TextEditingController();
  
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
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              locale.translate('helpCenter'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(AppConstants.primaryTeal),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildSearchSection(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      children: [
                        _buildQuickActions(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildFAQSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      color: const Color(AppConstants.primaryTeal),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.inter(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(
                Icons.support_agent_outlined,
                color: const Color(AppConstants.primaryTeal),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                locale.translate('quickActions'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.phone_outlined,
                  title: locale.translate('callSupport'),
                  subtitle: locale.translate('speakWithAgent'),
                  onTap: () => _callSupport(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.email_outlined,
                  title: locale.translate('emailSupport'),
                  subtitle: locale.translate('sendMessage'),
                  onTap: () => _emailSupport(),
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.videocam_outlined,
                  title: locale.translate('videoCall'),
                  subtitle: locale.translate('scheduleCall'),
                  onTap: () => _scheduleVideoCall(),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: const Color(AppConstants.primaryTeal),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    final filteredFAQs = _filteredFAQs;
    
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
          // FAQ Header
          Container(
            padding: const EdgeInsets.all(20),
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
                  Icons.quiz_outlined,
                  color: const Color(AppConstants.primaryTeal),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  locale.translate('frequentlyAskedQuestions'),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // FAQ List
          if (filteredFAQs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    locale.translate('noResultsFound'),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
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
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      height: 1,
                      color: Colors.grey[200],
                    ),
                  _buildFAQItem(faq),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            faq.answer,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
      iconColor: const Color(AppConstants.primaryTeal),
      collapsedIconColor: Colors.grey[600],
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
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}