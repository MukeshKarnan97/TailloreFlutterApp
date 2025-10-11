import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/mixins/navigation_mixin.dart';
import '../../../../widgets/custom_header.dart';
import '../../../../data/models/payment_analytics.dart';
import '../../../../data/services/payment_analytics_service.dart';
import '../../../../data/services/local_db_service.dart';
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
  PaymentAnalytics? _currentAnalytics;
  List<Map<String, dynamic>> _ordersWithPayments = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week';
  DateTime _selectedDate = DateTime.now();
  bool _showOrdersList = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _loadOrdersWithPayments();
  }

  Future<void> _loadOrdersWithPayments() async {
    try {
      // Get orders with their payment details
      final orders = await _dbService.select('orders', orderBy: 'created_at DESC');
      List<Map<String, dynamic>> ordersWithPayments = [];
      
      for (final order in orders) {
        // Get payment details for each order
        final payments = await _dbService.select(
          'payment',
          where: 'order_id = ?',
          whereArgs: [order['id']],
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
          child: Column(
            children: [
              // Period Selector Header
              Container(
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
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                        ),
                      )
                    : _showOrdersList
                        ? _buildOrdersList()
                        : _buildAnalyticsView(),
              ),
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

  Widget _buildOrdersList() {
    if (_ordersWithPayments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No orders with payments found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ordersWithPayments.length,
      itemBuilder: (context, index) {
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(order['status']?.toString().toUpperCase() ?? 'UNKNOWN'),
                      backgroundColor: _getStatusColor(order['status']?.toString() ?? 'unknown'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (customer != null) ...[
                  Text('Customer: ${customer['name'] ?? 'Unknown'}'),
                  const SizedBox(height: 4),
                ],
                Text('Total Amount: ₹${totalAmount.toStringAsFixed(2)}'),
                Text('Total Paid: ₹${totalPaid.toStringAsFixed(2)}'),
                Text('Remaining: ₹${(totalAmount - totalPaid).toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                if (payments.isNotEmpty) ...[
                  Text(
                    'Payments (${payments.length}):',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...payments.map((payment) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 2),
                    child: Text(
                      '• ₹${payment['amount']} (${payment['method']}) - ${payment['paid_on']?.toString().split(' ').first ?? 'Unknown date'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )),
                ] else ...[
                  const Text(
                    'No payments recorded',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showOrderDetailsDialog(orderData),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Show Full Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _generateOrderReport(orderData),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Generate PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsView() {
    if (_currentAnalytics == null) {
      return const Center(
        child: Text('No analytics data available'),
      );
    }

    final analytics = _currentAnalytics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          Row(
            children: [
              const Text('Period: '),
              DropdownButton<String>(
                value: _selectedPeriod,
                items: const [
                  DropdownMenuItem(value: 'day', child: Text('Today')),
                  DropdownMenuItem(value: 'week', child: Text('This Week')),
                  DropdownMenuItem(value: 'month', child: Text('This Month')),
                  DropdownMenuItem(value: 'year', child: Text('This Year')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPeriod = value;
                    });
                    _loadAnalytics();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Revenue',
                  '₹${analytics.totalRevenue.toStringAsFixed(2)}',
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Payments',
                  analytics.totalTransactions.toString(),
                  Icons.payment,
                  Colors.blue,
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
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Pending Amount',
                  '₹${analytics.outstandingAmount.toStringAsFixed(2)}',
                  Icons.pending,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Payment methods breakdown
          if (analytics.revenueByPaymentMethod.isNotEmpty) ...[
            Text(
              'Payment Methods',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...analytics.revenueByPaymentMethod.entries.map((entry) {
              return Card(
                child: ListTile(
                  leading: Icon(_getPaymentMethodIcon(entry.key)),
                  title: Text(entry.key.toUpperCase()),
                  trailing: Text('₹${entry.value.toStringAsFixed(2)}'),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Recent revenue by day
          Text(
            'Revenue Trends',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (analytics.revenueByDay.isNotEmpty)
            ...analytics.revenueByDay.entries.take(5).map((entry) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text('₹${entry.value.toStringAsFixed(2)}'),
                  subtitle: Text('Revenue on ${entry.key}'),
                  trailing: Text(entry.key),
                ),
              );
            })
          else
            const Card(
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('No revenue data available'),
              ),
            ),
        ],
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