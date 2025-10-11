import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/simple_locale_provider.dart';
import '../../../core/translations/app_localizations.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/local_db_service.dart';
import '../../../core/utils/logger.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/custom_header.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/order_card.dart';
import '../widgets/sub_header.dart';
import '../../../widgets/custom_bottom_navigation.dart';
import '../../../core/mixins/navigation_mixin.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with NavigationMixin {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  final TextEditingController _searchController = TextEditingController();
  
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _currentNavIndex = 2; // Orders tab

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Don't dispose singleton _localeProvider
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final orders = await _dbService.getOrders();
      
      if (mounted) {
        setState(() {
          _orders = orders;
          _filteredOrders = orders;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      Logger.error('OrderListScreen', 'Failed to load orders', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${locale.t('failedToLoad')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterOrders(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredOrders = _orders;
      } else {
        _filteredOrders = _orders.where((order) {
          return order.uniqueId.toLowerCase().contains(query.toLowerCase()) ||
                 order.serviceType.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _navigateToOrderDetails(Order order) {
    context.pushNamed(
      RouteNames.orderDetails,
      extra: {'order': order.toMap()},
    );
  }

  void _navigateToAddOrder() {
    context.pushNamed(RouteNames.addOrder);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: DashboardHeader(
            title: locale.t('orderList'),
            backgroundColor: AppColors.primary,
            notificationCount: 3,
            onBackPressed: () {
              context.pop();
            },
            onNotificationTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(locale.t('notifications'))),
              );
            },
          ),
          body: Column(
            children: [
              const SizedBox(height: 15),
              // Sub-header
              _buildSubHeader(locale),
              
              const SizedBox(height: 20),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearchBar(locale),
              ),
              
              const SizedBox(height: 20),
              
              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${locale.t('totalOrdersCount')}: ${_orders.length}',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Orders List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(AppConstants.primaryTeal),
                          ),
                        ),
                      )
                    : _filteredOrders.isEmpty
                        ? _buildEmptyState(locale)
                        : RefreshIndicator(
                            onRefresh: _loadOrders,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = _filteredOrders[index];
                                return OrderCard(
                                  order: order,
                                  onTap: () => _navigateToOrderDetails(order),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _navigateToAddOrder,
            backgroundColor: const Color(AppConstants.primaryTeal),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(
              locale.t('addOrder'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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

  Widget _buildSubHeader(AppLocalizations locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SubHeaderStyles.feature(
        icon: Icons.list_alt,
        title: locale.t('orderList'),
        subtitle: '${locale.t('viewAllOrders')} • ${locale.t('trackOrders')} • ${locale.t('searchOrders')}',
        action: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2,
                  size: 12,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_orders.length} ${locale.t('orders')}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
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
          _filterOrders(value);
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations locale) {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                locale.t('noOrdersFoundMessage'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                locale.t('trySearchingDifferentTerm'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              locale.t('noOrdersYet'),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              locale.t('addFirstOrder'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryTeal),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                locale.t('addOrder'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
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
    );
  }
}