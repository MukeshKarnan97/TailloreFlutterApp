import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/local_db_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/constants/app_constants.dart';

class PaymentCollectionScreen extends StatefulWidget {
  const PaymentCollectionScreen({Key? key}) : super(key: key);

  @override
  State<PaymentCollectionScreen> createState() => _PaymentCollectionScreenState();
}

class _PaymentCollectionScreenState extends State<PaymentCollectionScreen> {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _ordersWithPendingPayments = [];
  bool _isLoading = true;
  double _totalPendingAmount = 0.0;
  int _pendingOrdersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrdersWithPendingPayments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrdersWithPendingPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get tailor ID - for now using a default one, should be from auth
      const tailorId = 'tailor_001';
      final orders = await _dbService.getOrdersWithCustomerDetails(tailorId);
      
      _allOrders = orders.where((orderMap) {
        final totalAmount = (orderMap['total_amount'] as num?)?.toDouble() ?? 0.0;
        final advancePaid = (orderMap['advance_paid'] as num?)?.toDouble() ?? 0.0;
        final isDeleted = (orderMap['is_deleted'] as int?) == 1;
        
        return !isDeleted && totalAmount > advancePaid;
      }).toList();

      _ordersWithPendingPayments = List.from(_allOrders);
      _calculateTotals();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('PaymentCollectionScreen', 'Failed to load orders', error: e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateTotals() {
    _totalPendingAmount = _ordersWithPendingPayments.fold(
      0.0, 
      (sum, orderMap) {
        final totalAmount = (orderMap['total_amount'] as num?)?.toDouble() ?? 0.0;
        final advancePaid = (orderMap['advance_paid'] as num?)?.toDouble() ?? 0.0;
        return sum + (totalAmount - advancePaid);
      }
    );
    _pendingOrdersCount = _ordersWithPendingPayments.length;
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _ordersWithPendingPayments = List.from(_allOrders);
      } else {
        _ordersWithPendingPayments = _allOrders.where((orderMap) {
          final customerName = (orderMap['customer_name'] as String?) ?? '';
          final uniqueId = (orderMap['unique_id'] as String?) ?? '';
          final notes = (orderMap['notes'] as String?) ?? '';
          
          return customerName.toLowerCase().contains(query) ||
                 uniqueId.toLowerCase().contains(query) ||
                 notes.toLowerCase().contains(query);
        }).toList();
      }
      _calculateTotals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Payment Collection',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(AppConstants.primaryTeal),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrdersWithPendingPayments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with totals
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade600,
                  Colors.green.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Pending Orders',
                        value: _pendingOrdersCount.toString(),
                        icon: Icons.pending_actions,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Pending',
                        value: '₹${_totalPendingAmount.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search orders, customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _ordersWithPendingPayments.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadOrdersWithPendingPayments,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _ordersWithPendingPayments.length,
                          itemBuilder: (context, index) {
                            final orderMap = _ordersWithPendingPayments[index];
                            return _buildOrderCard(orderMap);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> orderMap) {
    final totalAmount = (orderMap['total_amount'] as num?)?.toDouble() ?? 0.0;
    final advancePaid = (orderMap['advance_paid'] as num?)?.toDouble() ?? 0.0;
    final uniqueId = (orderMap['unique_id'] as String?) ?? '';
    final customerName = (orderMap['customer_name'] as String?) ?? '';
    final status = (orderMap['status'] as String?) ?? '';
    
    final pendingAmount = totalAmount - advancePaid;
    final paymentProgress = totalAmount > 0 ? advancePaid / totalAmount : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uniqueId,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customerName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Payment Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paid Amount',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '₹${advancePaid.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Pending',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '₹${pendingAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Payment Progress Bar
                      LinearProgressIndicator(
                        value: paymentProgress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Progress',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${(paymentProgress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPaymentDialog(orderMap),
                    icon: const Icon(Icons.payment, size: 18),
                    label: Text(
                      'Collect Payment',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Payments',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All orders have been fully paid!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'cutting':
      case 'stitching':
      case 'in_progress':
        return Colors.blue;
      case 'ready':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showPaymentDialog(Map<String, dynamic> orderMap) async {
    final TextEditingController amountController = TextEditingController();
    
    final totalAmount = (orderMap['total_amount'] as num?)?.toDouble() ?? 0.0;
    final advancePaid = (orderMap['advance_paid'] as num?)?.toDouble() ?? 0.0;
    final uniqueId = (orderMap['unique_id'] as String?) ?? '';
    final customerName = (orderMap['customer_name'] as String?) ?? '';
    
    final pendingAmount = totalAmount - advancePaid;
    amountController.text = pendingAmount.toStringAsFixed(0);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.payment, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Text(
                'Collect Payment',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order: $uniqueId',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Customer: $customerName',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pending Amount: ₹${pendingAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Payment Amount Input
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    hintText: 'Enter amount to collect',
                    prefixIcon: Icon(Icons.currency_rupee, color: Colors.green.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  await _processPayment(orderMap, amount);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.red.shade600,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Collect Payment',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPayment(Map<String, dynamic> orderMap, double amount) async {
    try {
      final uniqueId = (orderMap['unique_id'] as String?) ?? '';
      final currentAdvancePaid = (orderMap['advance_paid'] as num?)?.toDouble() ?? 0.0;
      final newAdvancePaid = currentAdvancePaid + amount;
      
      // Update in database using the updateOrder method
      await _dbService.updateOrder(uniqueId, {
        'advance_paid': newAdvancePaid,
        'balance_amount': (orderMap['total_amount'] as num?)?.toDouble() ?? 0.0 - newAdvancePaid,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Refresh the data
      await _loadOrdersWithPendingPayments();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment of ₹${amount.toStringAsFixed(0)} collected successfully!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to process payment: ${e.toString()}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}