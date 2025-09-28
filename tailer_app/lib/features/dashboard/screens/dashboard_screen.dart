import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/data/services/dashboard_service.dart';
import 'package:tailer_app/features/dashboard/widgets/dashboard_card.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                      
                      // Quick Actions
                      _buildQuickActions(),
                      const SizedBox(height: AppConstants.spacingXL),
                    ],
                  ),
                ),
              ),
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
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          'Welcome back to your tailoring business',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Dashboard Overview',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(AppConstants.primaryTeal),
            ),
          ),
        ),
      ],
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
              _buildActionButton(
                title: 'Add New Customer',
                subtitle: 'Register a new customer',
                icon: Icons.person_add_outlined,
                color: const Color(AppConstants.primaryTeal),
                onTap: () => _navigateToAddCustomer(),
              ),
              const Divider(height: AppConstants.spacingL),
              _buildActionButton(
                title: 'Create Order',
                subtitle: 'Start a new tailoring order',
                icon: Icons.add_shopping_cart_outlined,
                color: const Color(AppConstants.primaryOrange),
                onTap: () => _navigateToCreateOrder(),
              ),
              const Divider(height: AppConstants.spacingL),
              _buildActionButton(
                title: 'Take Measurements',
                subtitle: 'Record customer measurements',
                icon: Icons.straighten,
                color: Colors.purple,
                onTap: () => _navigateToMeasurements(),
              ),
            ],
          ),
        ),
      ],
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

  // Navigation methods - implement these based on your routing
  void _navigateToCustomers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Customers')),
    );
  }

  void _navigateToOrders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Orders')),
    );
  }

  void _navigateToRevenue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Revenue')),
    );
  }

  void _navigateToMeasurements() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Measurements')),
    );
  }

  void _navigateToAppointments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Appointments')),
    );
  }

  void _navigateToAddCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Add Customer')),
    );
  }

  void _navigateToCreateOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Create Order')),
    );
  }
}
