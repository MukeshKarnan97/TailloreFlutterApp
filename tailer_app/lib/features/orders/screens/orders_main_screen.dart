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
import '../../../data/models/customer_model.dart';
import '../../../core/utils/logger.dart';
import 'pending_orders_screen.dart';
import 'in_progress_orders_screen.dart';
import 'completed_orders_screen.dart';
import 'ready_orders_screen.dart';
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
  int _completedOrders = 0;
  double _totalRevenue = 0.0;
  double _pendingPayments = 0.0;
  double _pendingOrdersValue = 0.0;
  double _inProgressOrdersValue = 0.0;
  double _readyOrdersValue = 0.0;
  double _completedOrdersValue = 0.0;

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
            onBackPressed: () {
              context.goNamed(RouteNames.dashboard);
            },
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
                              onTap: () => _navigateToOrderList('ready'),
                            ),

                            const SizedBox(height: 16),

                            _buildEnhancedStatusCard(
                              context: context,
                              title: locale.t('completedOrders'),
                              subtitle: locale.t('ordersDeliveredAndPaid'),
                              icon: Icons.done_all,
                              color: Colors.purple,
                              count: _completedOrders.toString(),
                              paymentAmount: '₹${_completedOrdersValue.toStringAsFixed(0)}',
                              priority: _completedOrders > 5 ? 'Low' : 'Low',
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
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: _showDeletedOrders,
                backgroundColor: Colors.grey.shade600,
                heroTag: "deletedOrders",
                child: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'View Deleted Orders',
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                onPressed: _updateOrdersForPaymentCollection,
                backgroundColor: Colors.blue,
                heroTag: "updatePayments",
                child: const Icon(Icons.payment, color: Colors.white),
                tooltip: 'Update Orders for Payment Collection',
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                onPressed: _insertTestData,
                backgroundColor: Colors.orange,
                heroTag: "insertTest",
                child: const Icon(Icons.add_box, color: Colors.white),
                tooltip: 'Insert Test Data',
              ),
            ],
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
      List<Order> orders;
      try {
        // Try to get orders excluding deleted ones
        final orderMaps = await _dbService.select('orders', where: 'is_deleted = 0');
        orders = orderMaps.map((map) => Order.fromMap(map)).toList();
      } catch (e) {
        // If is_deleted column doesn't exist, get all orders
        Logger.info('OrdersMainScreen', 'is_deleted column not found, loading all orders');
        orders = await _dbService.getOrders();
      }
      
      _allOrders = orders;
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
    
    // Add logging to see what orders we have
    Logger.info('OrdersMainScreen', 'Total orders loaded: ${_allOrders.length}');
    for (var order in _allOrders) {
      Logger.debug('OrdersMainScreen', 'Order ${order.uniqueId}: Status=${order.status}, Total=₹${order.totalAmount}, Paid=₹${order.advancePaid}, IsDeleted=${order.isDeleted}');
    }
    
    // Count orders by status
    _pendingOrders = _allOrders.where((order) => 
        order.status.toLowerCase() == 'pending').length;
    _inProgressOrders = _allOrders.where((order) => 
        order.status.toLowerCase() == 'in_progress' || 
        order.status.toLowerCase() == 'cutting' || 
        order.status.toLowerCase() == 'stitching').length;
    _readyOrders = _allOrders.where((order) => 
        order.status.toLowerCase() == 'ready').length;
    _completedOrders = _allOrders.where((order) => 
        order.status.toLowerCase() == 'completed' || 
        order.status.toLowerCase() == 'delivered').length;
    
    // Log the counts
    Logger.info('OrdersMainScreen', 'Order Status Summary: Pending=$_pendingOrders, InProgress=$_inProgressOrders, Ready=$_readyOrders, Completed=$_completedOrders');
    
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
        .where((order) => order.status.toLowerCase() == 'ready')
        .fold(0.0, (sum, order) => sum + order.totalAmount);
    
    _completedOrdersValue = _allOrders
        .where((order) => order.status.toLowerCase() == 'completed' || 
                         order.status.toLowerCase() == 'delivered')
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InProgressOrdersScreen()),
        );
        break;
      case 'ready':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReadyOrdersScreen()),
        );
        break;
      case 'completed':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CompletedOrdersScreen()),
        );
        break;
      default:
        context.pushNamed(RouteNames.orderList);
    }
  }

  // This method is already defined above

  void _navigateToPayments() {
    context.pushNamed(RouteNames.paymentCollection);
  }

  void _navigateToPaymentHistory() {
    context.pushNamed(RouteNames.paymentHistory);
  }

  /// Show deleted orders
  Future<void> _showDeletedOrders() async {
    try {
      final deletedOrders = await _dbService.getDeletedOrders();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Deleted Orders (${deletedOrders.length})',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          content: deletedOrders.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No deleted orders found',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                )
              : Container(
                  width: double.maxFinite,
                  height: 400,
                  child: ListView.builder(
                    itemCount: deletedOrders.length,
                    itemBuilder: (context, index) {
                      final order = deletedOrders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            'Order ${order.uniqueId}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status: ${order.status}',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                              Text(
                                'Amount: ₹${order.totalAmount.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              await _dbService.restoreOrder(order.uniqueId);
                              Navigator.of(context).pop();
                              await _loadOrderData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '↩️ Order ${order.uniqueId} has been restored',
                                    style: GoogleFonts.inter(fontSize: 14),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                            child: Text(
                              'Restore',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error loading deleted orders: $e',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Update orders to make them appear in payment collection screen
  Future<void> _updateOrdersForPaymentCollection() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Updating database and orders...'),
            ],
          ),
        ),
      );

      print('🔄 Starting order updates for payment collection...');
      
      // First, ensure database columns exist
      await _ensureDatabaseColumns();
      
      // Get all orders (handle case where is_deleted column might not exist)
      List<Map<String, Object?>> orders;
      try {
        orders = await _dbService.select('orders', where: 'is_deleted = 0');
      } catch (e) {
        // If is_deleted column doesn't exist, get all orders
        Logger.info('OrdersMainScreen', 'is_deleted column not found, getting all orders');
        orders = await _dbService.select('orders');
      }
      
      print('📊 Found ${orders.length} total orders');
      
      // Find orders that need updating (excluding the 2 reference orders)
      final excludeIds = ['ORDLQD6QU5', 'ORD70OC1ME'];
      final ordersToUpdate = orders.where((order) {
        final orderId = order['unique_id'] as String;
        final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
        final status = (order['status'] as String?)?.toLowerCase() ?? '';
        
        // Skip excluded orders and completed/delivered orders
        return !excludeIds.contains(orderId) && 
               status != 'completed' && 
               status != 'delivered' &&
               totalAmount > 0;
      }).toList();
      
      print('🎯 Found ${ordersToUpdate.length} orders to update');
      
      int updateCount = 0;
      for (int i = 0; i < ordersToUpdate.length && i < 12; i++) {
        final order = ordersToUpdate[i];
        final orderId = order['unique_id'] as String;
        final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
        
        // Calculate new advance payment (varying percentages)
        double paymentPercentage;
        switch (i % 5) {
          case 0: paymentPercentage = 0.30; break; // 30% paid
          case 1: paymentPercentage = 0.50; break; // 50% paid  
          case 2: paymentPercentage = 0.70; break; // 70% paid
          case 3: paymentPercentage = 0.40; break; // 40% paid
          case 4: paymentPercentage = 0.60; break; // 60% paid
          default: paymentPercentage = 0.50; break;
        }
        
        final newAdvancePaid = totalAmount * paymentPercentage;
        final newBalanceAmount = totalAmount - newAdvancePaid;
        
        // Update the order (handle missing payment_status column)
        Map<String, dynamic> updateData = {
          'advance_paid': newAdvancePaid,
          'balance_amount': newBalanceAmount,
          'updated_at': DateTime.now().toIso8601String(),
          'show_in_payment_collection': 1, // Set flag to show in payment collection
        };
        
        // Only add payment_status if the column exists
        try {
          final db = await _dbService.database;
          final columns = await db.rawQuery("PRAGMA table_info(orders)");
          final hasPaymentStatus = columns.any((col) => col['name'] == 'payment_status');
          
          if (hasPaymentStatus) {
            updateData['payment_status'] = newAdvancePaid > 0 ? 'partial' : 'pending';
          }
        } catch (e) {
          Logger.info('OrdersMainScreen', 'Could not check payment_status column, skipping');
        }
        
        await _dbService.update(
          'orders',
          updateData,
          where: 'unique_id = ?',
          whereArgs: [orderId],
        );
        
        print('✅ Updated $orderId: Total=₹${totalAmount.toStringAsFixed(0)}, '
              'Paid=₹${newAdvancePaid.toStringAsFixed(0)} (${(paymentPercentage*100).toStringAsFixed(0)}%), '
              'Balance=₹${newBalanceAmount.toStringAsFixed(0)}');
        
        updateCount++;
      }

      Navigator.of(context).pop(); // Close loading dialog
      
      // Refresh data
      await _loadOrderData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Updated $updateCount orders for payment collection!\n'
                         'Database columns added successfully.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      print('🎉 Update complete! Updated $updateCount orders');
      print('💡 Kept ORDLQD6QU5 and ORD70OC1ME unchanged as requested');
      
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error updating orders: $e');
    }
  }

  /// Ensure database has required columns
  Future<void> _ensureDatabaseColumns() async {
    try {
      final db = await _dbService.database;
      
      // Check and add missing columns to orders table
      final orderColumns = await db.rawQuery("PRAGMA table_info(orders)");
      final hasIsDeleted = orderColumns.any((col) => col['name'] == 'is_deleted');
      final hasPaymentStatus = orderColumns.any((col) => col['name'] == 'payment_status');
      
      if (!hasIsDeleted) {
        await db.execute('ALTER TABLE orders ADD COLUMN is_deleted INTEGER DEFAULT 0');
        Logger.info('OrdersMainScreen', 'Added is_deleted column to orders table');
      }
      
      if (!hasPaymentStatus) {
        await db.execute('ALTER TABLE orders ADD COLUMN payment_status TEXT DEFAULT "pending"');
        Logger.info('OrdersMainScreen', 'Added payment_status column to orders table');
      }
      
      // Check and add is_deleted to payment table
      final paymentColumns = await db.rawQuery("PRAGMA table_info(payment)");
      final hasPaymentIsDeleted = paymentColumns.any((col) => col['name'] == 'is_deleted');
      
      if (!hasPaymentIsDeleted) {
        await db.execute('ALTER TABLE payment ADD COLUMN is_deleted INTEGER DEFAULT 0');
        Logger.info('OrdersMainScreen', 'Added is_deleted column to payment table');
      }
      
      // Check and add is_deleted to customer table
      final customerColumns = await db.rawQuery("PRAGMA table_info(customer)");
      final hasCustomerIsDeleted = customerColumns.any((col) => col['name'] == 'is_deleted');
      
      if (!hasCustomerIsDeleted) {
        await db.execute('ALTER TABLE customer ADD COLUMN is_deleted INTEGER DEFAULT 0');
        Logger.info('OrdersMainScreen', 'Added is_deleted column to customer table');
      }
      
      Logger.info('OrdersMainScreen', 'Database column check completed successfully');
    } catch (e) {
      Logger.error('OrdersMainScreen', 'Failed to ensure database columns', error: e);
    }
  }

  /// Insert test data for all order statuses
  Future<void> _insertTestData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Inserting test data...'),
            ],
          ),
        ),
      );

      const String tailorId = 'admin1@gmail.com';
      
      // Create test customers first
      final customers = [
        {'name': 'Raj Kumar', 'phone': '9876543210', 'address': '123 MG Road, Bangalore'},
        {'name': 'Priya Sharma', 'phone': '9876543211', 'address': '456 Brigade Road, Bangalore'},
        {'name': 'Arjun Singh', 'phone': '9876543212', 'address': '789 Commercial Street, Bangalore'},
      ];

      List<Customer> insertedCustomers = [];
      for (var customerData in customers) {
        final customer = Customer.create(
          tailorId: tailorId,
          name: customerData['name']!,
          phone: customerData['phone']!,
          address: customerData['address']!,
          gender: 'Male',
        );
        
        try {
          await _dbService.insertCustomerWithoutForeignKeyCheck(customer);
          insertedCustomers.add(customer);
        } catch (e) {
          print('Customer already exists: ${customer.name}');
          // Customer might already exist, try to get it
          final existingCustomers = await _dbService.select('customer', 
            where: 'name = ?', whereArgs: [customer.name]);
          if (existingCustomers.isNotEmpty) {
            insertedCustomers.add(Customer.fromMap(existingCustomers.first));
          }
        }
      }

      // Order statuses to test
      final statuses = ['pending', 'cutting', 'stitching', 'in_progress', 'ready', 'completed', 'delivered'];
      final dressTypes = ['Shirt', 'Pant', 'Kurta', 'Dress', 'Suit', 'Blouse', 'Lehenga'];
      
      // Insert 3 orders for each status
      int orderIndex = 0;
      for (String status in statuses) {
        for (int i = 0; i < 3; i++) {
          final customer = insertedCustomers[i % insertedCustomers.length];
          final dressType = dressTypes[orderIndex % dressTypes.length];
          
          double totalAmount = 2000.0 + (orderIndex * 150);
          double advance = _getAdvanceForStatus(status, totalAmount);
          
          final order = Order.create(
            customerId: customer.uniqueId,
            tailorId: tailorId,
            serviceType: dressType,
            status: status,
            deliveryDate: _getDeliveryDateForStatus(status),
            notes: 'Test order - $status status for $dressType',
            totalAmount: totalAmount,
            advancePaid: advance,
            balanceAmount: totalAmount - advance,
            measurements: _getSampleMeasurements(dressType),
          );
          
          try {
            await _dbService.insertOrderWithoutTailorForeignKeyCheck(order);
            orderIndex++;
          } catch (e) {
            print('Failed to insert order: $e');
          }
        }
      }

      Navigator.of(context).pop(); // Close loading dialog
      
      // Refresh data
      await _loadOrderData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Inserted ${statuses.length * 3} test orders!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error inserting test data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _getAdvanceForStatus(String status, double totalAmount) {
    switch (status) {
      case 'pending':
        return totalAmount * 0.3;
      case 'cutting':
      case 'stitching':
        return totalAmount * 0.5;
      case 'in_progress':
        return totalAmount * 0.7;
      case 'ready':
        return totalAmount * 0.8;
      case 'completed':
      case 'delivered':
        return totalAmount;
      default:
        return totalAmount * 0.3;
    }
  }

  DateTime _getDeliveryDateForStatus(String status) {
    final now = DateTime.now();
    switch (status) {
      case 'pending':
        return now.add(Duration(days: 10));
      case 'cutting':
        return now.add(Duration(days: 8));
      case 'stitching':
        return now.add(Duration(days: 6));
      case 'in_progress':
        return now.add(Duration(days: 4));
      case 'ready':
        return now.add(Duration(days: 2));
      case 'completed':
        return now.subtract(Duration(days: 1));
      case 'delivered':
        return now.subtract(Duration(days: 3));
      default:
        return now.add(Duration(days: 7));
    }
  }

  Map<String, double> _getSampleMeasurements(String dressType) {
    switch (dressType.toLowerCase()) {
      case 'shirt':
        return {'chest': 40.0, 'waist': 36.0, 'sleeve_length': 24.0, 'shoulder': 16.0, 'neck': 15.0};
      case 'pant':
        return {'waist': 32.0, 'length': 40.0, 'hip': 38.0, 'thigh': 22.0, 'bottom': 14.0};
      case 'suit':
        return {'chest': 42.0, 'waist': 36.0, 'sleeve_length': 25.0, 'shoulder': 17.0, 'pant_waist': 34.0, 'pant_length': 42.0};
      case 'kurta':
        return {'chest': 44.0, 'length': 42.0, 'sleeve_length': 22.0, 'shoulder': 18.0, 'neck': 16.0};
      case 'dress':
        return {'bust': 36.0, 'waist': 30.0, 'hip': 38.0, 'length': 40.0, 'sleeve_length': 20.0};
      case 'blouse':
        return {'bust': 34.0, 'waist': 28.0, 'sleeve_length': 12.0, 'shoulder': 13.0, 'neck': 13.0};
      case 'lehenga':
        return {'bust': 36.0, 'waist': 28.0, 'hip': 40.0, 'skirt_length': 42.0, 'blouse_length': 14.0};
      default:
        return {'chest': 38.0, 'waist': 34.0, 'length': 38.0};
    }
  }
}