import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/mixins/navigation_mixin.dart';
import '../../../../widgets/custom_header.dart';
import '../../../../data/models/payment_analytics.dart';
import '../../../../data/services/payment_analytics_service.dart';
import '../../../../data/services/local_db_service.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../routes/route_names.dart';

/// Screen for displaying payment reports and analytics
class PaymentReportsScreen extends StatefulWidget {
  const PaymentReportsScreen({super.key});

  @override
  State<PaymentReportsScreen> createState() => _PaymentReportsScreenState();
}

class _PaymentReportsScreenState extends State<PaymentReportsScreen> with NavigationMixin {
  final PaymentAnalyticsService _analyticsService = PaymentAnalyticsService();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final AuthService _authService = AuthService();
  PaymentAnalytics? _currentAnalytics;
  List<Map<String, dynamic>> _ordersWithPayments = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week';
  final DateTime _selectedDate = DateTime.now();
  bool _showOrdersList = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _loadOrdersWithPayments();
  }

  Future<void> _loadOrdersWithPayments() async {
    try {
      // Get current tailor
      final currentTailor = _authService.currentUser;
      if (currentTailor == null) {
        Logger.warning('PaymentReportsScreen', 'No tailor logged in');
        setState(() {
          _ordersWithPayments = [];
        });
        return;
      }
      
      final tailorId = currentTailor.email;
      Logger.info('PaymentReportsScreen', 'Loading orders for tailor: $tailorId');
      
      // Get orders filtered by tailor
      final orders = await _dbService.select(
        'orders',
        where: 'tailor_id = ? AND is_deleted = 0',
        whereArgs: [tailorId],
        orderBy: 'created_at DESC',
      );
      
      List<Map<String, dynamic>> ordersWithPayments = [];
      
      for (final order in orders) {
        // Get payment details for each order
        final payments = await _dbService.select(
          'payment',
          where: 'order_id = ? AND is_deleted = 0',
          whereArgs: [order['unique_id']],
        );
        
        // Get customer details
        final customers = await _dbService.select(
          'customer',
          where: 'id = ?',
          whereArgs: [order['customer_id']],
        );
        
        final customer = customers.isNotEmpty ? customers.first : null;
        
        ordersWithPayments.add({
          'order': order,
          'payments': payments,
          'customer': customer,
          'total_paid': payments.fold<double>(0.0, (sum, payment) => 
            sum + (double.tryParse(payment['amount']?.toString() ?? '0') ?? 0.0)),
        });
      }
      
      setState(() {
        _ordersWithPayments = ordersWithPayments;
      });
    } catch (e) {
      Logger.error('PaymentReportsScreen', 'Failed to load orders with payments', error: e);
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() => _isLoading = true);

      final endDate = _selectedDate;
      DateTime startDate;

      switch (_selectedPeriod) {
        case 'day':
          startDate = DateTime(endDate.year, endDate.month, endDate.day);
          break;
        case 'week':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
          break;
        case 'year':
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }

      AnalyticsPeriod analyticsPeriod;
      switch (_selectedPeriod) {
        case 'day':
          analyticsPeriod = AnalyticsPeriod.today;
          break;
        case 'week':
          analyticsPeriod = AnalyticsPeriod.thisWeek;
          break;
        case 'month':
          analyticsPeriod = AnalyticsPeriod.thisMonth;
          break;
        case 'year':
          analyticsPeriod = AnalyticsPeriod.thisYear;
          break;
        default:
          analyticsPeriod = AnalyticsPeriod.thisWeek;
      }

      final analytics = await _analyticsService.generateAnalytics(
        period: analyticsPeriod,
        customStartDate: startDate,
        customEndDate: endDate,
      );

      setState(() {
        _currentAnalytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('PaymentReportsScreen', 'Failed to load analytics', error: e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardHeader(
        title: 'Payment Reports',
        backgroundColor: AppColors.secondary,
        notificationCount: 0,
        onBackPressed: () => context.goNamed(RouteNames.settings),
        onNotificationTap: () {
          showNavigationMessage(context, 'Notifications');
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.secondary.withOpacity(0.03),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondary,
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // Period Selector Header - Sticky
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildPeriodSelector()),
                            const SizedBox(width: 12),
                            _buildViewToggle(),
                          ],
                        ),
                      ),
                    ),
                    
                    // Content Area
                    _showOrdersList
                        ? _buildOrdersListSliver()
                        : _buildAnalyticsSliver(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          isDense: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.secondary),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          dropdownColor: AppColors.background,
          items: [
            DropdownMenuItem(value: 'day', child: Text('Today')),
            DropdownMenuItem(value: 'week', child: Text('This Week')),
            DropdownMenuItem(value: 'month', child: Text('This Month')),
            DropdownMenuItem(value: 'year', child: Text('This Year')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedPeriod = value);
              _loadAnalytics();
            }
          },
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          _showOrdersList ? Icons.analytics : Icons.list,
          color: AppColors.secondary,
        ),
        onPressed: () {
          setState(() {
            _showOrdersList = !_showOrdersList;
          });
        },
        tooltip: _showOrdersList ? 'Show Analytics' : 'Show Orders List',
      ),
    );
  }

  // Sliver version for better scrolling
  Widget _buildOrdersListSliver() {
    if (_ordersWithPayments.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No orders with payments found',
                style: GoogleFonts.inter(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final orderData = _ordersWithPayments[index];
            final order = orderData['order'] as Map<String, dynamic>;
            final payments = orderData['payments'] as List<Map<String, dynamic>>;
            final customer = orderData['customer'] as Map<String, dynamic>?;
            final totalPaid = orderData['total_paid'] as double;
            final totalAmount = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order['id']?.toString().substring(0, 8) ?? 'N/A'}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Chip(
                          label: Text(
                            order['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                            style: GoogleFonts.inter(fontSize: 11),
                          ),
                          backgroundColor: _getStatusColor(order['status']?.toString() ?? 'unknown'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (customer != null) ...[
                      Text(
                        'Customer: ${customer['name'] ?? 'Unknown'}',
                        style: GoogleFonts.inter(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                    ),
                    Text(
                      'Total Paid: ₹${totalPaid.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(color: AppColors.success),
                    ),
                    Text(
                      'Remaining: ₹${(totalAmount - totalPaid).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(color: AppColors.error),
                    ),
                    const SizedBox(height: 8),
                    if (payments.isNotEmpty) ...[
                      Text(
                        'Payments (${payments.length}):',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...payments.map((payment) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 2),
                        child: Text(
                          '• ₹${payment['amount']} (${payment['method']}) - ${payment['paid_on']?.toString().split(' ').first ?? 'Unknown date'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )),
                    ] else ...[
                      Text(
                        'No payments recorded',
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showOrderDetailsDialog(orderData),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: Text('View Details', style: GoogleFonts.inter()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _generateOrderReport(orderData),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: Text('PDF', style: GoogleFonts.inter()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: _ordersWithPayments.length,
        ),
      ),
    );
  }

  // Sliver version for better scrolling
  Widget _buildAnalyticsSliver() {
    if (_currentAnalytics == null) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No analytics data available',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final analytics = _currentAnalytics!;

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Revenue',
                  '₹${analytics.totalRevenue.toStringAsFixed(2)}',
                  Icons.monetization_on,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Payments',
                  analytics.totalTransactions.toString(),
                  Icons.payment,
                  AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Avg Payment',
                  '₹${analytics.averageTransactionValue.toStringAsFixed(2)}',
                  Icons.trending_up,
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Pending Amount',
                  '₹${analytics.outstandingAmount.toStringAsFixed(2)}',
                  Icons.pending,
                  AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Payment methods breakdown
          if (analytics.revenueByPaymentMethod.isNotEmpty) ...[
            Text(
              'Payment Methods',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...analytics.revenueByPaymentMethod.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    _getPaymentMethodIcon(entry.key),
                    color: AppColors.primary,
                  ),
                  title: Text(
                    entry.key.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: Text(
                    '₹${entry.value.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Recent revenue by day
          Text(
            'Revenue Trends',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (analytics.revenueByDay.isNotEmpty)
            ...analytics.revenueByDay.entries.take(5).map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: AppColors.secondary,
                  ),
                  title: Text(
                    '₹${entry.value.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  subtitle: Text(
                    'Revenue on ${entry.key}',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                  trailing: Text(
                    entry.key,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            })
          else
            Card(
              child: ListTile(
                leading: Icon(Icons.info, color: AppColors.info),
                title: Text(
                  'No revenue data available',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ),
            ),
          const SizedBox(height: 24), // Bottom padding
        ]),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade100;
      case 'in_progress':
        return Colors.blue.shade100;
      case 'ready':
        return Colors.green.shade100;
      case 'completed':
        return Colors.green.shade200;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.qr_code;
      case 'bank_transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  void _showOrderDetailsDialog(Map<String, dynamic> orderData) {
    final order = orderData['order'] as Map<String, dynamic>;
    final payments = orderData['payments'] as List<Map<String, dynamic>>;
    final customer = orderData['customer'] as Map<String, dynamic>?;
    final totalPaid = orderData['total_paid'] as double;
    final totalAmount = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details #${order['id']?.toString().substring(0, 8) ?? 'N/A'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customer != null) ...[
                _buildDetailRow('Customer', customer['name'] ?? 'Unknown'),
                _buildDetailRow('Phone', customer['phone'] ?? 'N/A'),
                const Divider(),
              ],
              _buildDetailRow('Service Type', order['service_type']?.toString() ?? 'N/A'),
              _buildDetailRow('Status', order['status']?.toString().toUpperCase() ?? 'UNKNOWN'),
              _buildDetailRow('Total Amount', '₹${totalAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Total Paid', '₹${totalPaid.toStringAsFixed(2)}'),
              _buildDetailRow('Remaining', '₹${(totalAmount - totalPaid).toStringAsFixed(2)}'),
              _buildDetailRow('Created', order['created_at']?.toString().split(' ').first ?? 'Unknown'),
              if (order['due_date'] != null)
                _buildDetailRow('Due Date', order['due_date']?.toString().split(' ').first ?? 'Unknown'),
              const Divider(),
              const Text(
                'Payment History:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (payments.isEmpty)
                const Text('No payments recorded', style: TextStyle(color: Colors.grey))
              else
                ...payments.map((payment) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${payment['amount']} (${payment['method']})'),
                      Text(payment['paid_on']?.toString().split(' ').first ?? 'Unknown'),
                    ],
                  ),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateOrderReport(orderData);
            },
            child: const Text('Generate PDF Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _generateOrderReport(Map<String, dynamic> orderData) {
    // Placeholder for PDF generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF generation feature will be implemented soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}