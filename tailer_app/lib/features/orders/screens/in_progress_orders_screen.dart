import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/widgets/custom_bottom_navigation.dart';
import '../widgets/sub_header.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import '../../../data/services/local_db_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/order_model.dart';
import '../../../core/utils/logger.dart';
import 'order_detail_screen.dart';

class InProgressOrdersScreen extends StatefulWidget {
  const InProgressOrdersScreen({Key? key}) : super(key: key);

  @override
  State<InProgressOrdersScreen> createState() => _InProgressOrdersScreenState();
}

class _InProgressOrdersScreenState extends State<InProgressOrdersScreen> with NavigationMixin {
  int _currentNavIndex = 2; // Orders is index 2
  late SimpleLocaleProvider _localeProvider;
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Order> _allInProgressOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _tailorId;
  
  // Statistics
  int _cuttingOrders = 0;
  int _stitchingOrders = 0;
  int _generalInProgressOrders = 0;
  double _totalInProgressValue = 0.0;

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    await _authService.initialize();
    if (_authService.currentUser != null) {
      setState(() {
        _tailorId = _authService.currentUser!.email;
      });
      _loadInProgressOrders();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInProgressOrders() async {
    if (_tailorId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final allOrders = await _dbService.getOrders(tailorId: _tailorId);
      _allInProgressOrders = allOrders.where((order) => 
        !order.isDeleted && 
        (order.status.toLowerCase() == 'in_progress' || 
         order.status.toLowerCase() == 'cutting' || 
         order.status.toLowerCase() == 'stitching')
      ).toList();
      
      _filteredOrders = List.from(_allInProgressOrders);
      _calculateStatistics();
      
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

  void _calculateStatistics() {
    _cuttingOrders = _allInProgressOrders.where((order) => 
        order.status.toLowerCase() == 'cutting').length;
    _stitchingOrders = _allInProgressOrders.where((order) => 
        order.status.toLowerCase() == 'stitching').length;
    _generalInProgressOrders = _allInProgressOrders.where((order) => 
        order.status.toLowerCase() == 'in_progress').length;
    _totalInProgressValue = _allInProgressOrders.fold(0.0, (sum, order) => 
        sum + order.totalAmount);
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
          backgroundColor: AppColors.background,
          appBar: DashboardHeader(
            title: locale.t('inProgressOrders'),
            backgroundColor: const Color(0xFF8B5CF6),
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
                  Color(0xFF8B5CF6),
                  Color(0xFF3B82F6),
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
                          'Cutting',
                          _cuttingOrders.toString(),
                          Icons.content_cut,
                          Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Stitching',
                          _stitchingOrders.toString(),
                          Icons.polymer,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Total Value',
                          '₹${_totalInProgressValue.toStringAsFixed(0)}',
                          Icons.currency_rupee,
                          Colors.green,
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
                        hintText: locale.t('searchInProgressOrders'),
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

  Widget _buildModernOrderCard(Order order, AppLocalizations locale) {
    final statusColor = _getStatusColor(order.status);
    final progress = _getProgress(order.status);
    final bool isUrgent = order.deliveryDate.difference(DateTime.now()).inDays <= 3;
    
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
        border: isUrgent
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 2)
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
                      if (isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'URGENT',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
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
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
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
                          color: Colors.grey[600],
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
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
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
              
              // Amount and Date Row
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
                          Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${locale.t('delivery')}: ${_formatDate(order.deliveryDate)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'cutting':
        return Icons.content_cut;
      case 'stitching':
        return Icons.polymer;
      case 'in_progress':
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
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