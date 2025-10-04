import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import '../../../data/services/local_db_service.dart';
import '../../../data/models/order_model.dart';
import '../../../core/utils/logger.dart';
import 'order_detail_screen.dart';

class EnhancedPendingOrdersScreen extends StatefulWidget {
  const EnhancedPendingOrdersScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedPendingOrdersScreen> createState() => _EnhancedPendingOrdersScreenState();
}

class _EnhancedPendingOrdersScreenState extends State<EnhancedPendingOrdersScreen> {
  late SimpleLocaleProvider _localeProvider;
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Order> _allPendingOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  
  // Enhanced Statistics
  double _totalPendingValue = 0.0;
  double _totalAdvanceReceived = 0.0;
  int _highPriorityOrders = 0;
  int _overdueOrders = 0;
  double _averageOrderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _loadPendingOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allOrders = await _dbService.getOrders();
      _allPendingOrders = allOrders
          .where((order) => 
              order.status.toLowerCase() == 'pending' && 
              !order.isDeleted)
          .toList();
      
      _filteredOrders = List.from(_allPendingOrders);
      _calculateStatistics();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Logger.error('PendingOrdersScreen', 'Failed to load pending orders', 
                   error: e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics() {
    _totalPendingValue = _allPendingOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
    _totalAdvanceReceived = _allPendingOrders.fold(0.0, (sum, order) => sum + order.advancePaid);
    _averageOrderValue = _allPendingOrders.isNotEmpty ? _totalPendingValue / _allPendingOrders.length : 0.0;
    
    final now = DateTime.now();
    _highPriorityOrders = _allPendingOrders.where((order) {
      final daysDiff = order.deliveryDate.difference(now).inDays;
      return daysDiff <= 3 && daysDiff >= 0;
    }).length;
    
    _overdueOrders = _allPendingOrders.where((order) {
      return order.deliveryDate.isBefore(now);
    }).length;
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOrders = List.from(_allPendingOrders);
      } else {
        _filteredOrders = _allPendingOrders.where((order) =>
            order.customerId.toLowerCase().contains(query.toLowerCase()) ||
            order.uniqueId.toLowerCase().contains(query.toLowerCase()) ||
            order.serviceType.toLowerCase().contains(query.toLowerCase()) ||
            order.notes.toLowerCase().contains(query.toLowerCase())
        ).toList();
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: CustomHeader(
            title: locale.t('pendingOrders'),
            backgroundColor: Colors.orange,
            showBackButton: true,
            actions: [
              IconButton(
                onPressed: _loadPendingOrders,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    // Enhanced Welcome Section with Statistics
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade600, Colors.orange.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_filteredOrders.length} ${locale.t('pendingOrders')}',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Orders awaiting production start • Total Value: ₹${_totalPendingValue.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Enhanced Stats Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'High Priority',
                                  _highPriorityOrders.toString(),
                                  Icons.priority_high,
                                  Colors.red.shade100,
                                  Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Overdue',
                                  _overdueOrders.toString(),
                                  Icons.schedule,
                                  Colors.amber.shade100,
                                  Colors.amber.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Avg Value',
                                  '₹${_averageOrderValue.toStringAsFixed(0)}',
                                  Icons.trending_up,
                                  Colors.green.shade100,
                                  Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Enhanced Search Bar
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: '${locale.t('searchOrders')}...',
                            prefixIcon: Icon(Icons.search, color: Colors.orange.shade400),
                            suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch('');
                                  },
                                  icon: Icon(Icons.clear, color: Colors.grey.shade400),
                                )
                              : null,
                            border: InputBorder.none,
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                          onChanged: _performSearch,
                        ),
                      ),
                    ),

                    // Enhanced Orders List
                    Expanded(
                      child: _filteredOrders.isEmpty
                        ? _buildEmptyState(locale)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = _filteredOrders[index];
                              return _buildEnhancedOrderCard(order, locale);
                            },
                          ),
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOrderCard(Order order, AppLocalizations locale) {
    final now = DateTime.now();
    final daysDiff = order.deliveryDate.difference(now).inDays;
    final isOverdue = order.deliveryDate.isBefore(now);
    final isHighPriority = daysDiff <= 3 && daysDiff >= 0;
    
    Color priorityColor = isOverdue 
        ? Colors.red 
        : isHighPriority 
            ? Colors.orange 
            : Colors.green;

    String priorityLabel = isOverdue 
        ? 'OVERDUE' 
        : isHighPriority 
            ? 'URGENT' 
            : 'NORMAL';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToOrderDetail(order),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.pending_actions,
                        color: Colors.orange.shade600,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.uniqueId,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.serviceType} • ${order.customerId}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            priorityLabel,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: priorityColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Delivery: ${order.deliveryDate.toString().substring(0, 10)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${daysDiff >= 0 ? daysDiff : 'Overdue'} ${daysDiff >= 0 ? 'days left' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: priorityColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.payment, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Advance: ₹${order.advancePaid.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Pending: ₹${order.balanceAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pending_actions,
              size: 64,
              color: Colors.orange.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty 
              ? 'No orders found for "${_searchController.text}"'
              : 'No pending orders found',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _searchController.text.isNotEmpty
              ? 'Try adjusting your search terms'
              : 'All orders are either in progress or completed',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}