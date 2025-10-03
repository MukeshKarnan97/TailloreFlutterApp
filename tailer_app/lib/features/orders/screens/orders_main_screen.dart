import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/widgets/custom_bottom_navigation.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import '../../../data/services/local_db_service.dart';
import '../../../data/models/order_model.dart';
import '../../../core/utils/logger.dart';
import 'pending_orders_screen.dart';
// Import for Order extension methods if needed

class OrdersMainScreen extends StatefulWidget {
  const OrdersMainScreen({Key? key}) : super(key: key);

  @override
  State<OrdersMainScreen> createState() => _OrdersMainScreenState();
}

class _OrdersMainScreenState extends State<OrdersMainScreen> with NavigationMixin {
  int _currentNavIndex = 2; // Orders is index 2
  late SimpleLocaleProvider _localeProvider;
  final LocalDatabaseService _dbService = LocalDatabaseService();
  
  // Real data state
  List<Order> _allOrders = [];
  bool _isLoading = true;
  int _totalOrders = 0;
  int _thisMonthOrders = 0;
  int _pendingOrders = 0;
  int _inProgressOrders = 0;
  int _readyOrders = 0;
  double _totalRevenue = 0.0;
  double _pendingPayments = 0.0;
  double _pendingOrdersValue = 0.0;
  double _inProgressOrdersValue = 0.0;
  double _readyOrdersValue = 0.0;

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _loadOrderData();
  }

  @override
  void dispose() {
    // Don't dispose singleton _localeProvider
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        context.goNamed(RouteNames.dashboard);
        break;
      case 1:
        context.goNamed(RouteNames.customers);
        break;
      case 2:
        // Already on orders, stay here
        break;
      case 3:
        context.goNamed(RouteNames.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        final navItems = [
          BottomNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: locale.t('dashboard'),
          ),
          BottomNavItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: locale.t('customers'),
          ),
          BottomNavItem(
            icon: Icons.shopping_bag_outlined,
            activeIcon: Icons.shopping_bag,
            label: locale.t('orders'),
          ),
          BottomNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: locale.t('settings'),
          ),
        ];

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: DashboardHeader(
            title: locale.t('ordersManagement'),
            backgroundColor: const Color(AppConstants.primaryTeal),
            notificationCount: 3,
            onNotificationTap: () {
              showNavigationMessage(context, locale.t('notifications'));
            },
          ),
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    // Welcome Section
                    Container(
                      width: double.infinity,
                      color: const Color(AppConstants.primaryTeal),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.t('manageYourOrders'),
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            locale.t('trackOrdersDeliveries'),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Search Bar
                            _buildSearchBar(locale),

                            const SizedBox(height: 20),

                            // Payment Overview Section
                            _buildPaymentOverview(locale),

                            const SizedBox(height: 20),

                            // Quick Actions Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionCard(
                                    context: context,
                                    title: locale.t('viewAllOrders'),
                                    subtitle: locale.t('seeOrderHistory'),
                                    icon: Icons.list_alt,
                                    color: const Color(AppConstants.primaryTeal),
                                    onTap: () => context.pushNamed(RouteNames.orderList),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildActionCard(
                                    context: context,
                                    title: locale.t('createNewOrder'),
                                    subtitle: locale.t('startNewOrder'),
                                    icon: Icons.add_shopping_cart,
                                    color: const Color(AppConstants.primaryOrange),
                                    onTap: () => context.pushNamed(RouteNames.addOrder),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Payment Quick Actions Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionCard(
                                    context: context,
                                    title: locale.t('collectPayments'),
                                    subtitle: locale.t('receivePendingPayments'),
                                    icon: Icons.payment,
                                    color: Colors.green,
                                    onTap: () => _navigateToPayments(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildActionCard(
                                    context: context,
                                    title: locale.t('paymentHistory'),
                                    subtitle: locale.t('viewAllTransactions'),
                                    icon: Icons.history,
                                    color: Colors.purple,
                                    onTap: () => _navigateToPaymentHistory(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Order Status Cards with Payment Info and Quick Actions
                            _buildEnhancedStatusCard(
                              context: context,
                              title: locale.t('pendingOrders'),
                              subtitle: locale.t('ordersAwaitingAction'),
                              icon: Icons.pending_actions,
                              color: Colors.orange,
                              count: _pendingOrders.toString(),
                              paymentAmount: '₹${_pendingOrdersValue.toStringAsFixed(0)}',
                              priority: _pendingOrders > 5 ? 'High' : _pendingOrders > 2 ? 'Medium' : 'Low',
                              onTap: () => _navigateToOrderList('pending'),
                            ),

                            const SizedBox(height: 16),

                            _buildEnhancedStatusCard(
                              context: context,
                              title: locale.t('inProgressOrders'),
                              subtitle: locale.t('ordersBeingWorked'),
                              icon: Icons.work_outline,
                              color: Colors.blue,
                              count: _inProgressOrders.toString(),
                              paymentAmount: '₹${_inProgressOrdersValue.toStringAsFixed(0)}',
                              priority: _inProgressOrders > 3 ? 'Medium' : 'Low',
                              onTap: () => _navigateToOrderList('in_progress'),
                            ),

                            const SizedBox(height: 16),

                            _buildEnhancedStatusCard(
                              context: context,
                              title: locale.t('readyOrders'),
                              subtitle: locale.t('ordersReadyForDelivery'),
                              icon: Icons.check_circle_outline,
                              color: Colors.green,
                              count: _readyOrders.toString(),
                              paymentAmount: '₹${_readyOrdersValue.toStringAsFixed(0)}',
                              priority: _readyOrders > 2 ? 'Medium' : 'Low',
                              onTap: () => _navigateToOrderList('completed'),
                            ),

                            const SizedBox(height: 30),

                            // Quick Stats Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locale.t('quickStats'),
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatItem(
                                          label: locale.t('totalOrders'),
                                          value: _totalOrders.toString(),
                                          icon: Icons.assignment,
                                          color: const Color(AppConstants.primaryTeal),
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildStatItem(
                                          label: locale.t('thisMonth'),
                                          value: _thisMonthOrders.toString(),
                                          icon: Icons.calendar_today,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          bottomNavigationBar: AnimatedBottomNavigation(
            currentIndex: _currentNavIndex,
            onTap: _onNavTap,
            items: navItems,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(AppConstants.primaryTeal),
            unselectedItemColor: Colors.grey.shade600,
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatusCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String count,
    required String paymentAmount,
    required String priority,
    required VoidCallback onTap,
  }) {
    Color priorityColor = priority == 'High' 
        ? Colors.red 
        : priority == 'Medium' 
            ? Colors.orange 
            : Colors.green;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                priority,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: priorityColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      count,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.currency_rupee,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Value: $paymentAmount',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey.shade400,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchBar(AppLocalizations locale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: locale.t('searchOrders'),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        onChanged: (value) {
          _performSearch(value);
        },
      ),
    );
  }

  Widget _buildPaymentOverview(AppLocalizations locale) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade600,
            Colors.green.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                locale.t('paymentOverview'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadOrderData,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPaymentStatItem(
                  label: locale.t('totalRevenue'),
                  value: '₹${_totalRevenue.toStringAsFixed(0)}',
                  subLabel: locale.t('thisMonth'),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildPaymentStatItem(
                  label: locale.t('pendingPaymentAmount'),
                  value: '₹${_pendingPayments.toStringAsFixed(0)}',
                  subLabel: locale.t('awaitingCollection'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildPaymentStatItem({
    required String label,
    required String value,
    required String subLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subLabel,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Data Loading Methods
  Future<void> _loadOrderData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await _dbService.getOrders();
      _allOrders = orders.where((order) => !order.isDeleted).toList();
      
      _calculateStats();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Logger.error('OrdersMainScreen', 'Failed to load order data', 
                   error: e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStats() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    
    _totalOrders = _allOrders.length;
    _thisMonthOrders = _allOrders.where((order) => 
        order.createdAt.isAfter(thisMonth)).length;
    
    // Count orders by status
    _pendingOrders = _allOrders.where((order) => 
        order.status.toLowerCase() == 'pending').length;
    _inProgressOrders = _allOrders.where((order) => 
        order.status.toLowerCase() == 'in_progress' || 
        order.status.toLowerCase() == 'cutting' || 
        order.status.toLowerCase() == 'stitching').length;
    _readyOrders = _allOrders.where((order) => 
        order.status.toLowerCase() == 'completed' || 
        order.status.toLowerCase() == 'ready').length;
    
    // Calculate financial data
    _totalRevenue = _allOrders.fold(0.0, (sum, order) => sum + order.advancePaid);
    _pendingPayments = _allOrders.fold(0.0, (sum, order) => 
        sum + (order.totalAmount - order.advancePaid));
    
    // Calculate order values by status
    _pendingOrdersValue = _allOrders
        .where((order) => order.status.toLowerCase() == 'pending')
        .fold(0.0, (sum, order) => sum + order.totalAmount);
    
    _inProgressOrdersValue = _allOrders
        .where((order) => order.status.toLowerCase() == 'in_progress' || 
                         order.status.toLowerCase() == 'cutting' || 
                         order.status.toLowerCase() == 'stitching')
        .fold(0.0, (sum, order) => sum + order.totalAmount);
    
    _readyOrdersValue = _allOrders
        .where((order) => order.status.toLowerCase() == 'completed' || 
                         order.status.toLowerCase() == 'ready')
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }



  void _performSearch(String query) {
    if (query.isEmpty) {
      _loadOrderData();
      return;
    }
    
    setState(() {
      _allOrders = _allOrders.where((order) =>
          order.customerId.toLowerCase().contains(query.toLowerCase()) ||
          order.uniqueId.toLowerCase().contains(query.toLowerCase()) ||
          order.notes.toLowerCase().contains(query.toLowerCase())
      ).toList();
      _calculateStats();
    });
  }

  // Navigation Methods
  void _navigateToOrderList(String? status) {
    // Navigate to status-specific order list screen
    switch (status?.toLowerCase()) {
      case 'pending':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PendingOrdersScreen()),
        );
        break;
      case 'in_progress':
        // TODO: Implement InProgressOrdersScreen
        showNavigationMessage(context, 'In Progress Orders - Coming Soon!');
        break;
      case 'completed':
      case 'ready':
        // TODO: Implement CompletedOrdersScreen
        showNavigationMessage(context, 'Completed Orders - Coming Soon!');
        break;
      default:
        context.pushNamed(RouteNames.orderList);
    }
  }

  // This method is already defined above

  void _navigateToPayments() {
    // TODO: Implement PaymentCollectionScreen
    showNavigationMessage(context, 'Payment Collection - Coming Soon!');
  }

  void _navigateToPaymentHistory() {
    // Navigate to existing payment history or show message
    showNavigationMessage(context, 'Payment History - Feature Available!');
  }
}