import 'package:flutter/material.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:tailer_app/widgets/custom_header.dart';
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
  
  // Statistics
  int _totalCompletedOrders = 0;
  double _totalCompletedValue = 0.0;
  int _recentlyCompleted = 0;
  double _averageOrderValue = 0.0;

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
      
      // Sort by completion date (most recent first)
      _allCompletedOrders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      _filteredOrders = List.from(_allCompletedOrders);
      _calculateStatistics();
      
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

  void _calculateStatistics() {
    _totalCompletedOrders = _allCompletedOrders.length;
    _totalCompletedValue = _allCompletedOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
    _averageOrderValue = _totalCompletedOrders > 0 ? _totalCompletedValue / _totalCompletedOrders : 0.0;
    
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    _recentlyCompleted = _allCompletedOrders.where((order) {
      return order.updatedAt.isAfter(weekAgo);
    }).length;
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
        return Colors.blue;
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
          backgroundColor: AppColors.background,
          appBar: DashboardHeader(
            title: locale.t('completedOrders'),
            backgroundColor: AppColors.success,
            notificationCount: 3,
            onBackPressed: () {
              Navigator.pop(context);
            },
            onNotificationTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(locale.t('notifications'))),
              );
            },
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4CAF50),
                  Color(0xFF2E7D32),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Statistics Cards
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        _buildStatCard(
                          'Completed',
                          _totalCompletedOrders.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'This Week',
                          _recentlyCompleted.toString(),
                          Icons.trending_up,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Avg Value',
                          '₹${_averageOrderValue.toStringAsFixed(0)}',
                          Icons.analytics,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Search Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _performSearch,
                      decoration: InputDecoration(
                        hintText: locale.t('searchCompletedOrders'),
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Orders List
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
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
                                      return _buildModernOrderCard(order, locale);
                                    },
                                  ),
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernOrderCard(Order order, AppLocalizations locale) {
    final statusColor = _getStatusColor(order.status);
    final bool isDelivered = order.status.toLowerCase() == 'delivered';
    final daysSinceCompletion = DateTime.now().difference(order.updatedAt).inDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDelivered
            ? Border.all(color: Colors.blue.withOpacity(0.3), width: 1)
            : null,
      ),
      child: InkWell(
        onTap: () => _navigateToOrderDetail(order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getStatusIcon(order.status),
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.uniqueId,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.serviceType,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusDisplayName(order.status),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (daysSinceCompletion <= 7)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            daysSinceCompletion == 0 
                                ? 'Today' 
                                : '${daysSinceCompletion}d ago',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Customer Info
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${locale.t('customer')}: ${order.customerId}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Amount and Completion Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.currency_rupee,
                          size: 16,
                          color: Colors.green[700],
                        ),
                        Text(
                          order.totalAmount.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Completed: ${_formatDate(order.updatedAt)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (isDelivered)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_shipping, size: 14, color: Colors.blue[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Delivered',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToOrderDetail(order),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: Text(
                    locale.t('viewDetails'),
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: statusColor,
                    side: BorderSide(color: statusColor.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? locale.t('noCompletedOrders')
                : locale.t('noOrdersFound'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Completed orders will appear here once orders are finished'
                : locale.t('tryDifferentSearch'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
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
}