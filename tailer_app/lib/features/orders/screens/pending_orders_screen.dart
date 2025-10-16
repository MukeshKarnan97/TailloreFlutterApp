import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import '../widgets/sub_header.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import '../../../data/services/local_db_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/order_model.dart';
import '../../../core/utils/logger.dart';
import 'order_detail_screen.dart';

class PendingOrdersScreen extends StatefulWidget {
  const PendingOrdersScreen({super.key});

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  late SimpleLocaleProvider _localeProvider;
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Order> _allPendingOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String? _tailorId;
  
  // Statistics
  double _totalPendingValue = 0.0;
  double _totalAdvanceReceived = 0.0;
  int _highPriorityOrders = 0;
  int _overdueOrders = 0;

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
      _loadPendingOrders();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingOrders() async {
    if (_tailorId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final allOrders = await _dbService.getOrders(tailorId: _tailorId);
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
    
    final now = DateTime.now();
    _highPriorityOrders = _allPendingOrders.where((order) {
      final daysDiff = order.deliveryDate.difference(now).inDays;
      return daysDiff <= 3; // High priority if delivery in 3 days or less
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
          appBar: DashboardHeader(
            title: '${locale.t('pendingOrders')} (${_filteredOrders.length})',
            backgroundColor: Colors.orange,
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
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Sub-header
                  SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // safe margins
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSubHeader(locale),
        ),
      ],
    ),
  ),
),

                  
                  // Welcome Section with Stats
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      color: Colors.orange,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
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
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.95),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Quick Stats Row
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
                                  Colors.amber.shade800,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Advance',
                                  '₹${(_totalAdvanceReceived / 1000).toStringAsFixed(1)}k',
                                  Icons.payment,
                                  Colors.green.shade100,
                                  Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Container(
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
                            hintText: '${locale.t('searchOrders')}...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch('');
                                  },
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                )
                              : null,
                            border: InputBorder.none,
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          onChanged: _performSearch,
                        ),
                      ),
                    ),
                  ),

                  // Orders List or Empty State
                  if (_filteredOrders.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(locale),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final order = _filteredOrders[index];
                            return _buildEnhancedOrderCard(order, locale);
                          },
                          childCount: _filteredOrders.length,
                        ),
                      ),
                    ),
                ],
              ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.85),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToOrderDetail(order),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.pending_actions,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.uniqueId,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${order.serviceType} • Customer: ${order.customerId}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isOverdue ? 'OVERDUE' : isHighPriority ? 'HIGH' : 'NORMAL',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: priorityColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Delivery: ${order.deliveryDate.toString().substring(0, 10)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.payment, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Advance: ₹${order.advancePaid.toStringAsFixed(0)} • Balance: ₹${order.balanceAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey.shade400,
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
          Icon(
            Icons.pending_actions,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty 
              ? 'No orders found for "${_searchController.text}"'
              : 'No pending orders found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
              ? 'Try adjusting your search terms'
              : 'All orders are either in progress or completed',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
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
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubHeader(AppLocalizations locale) {
    return SubHeaderStyles.pending(
      title: '${locale.t('pendingOrders')} (${_filteredOrders.length})',
      subtitle: '${locale.t('awaitingAction')} • ${locale.t('review')} • ${locale.t('process')}',
      action: _filteredOrders.length > 5 
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'High Priority',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          )
        : null,
    );
  }
}