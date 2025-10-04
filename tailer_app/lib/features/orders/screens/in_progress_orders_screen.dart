import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import '../../../data/services/local_db_service.dart';
import '../../../data/models/order_model.dart';
import '../../../core/utils/logger.dart';
import 'order_detail_screen.dart';

class InProgressOrdersScreen extends StatefulWidget {
  const InProgressOrdersScreen({Key? key}) : super(key: key);

  @override
  State<InProgressOrdersScreen> createState() => _InProgressOrdersScreenState();
}

class _InProgressOrdersScreenState extends State<InProgressOrdersScreen> {
  late SimpleLocaleProvider _localeProvider;
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Order> _allInProgressOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _loadInProgressOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInProgressOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allOrders = await _dbService.getOrders();
      _allInProgressOrders = allOrders.where((order) => 
        !order.isDeleted && 
        (order.status.toLowerCase() == 'in_progress' || 
         order.status.toLowerCase() == 'cutting' || 
         order.status.toLowerCase() == 'stitching')
      ).toList();
      
      _filteredOrders = List.from(_allInProgressOrders);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Logger.error('InProgressOrdersScreen', 'Failed to load in progress orders', 
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
        _filteredOrders = List.from(_allInProgressOrders);
      } else {
        _filteredOrders = _allInProgressOrders.where((order) {
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
      case 'cutting':
        return Colors.indigo;
      case 'stitching':
        return Colors.purple;
      case 'in_progress':
      default:
        return Colors.blue;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'cutting':
        return 'Cutting';
      case 'stitching':
        return 'Stitching';
      case 'in_progress':
        return 'In Progress';
      default:
        return status;
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
            title: locale.t('inProgressOrders'),
            backgroundColor: Colors.blue,
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadInProgressOrders,
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
                    hintText: locale.t('searchInProgressOrders'),
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
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Icon(Icons.work_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_filteredOrders.length} ${locale.t('ordersInProgress')}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
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
                        locale.t('totalValue'),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    : _filteredOrders.isEmpty
                        ? _buildEmptyState(locale)
                        : RefreshIndicator(
                            onRefresh: _loadInProgressOrders,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = _filteredOrders[index];
                                return _buildInProgressOrderCard(order, locale);
                              },
                            ),
                          ),
              ),
            ],
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
            Icons.work_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? locale.t('noInProgressOrders')
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
                ? locale.t('allOrdersCompleted')
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInProgressOrderCard(Order order, AppLocalizations locale) {
    final statusColor = _getStatusColor(order.status);
    final progress = _getProgress(order.status);
    
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
                    child: Text(
                      _getStatusDisplayName(order.status),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        locale.t('progress'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ],
              ),

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
                      locale.t('delivery'),
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
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(order),
                      icon: const Icon(Icons.update_outlined, size: 16),
                      label: Text(
                        locale.t('updateStatus'),
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
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

  double _getProgress(String status) {
    switch (status.toLowerCase()) {
      case 'cutting':
        return 0.33;
      case 'stitching':
        return 0.66;
      case 'in_progress':
        return 0.5;
      default:
        return 0.5;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      return '${difference}d left';
    }
  }

  void _updateOrderStatus(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Cutting'),
              onTap: () => _performStatusUpdate(order, 'cutting'),
            ),
            ListTile(
              title: Text('Stitching'),
              onTap: () => _performStatusUpdate(order, 'stitching'),
            ),
            ListTile(
              title: Text('Ready for Delivery'),
              onTap: () => _performStatusUpdate(order, 'completed'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _performStatusUpdate(Order order, String newStatus) async {
    Navigator.pop(context); // Close dialog
    
    try {
      await _dbService.updateOrderStatus(order.uniqueId, newStatus);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadInProgressOrders(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}