import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/data/services/dashboard_service.dart';
import 'package:tailer_app/features/dashboard/widgets/dashboard_card.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/widgets/custom_bottom_navigation.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/core/services/back_button_handler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      await _dashboardService.initializeDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = _dashboardService.dashboardStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      await _dashboardService.refreshDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = _dashboardService.dashboardStats;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh dashboard: $e'),
            backgroundColor: Colors.red,
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
      backgroundColor: Colors.grey[50],
      appBar: DashboardHeader(
        title: 'Dashboard',
        backgroundColor: const Color(AppConstants.primaryTeal),
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
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(AppConstants.primaryTeal),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshDashboard,
                color: const Color(AppConstants.primaryTeal),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppConstants.spacingM),
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
      floatingActionButton: _isRefreshing
          ? const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : FloatingActionButton(
              onPressed: _refreshDashboard,
              backgroundColor: const Color(AppConstants.primaryTeal),
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
            const Color(AppConstants.primaryTeal).withOpacity(0.1),
            const Color(AppConstants.primaryTeal).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: const Color(AppConstants.primaryTeal).withOpacity(0.2),
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
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      'Tailor Business Manager',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      'Managing your business since ${now.year}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.design_services,
                  color: Color(AppConstants.primaryTeal),
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
                  color: const Color(AppConstants.primaryTeal),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: AppConstants.spacingXS),
                    Text(
                      '${now.day}/${now.month}/${now.year}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingXS),
                    Text(
                      'Business Active',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
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
        Text(
          'Business Overview',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: AppConstants.spacingM,
          mainAxisSpacing: AppConstants.spacingM,
          children: [
            DashboardCard(
              title: 'Total Customers',
              value: '${_dashboardData['totalCustomers']}',
              icon: Icons.people_outline,
              iconColor: const Color(AppConstants.primaryTeal),
              onTap: () => _navigateToCustomers(),
            ),
            DashboardCard(
              title: 'Active Orders',
              value: '${_dashboardData['activeOrders']}',
              icon: Icons.pending_actions_outlined,
              iconColor: const Color(AppConstants.primaryOrange),
              onTap: () => _navigateToOrders(),
            ),
            DashboardCard(
              title: 'Completed Orders',
              value: '${_dashboardData['completedOrders']}',
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
              onTap: () => _navigateToOrders(),
            ),
            DashboardCard(
              title: 'Total Revenue',
              value: '₹${_formatRevenue(_dashboardData['totalRevenue'])}',
              icon: Icons.currency_rupee,
              iconColor: Colors.purple,
              subtitle: 'This month',
              onTap: () => _navigateToRevenue(),
            ),
          ],
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
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                title: 'Pending Measurements',
                value: '${_dashboardData['pendingMeasurements']}',
                icon: Icons.straighten,
                iconColor: Colors.amber[700]!,
                onTap: () => _navigateToMeasurements(),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: DashboardCard(
                title: 'Today\'s Appointments',
                value: '${_dashboardData['todayAppointments']}',
                icon: Icons.schedule,
                iconColor: Colors.blue,
                onTap: () => _navigateToAppointments(),
              ),
            ),
          ],
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
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToOrders(),
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(AppConstants.primaryTeal),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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
                },
                {
                  'title': 'New customer registered',
                  'subtitle': 'Mike Wilson added to database',
                  'time': '4 hours ago',
                  'icon': Icons.person_add,
                  'color': const Color(AppConstants.primaryTeal),
                },
                {
                  'title': 'Payment received',
                  'subtitle': '₹2,500 from Order #ORD002',
                  'time': '1 day ago',
                  'icon': Icons.payment,
                  'color': Colors.blue,
                },
                {
                  'title': 'Order #ORD003 in progress',
                  'subtitle': 'Formal suit measurements taken',
                  'time': '2 days ago',
                  'icon': Icons.work_outline,
                  'color': Colors.orange,
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
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  activity['subtitle'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Text(
                  activity['time'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Viewing details for: ${activity['title']}'),
                    ),
                  );
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
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        // Primary Actions Grid
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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
                      color: const Color(AppConstants.primaryTeal),
                      onTap: () => _navigateToAddCustomer(),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: _buildQuickActionCard(
                      title: 'Create Order',
                      subtitle: 'Start new order',
                      icon: Icons.add_shopping_cart_outlined,
                      color: const Color(AppConstants.primaryOrange),
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
                      color: Colors.purple,
                      onTap: () => _navigateToMeasurements(),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: _buildQuickActionCard(
                      title: 'Payment Reports',
                      subtitle: 'View receipts & refunds',
                      icon: Icons.receipt_long,
                      color: Colors.blue,
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
                color: Colors.blue,
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
          color: color.withOpacity(0.05),
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
                color: color.withOpacity(0.1),
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
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
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
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Measurements feature coming soon!')),
    );
  }

  void _navigateToAppointments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointments feature coming soon!')),
    );
  }

  void _navigateToAddCustomer() {
    context.goNamed(RouteNames.addCustomer);
  }

  void _navigateToCreateOrder() {
    context.goNamed(RouteNames.addOrder);
  }


}
