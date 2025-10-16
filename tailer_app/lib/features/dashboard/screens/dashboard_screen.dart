import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:tailer_app/core/theme/text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/data/services/dashboard_service.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/features/dashboard/widgets/dashboard_card.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/widgets/custom_bottom_navigation.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/core/services/back_button_handler.dart';
import 'package:tailer_app/core/utils/logger.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final AuthService _authService = AuthService();
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _currentNavIndex = 0;
  Timer? _refreshTimer;
  DateTime? _lastUpdated;
  String _selectedTimePeriod = 'today'; // today, this_week, this_month, this_year, all_time
  String? _tailorId;

  @override
  void initState() {
    super.initState();
    Logger.info('DashboardScreen', '🚀 initState called');
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    Logger.info('DashboardScreen', '🔐 Initializing auth...');
    await _authService.initialize();
    
    if (_authService.currentUser != null) {
      Logger.info('DashboardScreen', '✅ User authenticated: ${_authService.currentUser!.email}');
      setState(() {
        _tailorId = _authService.currentUser!.email;
      });
      Logger.info('DashboardScreen', '📋 tailorId set to: $_tailorId');
      _loadDashboardData();
      _startAutoRefresh();
    } else {
      Logger.error('DashboardScreen', '❌ No user authenticated!');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Start automatic refresh every 30 seconds for real-time updates
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isRefreshing) {
        _refreshDashboardSilently();
      }
    });
  }

  /// Refresh dashboard data silently without showing loading indicator
  Future<void> _refreshDashboardSilently() async {
    if (_tailorId == null) return;
    
    try {
      await _dashboardService.refreshDashboard(tailorId: _tailorId!);
      if (mounted) {
        setState(() {
          _dashboardData = _dashboardService.dashboardStats;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      // Silently fail for auto-refresh, don't show error to user
      debugPrint('Auto-refresh failed: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    if (_tailorId == null) {
      Logger.error('DashboardScreen', '⚠️ tailorId is null, cannot load data');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    
    Logger.info('DashboardScreen', '📊 Loading data for tailorId: $_tailorId');
    
    try {
      await _dashboardService.initializeDashboard(tailorId: _tailorId!);
      Logger.info('DashboardScreen', '✅ Data loaded successfully');
      
      if (mounted) {
        setState(() {
          _dashboardData = _dashboardService.dashboardStats;
          _lastUpdated = DateTime.now();
          _isLoading = false;
        });
        Logger.debug('DashboardScreen', '📊 Dashboard Data: $_dashboardData');
      }
    } catch (e, stackTrace) {
      Logger.error('DashboardScreen', '❌ Error loading data', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Load dashboard data with specific time period filter
  Future<void> _loadDashboardDataWithFilter(String timePeriod) async {
    if (_tailorId == null) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      await _dashboardService.initializeDashboard(
        tailorId: _tailorId!,
        timePeriod: timePeriod,
      );
      if (mounted) {
        setState(() {
          _dashboardData = _dashboardService.dashboardStats;
          _lastUpdated = DateTime.now();
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing || _tailorId == null) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      // Force refresh from database
      await _dashboardService.refreshDashboard(tailorId: _tailorId!);
      if (mounted) {
        setState(() {
          _dashboardData = _dashboardService.dashboardStats;
          _lastUpdated = DateTime.now();
        });
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Dashboard updated with latest data'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh dashboard: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler.wrapWithBackHandler(
      type: BackHandlerType.main,
      context: context,
      homeRoute: '/home',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: DashboardHeader(
          title: 'Dashboard',
          backgroundColor: AppColors.primary,
        notificationCount: 3, // You can make this dynamic
        onBackPressed: () {
          // Handle back button press - maybe go to previous screen or drawer
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Back button pressed')),
          );
        },
        onNotificationTap: () {
          // Handle notification tap
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications: You have 3 new notifications')),
          );
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshDashboard,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final padding = constraints.maxWidth > 600 
                          ? AppConstants.spacingL 
                          : AppConstants.spacingM;
                      return Padding(
                        padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeader(),
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Quick Stats Grid
                      _buildQuickStats(),
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Today's Overview
                      _buildTodayOverview(),
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Recent Activity Section
                      _buildRecentActivity(),
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Quick Actions
                      _buildQuickActions(),
                        const SizedBox(height: AppConstants.spacingXL),
                      ],
                    ),
                      );
                    },
                  ),
                ),
              ),
      ),
      bottomNavigationBar: AnimatedBottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        items: TailorAppBottomNavItems.defaultItems,
  selectedItemColor: AppColors.primary,
  backgroundColor: AppColors.panel,
      ),
      floatingActionButton: _isRefreshing
          ? const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : FloatingActionButton(
              onPressed: _refreshDashboard,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final now = DateTime.now();
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      'Tailor Business Manager',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      'Managing your business since ${now.year}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.design_services,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: AppConstants.spacingXS),
                    Text(
                      '${now.day}/${now.month}/${now.year}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingXS),
                    Text(
                      'Business Active',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        'Business Overview',
        style: AppTextStyles.heading4.copyWith(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis, // prevent overflow
      ),
    ),
    Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTimePeriod,
                isDense: true,
                icon: Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 20),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                items: const [
                  DropdownMenuItem(value: 'today', child: Text('Today')),
                  DropdownMenuItem(value: 'this_week', child: Text('This Week')),
                  DropdownMenuItem(value: 'this_month', child: Text('This Month')),
                  DropdownMenuItem(value: 'this_year', child: Text('This Year')),
                  DropdownMenuItem(value: 'all_time', child: Text('All Time')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTimePeriod = value;
                    });
                    _loadDashboardDataWithFilter(value);
                  }
                },
              ),
            ),
          ),

          if (_lastUpdated != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _getLastUpdatedText(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textHint,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  ],
),

        const SizedBox(height: AppConstants.spacingM),
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid layout with overflow prevention
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth > 600 ? 4 : 2;
            final childAspectRatio = screenWidth > 600 ? 2.0 :
                                   screenWidth > 450 ? 1.7 :
                                   screenWidth > 350 ? 1.5 : 1.3;
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: AppConstants.spacingM,
              mainAxisSpacing: AppConstants.spacingM,
              children: [
                DashboardCard(
                  title: 'Total Customers',
                  value: '${_dashboardData['totalCustomers']}',
                  icon: Icons.people_outline,
                  iconColor: AppColors.primary,
                  backgroundColor: AppColors.panel,
                  onTap: () => _navigateToCustomers(),
                ),
                DashboardCard(
                  title: 'Active Orders',
                  value: '${_dashboardData['activeOrders']}',
                  icon: Icons.pending_actions_outlined,
                  iconColor: AppColors.accent,
                  backgroundColor: AppColors.panel,
                  onTap: () => _navigateToOrders(),
                ),
                DashboardCard(
                  title: 'Completed Orders',
                  value: '${_dashboardData['completedOrders']}',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                  backgroundColor: AppColors.panel,
                  onTap: () => _navigateToOrders(),
                ),
                DashboardCard(
                  title: 'Total Revenue',
                  value: '₹${_formatRevenue(_dashboardData['totalRevenue'])}',
                  icon: Icons.currency_rupee,
                  iconColor: AppColors.secondary,
                  backgroundColor: AppColors.panel,
                  subtitle: 'This month',
                  onTap: () => _navigateToRevenue(),
                ),
            ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTodayOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: AppTextStyles.heading4.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth > 600 ? 4 : 2;
            final childAspectRatio = screenWidth > 600 ? 2.0 :
                                   screenWidth > 450 ? 1.7 :
                                   screenWidth > 350 ? 1.5 : 1.3;
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: AppConstants.spacingM,
              mainAxisSpacing: AppConstants.spacingM,
              children: [
                DashboardCard(
                  title: 'Pending Measurements',
                  value: '${_dashboardData['pendingMeasurements']}',
                  icon: Icons.straighten,
                  iconColor: AppColors.warning,
                  backgroundColor: AppColors.panel,
                  onTap: () => _navigateToMeasurements(),
                ),
                DashboardCard(
                  title: 'Today\'s Appointments',
                  value: '${_dashboardData['todayAppointments']}',
                  icon: Icons.schedule,
                  iconColor: AppColors.info,
                  backgroundColor: AppColors.panel,
                  onTap: () => _navigateToAppointments(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToOrders(),
              child: Text(
                'View All',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4, // Show recent 4 activities
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final activities = [
                {
                  'title': 'Order #ORD001 completed',
                  'subtitle': 'Wedding dress for Sarah Johnson',
                  'time': '2 hours ago',
                  'icon': Icons.check_circle,
                  'color': Colors.green,
                  'type': 'order',
                  'orderId': 'ORD001',
                },
                {
                  'title': 'New customer registered',
                  'subtitle': 'Mike Wilson added to database',
                  'time': '4 hours ago',
                  'icon': Icons.person_add,
                  'color': const Color(AppConstants.primaryTeal),
                  'type': 'customer',
                },
                {
                  'title': 'Payment received',
                  'subtitle': '₹2,500 from Order #ORD002',
                  'time': '1 day ago',
                  'icon': Icons.payment,
                  'color': Colors.blue,
                  'type': 'payment',
                },
                {
                  'title': 'Order #ORD003 in progress',
                  'subtitle': 'Formal suit measurements taken',
                  'time': '2 days ago',
                  'icon': Icons.work_outline,
                  'color': Colors.orange,
                  'type': 'order',
                  'orderId': 'ORD003',
                },
              ];

              final activity = activities[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingS,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (activity['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    activity['icon'] as IconData,
                    color: activity['color'] as Color,
                    size: 20,
                  ),
                ),
                title: Text(
                  activity['title'] as String,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  activity['subtitle'] as String,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: Text(
                  activity['time'] as String,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
                onTap: () {
                  // Navigate based on activity type
                  final type = activity['type'] as String?;
                  
                  switch (type) {
                    case 'order':
                      // Navigate to order list where user can search for the order
                      context.goNamed(RouteNames.orderList);
                      break;
                    case 'customer':
                      // Navigate to customers list
                      context.goNamed(RouteNames.viewCustomers);
                      break;
                    case 'payment':
                      // Navigate to payment history
                      context.goNamed(RouteNames.paymentHistory);
                      break;
                    default:
                      // Fallback to orders list
                      context.goNamed(RouteNames.orders);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.heading4.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        // Primary Actions Grid
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // First row of actions
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      title: 'Add Customer',
                      subtitle: 'Register new customer',
                      icon: Icons.person_add_outlined,
                      color: AppColors.primary,
                      onTap: () => _navigateToAddCustomer(),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: _buildQuickActionCard(
                      title: 'Create Order',
                      subtitle: 'Start new order',
                      icon: Icons.add_shopping_cart_outlined,
                      color: AppColors.accent,
                      onTap: () => _navigateToCreateOrder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Second row of actions
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      title: 'Measurements',
                      subtitle: 'Record measurements',
                      icon: Icons.straighten,
                      color: AppColors.accent,
                      onTap: () => _navigateToMeasurements(),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: _buildQuickActionCard(
                      title: 'Payment Reports',
                      subtitle: 'View receipts & refunds',
                      icon: Icons.receipt_long,
                      color: AppColors.secondary,
                      onTap: () => _navigateToRevenue(),
                    ),
                  ),
                ],
              ),
              
              const Divider(height: AppConstants.spacingL * 2),
              
              // Language Demo Section
              _buildActionButton(
                title: '🌍 Language Demo',
                subtitle: 'Test English ⇄ Tamil switching',
                icon: Icons.translate,
                color: AppColors.secondary,
                onTap: () => context.goNamed(RouteNames.languageDemo),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 16,
          ),
        ],
      ),
    );
  }

  String _formatRevenue(double revenue) {
    if (revenue >= 100000) {
      return '${(revenue / 100000).toStringAsFixed(1)}L';
    } else if (revenue >= 1000) {
      return '${(revenue / 1000).toStringAsFixed(1)}K';
    } else {
      return revenue.toStringAsFixed(0);
    }
  }

  // Bottom navigation handler
  // FIXED: Improved navigation handler with proper error handling
  void _onNavTap(int index) {
    // Prevent navigation to same tab
    if (index == _currentNavIndex) return;
    
    // Update UI immediately for visual feedback
    setState(() {
      _currentNavIndex = index;
    });
    
    // Add small delay to ensure state update completes
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      
      try {
        switch (index) {
          case 0: // Dashboard
            // Already on dashboard, no navigation needed
            break;
          case 1: // Customers
            context.goNamed(RouteNames.customers);
            break;
          case 2: // Orders  
            context.goNamed(RouteNames.orders);
            break;
          case 3: // Settings
            context.goNamed(RouteNames.settings);
            break;
          default:
            debugPrint('Unknown navigation index: $index');
        }
      } catch (e) {
        debugPrint('Navigation error: $e');
        // Reset to current screen on error
        if (mounted) {
          setState(() {
            _currentNavIndex = 0; // Dashboard index
          });
        }
      }
    });
  }

  // Navigation helper methods for dashboard actions
  void _navigateToCustomers() {
    context.goNamed(RouteNames.customers);
  }

  void _navigateToOrders() {
    context.goNamed(RouteNames.orders);
  }

  void _navigateToRevenue() {
    context.goNamed(RouteNames.paymentReports);
  }

  void _navigateToMeasurements() {
    // Navigate to measurement list - shows all customer measurements
    context.goNamed(RouteNames.measurementList);
  }

  void _navigateToAppointments() {
    // Navigate to orders screen - user can filter by today's appointments
    context.goNamed(RouteNames.orderList);
  }

  void _navigateToAddCustomer() {
    context.goNamed(RouteNames.addCustomer);
  }

  void _navigateToCreateOrder() {
    context.goNamed(RouteNames.addOrder);
  }
  /// Get formatted last updated text
  String _getLastUpdatedText() {
    if (_lastUpdated == null) return '';

    final now = DateTime.now();
    final difference = now.difference(_lastUpdated!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

}
