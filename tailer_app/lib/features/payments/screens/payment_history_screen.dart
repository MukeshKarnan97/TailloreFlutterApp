import 'package:flutter/material.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/enums/payment_method.dart';
import '../../../data/services/local_db_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/logger.dart';
import '../../../widgets/custom_header.dart';
import '../../../widgets/custom_bottom_navigation.dart';
import '../../../core/mixins/navigation_mixin.dart';
import '../../../core/translations/app_localizations.dart';
import '../../../core/providers/simple_locale_provider.dart';
import '../../orders/widgets/sub_header.dart';
import '../../../routes/route_names.dart';
import 'package:tailer_app/core/constants/app_constants.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String? orderId;
  
  const PaymentHistoryScreen({super.key, this.orderId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> with NavigationMixin {
  int _currentNavIndex = 2; // Orders section
  late SimpleLocaleProvider _localeProvider;
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  List<Payment> _allPayments = [];
  List<Payment> _filteredPayments = [];
  bool _isLoading = true;
  PaymentMethod? _selectedMethodFilter;

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _loadPayments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPayments();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        context.goNamed(RouteNames.orders);
        break;
      case 3:
        context.goNamed(RouteNames.settings);
        break;
    }
  }

  Future<void> _loadPayments() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure database is ready
      await _dbService.database;
      
      // Get current tailor's email for filtering
      final currentTailor = _authService.currentUser;
      if (currentTailor == null) {
        Logger.warning('PaymentHistoryScreen', 'No tailor logged in');
        setState(() {
          _allPayments = [];
          _filteredPayments = [];
          _isLoading = false;
        });
        return;
      }
      
      final tailorId = currentTailor.email;
      Logger.info('PaymentHistoryScreen', 'Loading payments for tailor: $tailorId');
      
      List<Payment> payments;
      if (widget.orderId != null) {
        Logger.debug('PaymentHistoryScreen', 'Loading payments for order: ${widget.orderId}');
        payments = await _dbService.getPaymentsByOrderId(widget.orderId!);
      } else {
        Logger.debug('PaymentHistoryScreen', 'Loading all payments for current tailor');
        payments = await _dbService.getPayments(tailorId: tailorId);
      }
      
      Logger.info('PaymentHistoryScreen', 'Loaded ${payments.length} payments');
      
      // Debug: Log each payment for troubleshooting
      for (final payment in payments) {
        Logger.debug('PaymentHistoryScreen', 
          'Payment ${payment.uniqueId}: Order=${payment.orderId}, Amount=₹${payment.amount}, Method=${payment.method.displayName}, Date=${payment.paidOn}');
      }
      
      if (mounted) {
        _allPayments = payments;
        _filteredPayments = List.from(_allPayments);
        _applyFilters(); // Apply any existing filters
        
        setState(() {
          _isLoading = false;
        });
        
        // Show success message for manual refresh
        if (payments.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded ${payments.length} payments'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      Logger.error('PaymentHistoryScreen', 'Failed to load payments', 
                   error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payments: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      final searchQuery = _searchController.text.toLowerCase();
      _filteredPayments = _allPayments.where((payment) {
        final matchesSearch = payment.orderId.toLowerCase().contains(searchQuery) ||
                             payment.notes.toLowerCase().contains(searchQuery);
        final matchesMethod = _selectedMethodFilter == null || 
                             payment.method == _selectedMethodFilter;
        return matchesSearch && matchesMethod;
      }).toList();
    });
  }

  double get _totalAmount {
    return _filteredPayments.fold(0.0, (sum, payment) => sum + payment.amount);
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
          backgroundColor: AppColors.background,
          appBar: DashboardHeader(
            title: widget.orderId != null ? 'Order Payments' : 'Payment History',
            backgroundColor: AppColors.primary,
            notificationCount: 0,
            onBackPressed: () {
              if (widget.orderId != null) {
                Navigator.of(context).pop();
              } else {
                context.goNamed(RouteNames.orders);
              }
            },
            onNotificationTap: () {
              showNavigationMessage(context, locale.t('notifications'));
            },
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    // Sub-header
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SubHeaderStyles.feature(
                              icon: Icons.receipt_long,
                              title: 'Payment Records',
                              subtitle: 'All Transactions • Payment Methods • History',
                              action: Container(
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
                                      Icons.payments,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_filteredPayments.length}',
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
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),

                    // Search and Filter Bar
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.panel,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Search Bar
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search payments...',
                                hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
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
                                  borderSide: BorderSide(color: AppColors.primary),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Method Filter
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('All', null),
                                  const SizedBox(width: 8),
                                  ...PaymentMethod.values.map((method) => 
                                    _buildFilterChip(method.displayName, method)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Summary Card
                    if (_filteredPayments.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Payments',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${_totalAmount.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: AppColors.success,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Payments List
                    if (_filteredPayments.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildPaymentCard(_filteredPayments[index]);
                            },
                            childCount: _filteredPayments.length,
                          ),
                        ),
                      ),
                    
                    // Bottom padding
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
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

  Widget _buildFilterChip(String label, PaymentMethod? method) {
    final isSelected = _selectedMethodFilter == method;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedMethodFilter = selected ? method : null;
          });
          _applyFilters();
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(
          color: isSelected 
              ? AppColors.primary
              : AppColors.textSecondary,
          fontWeight: isSelected 
              ? FontWeight.w600
              : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Payments Found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.orderId != null 
                ? 'No payments found for this order'
                : 'No payment transactions found',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
            label: Text(
              'Refresh',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Navigate to payment collection screen
              context.push('/payments/collection');
            },
            child: Text(
              'Collect Payment',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment #${payment.uniqueId}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${payment.orderId}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      payment.getFormattedAmount(),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getMethodColor(payment.method).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payment.method.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getMethodColor(payment.method),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Date and Notes
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  payment.getFormattedDateTime(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            
            if (payment.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      payment.notes,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            if (payment.transactionId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ref: ${payment.transactionId}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Colors.green;
      case PaymentMethod.card:
        return Colors.blue;
      case PaymentMethod.upi:
        return Colors.purple;
      case PaymentMethod.bank:
        return Colors.orange;
    }
  }
}