import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import '../../../data/services/local_db_service.dart';
import '../../../data/models/order_model.dart';
import '../../../core/utils/logger.dart';
import 'order_detail_screen.dart';

class CompletedOrdersScreen extends StatefulWidget {
  const CompletedOrdersScreen({Key? key}) : super(key: key);

  @override
  State<CompletedOrdersScreen> createState() => _CompletedOrdersScreenState();
}

class _CompletedOrdersScreenState extends State<CompletedOrdersScreen> {
  late SimpleLocaleProvider _localeProvider;
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Order> _allCompletedOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _loadCompletedOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompletedOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allOrders = await _dbService.getOrders();
      _allCompletedOrders = allOrders.where((order) => 
        !order.isDeleted && 
        (order.status.toLowerCase() == 'completed' || 
         order.status.toLowerCase() == 'delivered')
      ).toList();
      
      // Sort by delivery date (most recent first)
      _allCompletedOrders.sort((a, b) => b.deliveryDate.compareTo(a.deliveryDate));
      
      _filteredOrders = List.from(_allCompletedOrders);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Logger.error('CompletedOrdersScreen', 'Failed to load completed orders', 
                   error: e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredOrders = List.from(_allCompletedOrders);
      } else {
        _filteredOrders = _allCompletedOrders.where((order) {
          return order.uniqueId.toLowerCase().contains(query.toLowerCase()) ||
                 order.customerId.toLowerCase().contains(query.toLowerCase()) ||
                 order.serviceType.toLowerCase().contains(query.toLowerCase()) ||
                 order.notes.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _navigateToOrderDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: order),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade700;
      case 'completed':
      default:
        return Colors.green;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'ready':
        return Icons.inventory;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: CustomHeader(
            title: locale.t('completedOrders'),
            backgroundColor: Colors.green,
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadCompletedOrders,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'sort_date':
                      _sortByDate();
                      break;
                    case 'sort_customer':
                      _sortByCustomer();
                      break;
                    case 'filter_this_month':
                      _filterThisMonth();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'sort_date',
                    child: Row(
                      children: [
                        const Icon(Icons.sort_by_alpha),
                        const SizedBox(width: 8),
                        Text(locale.t('sortByDate')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'sort_customer',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Text(locale.t('sortByCustomer')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'filter_this_month',
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month),
                        const SizedBox(width: 8),
                        Text(locale.t('thisMonthOnly')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: locale.t('searchCompletedOrders'),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _performSearch,
                ),
              ),

              // Statistics Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.green.shade50,
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_filteredOrders.length} ${locale.t('completedOrders')}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const Spacer(),
                    if (_filteredOrders.isNotEmpty) ...[
                      Text(
                        '₹${_filteredOrders.fold(0.0, (sum, order) => sum + order.totalAmount).toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        locale.t('totalRevenue'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Orders List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      )
                    : _filteredOrders.isEmpty
                        ? _buildEmptyState(locale)
                        : RefreshIndicator(
                            onRefresh: _loadCompletedOrders,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = _filteredOrders[index];
                                return _buildCompletedOrderCard(order, locale);
                              },
                            ),
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _generateReport,
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.summarize),
            label: Text(locale.t('generateReport')),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? locale.t('noCompletedOrders')
                : locale.t('noOrdersFound'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? locale.t('noOrdersCompletedYet')
                : locale.t('tryDifferentSearch'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
              icon: const Icon(Icons.clear),
              label: Text(locale.t('clearSearch')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedOrderCard(Order order, AppLocalizations locale) {
    final statusColor = _getStatusColor(order.status);
    final isOverdue = order.deliveryDate.isBefore(DateTime.now()) && 
                     order.status.toLowerCase() != 'delivered';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToOrderDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.uniqueId,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(order.status),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusDisplayName(order.status),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isOverdue) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber, size: 14, color: Colors.red.shade600),
                      const SizedBox(width: 4),
                      Text(
                        locale.t('deliveryOverdue'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Order Details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      locale.t('customer'),
                      order.customerId,
                      Icons.person_outline,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      locale.t('service'),
                      order.serviceType,
                      Icons.design_services_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      locale.t('deliveryDate'),
                      _formatDate(order.deliveryDate),
                      Icons.schedule_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      locale.t('amount'),
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      Icons.currency_rupee_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Payment Status
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentStatus(order, locale),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      locale.t('completed'),
                      _formatCompletionDate(order.updatedAt),
                      Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToOrderDetail(order),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: Text(
                        locale.t('viewDetails'),
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: statusColor,
                        side: BorderSide(color: statusColor.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (order.status.toLowerCase() != 'delivered')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsDelivered(order),
                        icon: const Icon(Icons.local_shipping_outlined, size: 16),
                        label: Text(
                          locale.t('markDelivered'),
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _generateOrderReport(order),
                        icon: const Icon(Icons.receipt_outlined, size: 16),
                        label: Text(
                          locale.t('receipt'),
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatus(Order order, AppLocalizations locale) {
    final isPaid = order.advancePaid >= order.totalAmount;
    final paymentColor = isPaid ? Colors.green : Colors.orange;
    final paymentText = isPaid ? locale.t('paid') : locale.t('pending');
    
    return Row(
      children: [
        Icon(Icons.payment_outlined, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.t('payment'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: paymentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    paymentText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: paymentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatCompletionDate(DateTime date) {
    final difference = DateTime.now().difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${difference}d ago';
    }
  }

  void _sortByDate() {
    setState(() {
      _filteredOrders.sort((a, b) => b.deliveryDate.compareTo(a.deliveryDate));
    });
  }

  void _sortByCustomer() {
    setState(() {
      _filteredOrders.sort((a, b) => a.customerId.compareTo(b.customerId));
    });
  }

  void _filterThisMonth() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    
    setState(() {
      _filteredOrders = _allCompletedOrders.where((order) =>
          order.deliveryDate.isAfter(thisMonth)).toList();
    });
  }

  Future<void> _markAsDelivered(Order order) async {
    try {
      await _dbService.updateOrderStatus(order.uniqueId, 'delivered');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order marked as delivered'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadCompletedOrders(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _generateOrderReport(Order order) {
    // TODO: Implement order report generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order receipt generation - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _generateReport() {
    // TODO: Implement comprehensive report generation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: const Text('Choose report type:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Monthly Report - Coming Soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Monthly Report'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Customer Report - Coming Soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Customer Report'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}