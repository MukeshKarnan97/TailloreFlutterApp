import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/widgets/custom_bottom_navigation.dart';
import 'package:tailer_app/core/services/navigation_service.dart';
import 'dart:io' show Platform;

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> with NavigationMixin {
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();
  
  int _currentNavIndex = 3; // Settings is index 3
  String _selectedPriority = 'medium';
  String _selectedCategory = 'ui';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _priorities = [
    {'value': 'low', 'label': 'Low', 'color': AppColors.success},
    {'value': 'medium', 'label': 'Medium', 'color': AppColors.warning},
    {'value': 'high', 'label': 'High', 'color': AppColors.error},
    {'value': 'critical', 'label': 'Critical', 'color': AppColors.info},
  ];

  final List<Map<String, String>> _categories = [
    {'value': 'ui', 'label': 'User Interface'},
    {'value': 'functionality', 'label': 'Functionality'},
    {'value': 'performance', 'label': 'Performance'},
    {'value': 'data', 'label': 'Data Issues'},
    {'value': 'navigation', 'label': 'Navigation'},
    {'value': 'auth', 'label': 'Authentication'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stepsController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: DashboardHeader(
            title: locale.translate('reportBug'),
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBugReportHeader(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      _buildBasicInfoSection(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      _buildBugDetailsSection(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      _buildSystemInfoSection(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      _buildSubmitButton(isSmallScreen),
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
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

  Widget _buildBugReportHeader(bool isSmallScreen) {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(
          color: AppColors.error.withOpacity(0.15),
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
        children: [
          Container(
            width: isSmallScreen ? 64 : 80,
            height: isSmallScreen ? 64 : 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.error,
                  AppColors.error.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 32 : 40),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.bug_report_rounded,
              size: isSmallScreen ? 32 : 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            locale.translate('reportABug'),
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 17 : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            locale.translate('helpUsFixIssues'),
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 12 : 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isSmallScreen) {
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: Text(
                  locale.translate('basicInformation'),
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          TextFormField(
            controller: _titleController,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 13 : 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: locale.translate('bugTitle'),
              labelStyle: GoogleFonts.inter(
                fontSize: isSmallScreen ? 12 : 14,
                color: AppColors.textSecondary,
              ),
              prefixIcon: Icon(
                Icons.title_rounded,
                color: AppColors.primary,
                size: isSmallScreen ? 20 : 22,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.error),
              ),
              filled: true,
              fillColor: AppColors.background,
              hintText: locale.translate('briefDescriptionOfIssue'),
              hintStyle: GoogleFonts.inter(
                fontSize: isSmallScreen ? 12 : 13,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return locale.translate('pleaseEnterBugTitle');
              }
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 14 : 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: locale.translate('category'),
                    labelStyle: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: AppColors.primary,
                      size: isSmallScreen ? 20 : 22,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['value'],
                      child: Text(category['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                  },
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPriority,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: locale.translate('priority'),
                    labelStyle: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.priority_high_rounded,
                      color: AppColors.error,
                      size: isSmallScreen ? 20 : 22,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.error, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  items: _priorities.map((priority) {
                    return DropdownMenuItem<String>(
                      value: priority['value'],
                      child: Row(
                        children: [
                          Container(
                            width: isSmallScreen ? 10 : 12,
                            height: isSmallScreen ? 10 : 12,
                            decoration: BoxDecoration(
                              color: priority['color'],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (priority['color'] as Color).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 6 : 8),
                          Text(
                            priority['label'],
                            style: GoogleFonts.inter(
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPriority = value!);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBugDetailsSection(bool isSmallScreen) {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
          Row(
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
                  Icons.description_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: Text(
                  locale.translate('bugDetails'),
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 13 : 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: locale.translate('description'),
              labelStyle: GoogleFonts.inter(
                fontSize: isSmallScreen ? 12 : 14,
                color: AppColors.textSecondary,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: isSmallScreen ? 70 : 80),
                child: Icon(
                  Icons.description_rounded,
                  color: AppColors.info,
                  size: isSmallScreen ? 20 : 22,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.info, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.error),
              ),
              filled: true,
              fillColor: AppColors.background,
              alignLabelWithHint: true,
              hintText: locale.translate('describeBugInDetail'),
              hintStyle: GoogleFonts.inter(
                fontSize: isSmallScreen ? 12 : 13,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return locale.translate('pleaseDescribeBug');
              }
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 14 : 16),
          TextFormField(
            controller: _stepsController,
            maxLines: 3,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 13 : 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: locale.translate('stepsToReproduce'),
              labelStyle: GoogleFonts.inter(
                fontSize: isSmallScreen ? 12 : 14,
                color: AppColors.textSecondary,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: isSmallScreen ? 50 : 60),
                child: Icon(
                  Icons.format_list_numbered_rounded,
                  color: AppColors.info,
                  size: isSmallScreen ? 20 : 22,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.info, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.error),
              ),
              filled: true,
              fillColor: AppColors.background,
              alignLabelWithHint: true,
              hintText: locale.translate('stepByStepInstructions'),
              hintStyle: GoogleFonts.inter(
                fontSize: isSmallScreen ? 12 : 13,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return locale.translate('pleaseProvideSteps');
              }
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 14 : 16),
          TextFormField(
            controller: _expectedController,
            maxLines: 2,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 13 : 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: locale.translate('expectedBehavior'),
              labelStyle: GoogleFonts.inter(
                fontSize: isSmallScreen ? 12 : 14,
                color: AppColors.textSecondary,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: isSmallScreen ? 35 : 40),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: isSmallScreen ? 20 : 22,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.success, width: 2),
              ),
              filled: true,
              fillColor: AppColors.background,
              alignLabelWithHint: true,
              hintText: locale.translate('whatShouldHappen'),
              hintStyle: GoogleFonts.inter(
                fontSize: isSmallScreen ? 12 : 13,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 14 : 16),
          TextFormField(
            controller: _actualController,
            maxLines: 2,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 13 : 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: locale.translate('actualBehavior'),
              labelStyle: GoogleFonts.inter(
                fontSize: isSmallScreen ? 12 : 14,
                color: AppColors.textSecondary,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: isSmallScreen ? 35 : 40),
                child: Icon(
                  Icons.error_rounded,
                  color: AppColors.error,
                  size: isSmallScreen ? 20 : 22,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.error, width: 2),
              ),
              filled: true,
              fillColor: AppColors.background,
              alignLabelWithHint: true,
              hintText: locale.translate('whatActuallyHappens'),
              hintStyle: GoogleFonts.inter(
                fontSize: isSmallScreen ? 12 : 13,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoSection(bool isSmallScreen) {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.15),
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
                  Icons.phone_android_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: Text(
                  locale.translate('systemInformation'),
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 14 : 16),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                _buildSystemInfoRow('Platform', _getPlatform(), isSmallScreen),
                _buildSystemInfoRow('App Version', '1.0.0', isSmallScreen),
                _buildSystemInfoRow('Build Number', '100', isSmallScreen),
                _buildSystemInfoRow('Flutter Version', '3.19.0', isSmallScreen),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          Text(
            locale.translate('systemInfoNote'),
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 11 : 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 3 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isSmallScreen) {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: isSmallScreen ? 50 : 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitBugReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
                  width: isSmallScreen ? 20 : 24,
                  height: isSmallScreen ? 20 : 24,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send_rounded,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      locale.translate('submitBugReport'),
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _getPlatform() {
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
      return 'Unknown';
    } catch (e) {
      return 'Web';
    }
  }

  Future<void> _submitBugReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Show success message
      _showSuccessDialog();
      
    } catch (e) {
      _showSnackBar('Failed to submit bug report. Please try again.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              locale.translate('success'),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.translate('bugReportSubmitted'),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${locale.translate('reportId')}: #BUG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: Text(
              locale.translate('ok'),
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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