import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/local_db_service.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/enums/payment_method.dart';
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
  
  // Toggle between payment pending only vs all active orders
  bool _showPaymentPendingOnly = true;

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
      
      // Debug: Log total orders fetched
      Logger.info('PaymentCollectionScreen', 'Total orders fetched: ${orders.length}');
      
      // Debug: Count orders by status and payment status
      int pendingStatusCount = 0;
      int inProgressStatusCount = 0;
      int fullyPaidCount = 0;
      int partialPaidCount = 0;
      int noPaidCount = 0;
      
      _allOrders = orders.where((orderMap) {
        final totalAmount = (orderMap['total_amount'] as num?)?.toDouble() ?? 0.0;
        final advancePaid = (orderMap['advance_paid'] as num?)?.toDouble() ?? 0.0;
        final isDeleted = (orderMap['is_deleted'] as int?) == 1;
        final orderStatus = (orderMap['status'] as String?) ?? '';
        // Debug counting
        if (orderStatus.toLowerCase() == 'pending') pendingStatusCount++;
        if (orderStatus.toLowerCase() == 'in_progress' || 
            orderStatus.toLowerCase() == 'cutting' || 
            orderStatus.toLowerCase() == 'stitching') inProgressStatusCount++;
        
        if (totalAmount <= advancePaid) fullyPaidCount++;
        else if (advancePaid > 0) partialPaidCount++;
        else noPaidCount++;
        
        // Show orders based on toggle setting
        final shouldShow = !isDeleted && totalAmount > 0 && 
          (_showPaymentPendingOnly 
            ? // Payment pending only - show orders with pending payments
              (totalAmount > advancePaid)
            : // All active orders (pending, in-progress, cutting, stitching, ready)
              (orderStatus.toLowerCase() != 'completed' && 
               orderStatus.toLowerCase() != 'delivered' &&
               orderStatus.toLowerCase() != 'cancelled'));
        
        // Debug: Log each order's payment status
        if (!isDeleted && totalAmount > 0) {
          Logger.debug('PaymentCollectionScreen', 
            'Order ${orderMap['unique_id']}: Status=${orderStatus}, '
            'Total=₹${totalAmount.toStringAsFixed(0)}, '
            'Paid=₹${advancePaid.toStringAsFixed(0)}, '
            'ShouldShow=${shouldShow}');
        }
        
        return shouldShow;
      }).toList();
      
      // Debug: Log summary
      Logger.info('PaymentCollectionScreen', 
        'Order Status Summary: Pending=${pendingStatusCount}, InProgress=${inProgressStatusCount}');
      Logger.info('PaymentCollectionScreen', 
        'Payment Summary: FullyPaid=${fullyPaidCount}, PartialPaid=${partialPaidCount}, NoPaid=${noPaidCount}');
      Logger.info('PaymentCollectionScreen', 
        'Orders shown in Payment Collection: ${_allOrders.length}');

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
                        title: _showPaymentPendingOnly ? 'Unpaid Orders' : 'Active Orders',
                        value: _pendingOrdersCount.toString(),
                        icon: Icons.receipt_long,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Amount Due',
                        value: '₹${_totalPendingAmount.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Toggle buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showPaymentPendingOnly ? null : () {
                          setState(() {
                            _showPaymentPendingOnly = true;
                          });
                          _loadOrdersWithPendingPayments();
                        },
                        icon: Icon(
                          Icons.payment_outlined,
                          size: 16,
                          color: _showPaymentPendingOnly ? Colors.white : Colors.green.shade600,
                        ),
                        label: Text(
                          'Payment Due',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _showPaymentPendingOnly ? Colors.white : Colors.green.shade600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showPaymentPendingOnly 
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.2),
                          foregroundColor: _showPaymentPendingOnly ? Colors.green.shade600 : Colors.white,
                          elevation: _showPaymentPendingOnly ? 2 : 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !_showPaymentPendingOnly ? null : () {
                          setState(() {
                            _showPaymentPendingOnly = false;
                          });
                          _loadOrdersWithPendingPayments();
                        },
                        icon: Icon(
                          Icons.list_alt_outlined,
                          size: 16,
                          color: !_showPaymentPendingOnly ? Colors.white : Colors.green.shade600,
                        ),
                        label: Text(
                          'All Active',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: !_showPaymentPendingOnly ? Colors.white : Colors.green.shade600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_showPaymentPendingOnly 
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.2),
                          foregroundColor: !_showPaymentPendingOnly ? Colors.green.shade600 : Colors.white,
                          elevation: !_showPaymentPendingOnly ? 2 : 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
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
                hintText: _showPaymentPendingOnly 
                    ? 'Search unpaid orders, customers...'
                    : 'Search active orders, customers...',
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
    
    // Determine payment status display
    String paymentStatusText;
    Color paymentStatusColor;
    if (advancePaid == 0) {
      paymentStatusText = 'NO PAYMENT';
      paymentStatusColor = Colors.red;
    } else if (pendingAmount > 0) {
      paymentStatusText = 'PARTIAL PAID';
      paymentStatusColor = Colors.orange;
    } else {
      paymentStatusText = 'FULLY PAID';
      paymentStatusColor = Colors.green;
    }

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
                    // Payment Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: paymentStatusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            advancePaid == 0 
                                ? Icons.payment_outlined
                                : pendingAmount > 0 
                                    ? Icons.pending_actions 
                                    : Icons.payment,
                            size: 12,
                            color: paymentStatusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            paymentStatusText,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: paymentStatusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Order Status Badge
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

                // Action Buttons Row
                Row(
                  children: [
                    // Payment Button
                    Expanded(
                      flex: 3,
                      child: pendingAmount > 0 
                        ? ElevatedButton.icon(
                            onPressed: () => _showPaymentDialog(orderMap),
                            icon: const Icon(Icons.payment, size: 16),
                            label: Text(
                              'Collect Payment',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, 
                                     size: 16, 
                                     color: Colors.green.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  'Payment Complete',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Delete Button
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () => _showDeleteConfirmation(orderMap),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Icon(Icons.delete, size: 16),
                      ),
                    ),
                  ],
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
            _showPaymentPendingOnly 
                ? Icons.account_balance_wallet_outlined
                : Icons.checklist_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _showPaymentPendingOnly ? 'No Unpaid Orders' : 'No Active Orders',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showPaymentPendingOnly
                ? 'All orders have been fully paid!\nGreat job on payment collection.'
                : 'No orders are currently in progress.\nAll orders are completed or delivered.',
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
    final TextEditingController notesController = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.cash; // Default to cash
    
    final totalAmount = (orderMap['total_amount'] as num?)?.toDouble() ?? 0.0;
    final advancePaid = (orderMap['advance_paid'] as num?)?.toDouble() ?? 0.0;
    final uniqueId = (orderMap['unique_id'] as String?) ?? '';
    final customerName = (orderMap['customer_name'] as String?) ?? '';
    
    final pendingAmount = totalAmount - advancePaid;
    amountController.text = pendingAmount.toStringAsFixed(0);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        bool isAmountValid = true;
        String? errorMessage;
        
        return StatefulBuilder(
          builder: (context, setState) {
            // Validate amount in real-time
            void validateAmount(String value) {
              final amount = double.tryParse(value);
              setState(() {
                if (amount == null || amount <= 0) {
                  isAmountValid = false;
                  errorMessage = 'Please enter a valid amount';
                } else if (amount > pendingAmount) {
                  isAmountValid = false;
                  errorMessage = 'Amount cannot exceed ₹${pendingAmount.toStringAsFixed(0)}';
                } else {
                  isAmountValid = true;
                  errorMessage = null;
                }
              });
            }
            
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
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 12, color: Colors.blue.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Max payment: ₹${pendingAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Method Selection
                    Text(
                      'Payment Method',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: selectedMethod,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          items: PaymentMethod.values.map((PaymentMethod method) {
                            return DropdownMenuItem<PaymentMethod>(
                              value: method,
                              child: Row(
                                children: [
                                  Icon(
                                    _getPaymentMethodIcon(method),
                                    size: 20,
                                    color: _getPaymentMethodColor(method),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    method.displayName,
                                    style: GoogleFonts.inter(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (PaymentMethod? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedMethod = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Amount Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          onChanged: validateAmount,
                          decoration: InputDecoration(
                            labelText: 'Payment Amount',
                            hintText: 'Max: ₹${pendingAmount.toStringAsFixed(0)}',
                            prefixIcon: Icon(Icons.currency_rupee, color: Colors.green.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isAmountValid ? Colors.green.shade600 : Colors.red.shade600,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.red.shade600),
                            ),
                          ),
                        ),
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                            child: Text(
                              errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Notes
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Transaction reference, etc.',
                        prefixIcon: Icon(Icons.note, color: Colors.grey.shade600),
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
                  onPressed: isAmountValid ? () async {
                    final amount = double.tryParse(amountController.text);
                    
                    // Final validation (should already be validated by real-time validation)
                    if (amount == null || amount <= 0 || amount > pendingAmount) {
                      return;
                    }
                    
                    // Process the payment
                    await _processPayment(
                      orderMap, 
                      amount, 
                      selectedMethod, 
                      notesController.text.trim()
                    );
                    Navigator.of(context).pop();
                  } : null, // Disable button if amount is invalid
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAmountValid ? Colors.green.shade600 : Colors.grey.shade400,
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
      },
    );
  }

  Future<void> _processPayment(
    Map<String, dynamic> orderMap, 
    double amount, 
    PaymentMethod method, 
    String notes
  ) async {
    try {
      final uniqueId = (orderMap['unique_id'] as String?) ?? '';
      final currentAdvancePaid = (orderMap['advance_paid'] as num?)?.toDouble() ?? 0.0;
      final newAdvancePaid = currentAdvancePaid + amount;
      
      Logger.info('PaymentCollectionScreen', 'Processing payment: ₹$amount for order $uniqueId via ${method.displayName}');
      
      // ENHANCED: Verify order exists in database before creating payment to prevent foreign key errors
      final db = await _dbService.database;
      final orderVerification = await db.rawQuery(
        'SELECT unique_id, customer_id FROM orders WHERE unique_id = ? AND is_deleted = 0',
        [uniqueId]
      );
      
      if (orderVerification.isEmpty) {
        Logger.error('PaymentCollectionScreen', 'Order $uniqueId not found in database for payment insertion');
        
        // Try to find the order with flexible matching (handles case/whitespace differences)
        final flexibleSearch = await db.rawQuery(
          'SELECT unique_id FROM orders WHERE TRIM(UPPER(unique_id)) = TRIM(UPPER(?)) AND is_deleted = 0',
          [uniqueId]
        );
        
        if (flexibleSearch.isNotEmpty) {
          final correctedOrderId = flexibleSearch.first['unique_id'] as String;
          Logger.info('PaymentCollectionScreen', 'Found order with corrected ID: $correctedOrderId');
          
          // Update the uniqueId to use the corrected version
          final correctedOrderMap = Map<String, dynamic>.from(orderMap);
          correctedOrderMap['unique_id'] = correctedOrderId;
          
          // Retry with corrected order ID
          return _processPayment(correctedOrderMap, amount, method, notes);
        } else {
          throw Exception('Order $uniqueId not found in database. Cannot process payment.');
        }
      }
      
      // Use the verified order ID from database
      final verifiedOrderId = orderVerification.first['unique_id'] as String;
      Logger.debug('PaymentCollectionScreen', 'Verified order ID: $verifiedOrderId');
      
      // Create payment record with verified order ID
      final payment = Payment.create(
        orderId: verifiedOrderId, // Use verified ID from database
        amount: amount,
        method: method,
        notes: notes,
      );
      
      Logger.debug('PaymentCollectionScreen', 'Created payment object: ${payment.uniqueId}');
      
      // Insert payment into database with enhanced error handling
      final paymentSaved = await _dbService.addPayment(payment);
      Logger.info('PaymentCollectionScreen', 'Payment save result: $paymentSaved');
      
      if (!paymentSaved) {
        throw Exception('Failed to save payment to database');
      }
      
      // Verify payment was actually inserted
      final paymentVerification = await _dbService.getPaymentsByOrderId(verifiedOrderId);
      final newPayment = paymentVerification.firstWhere(
        (p) => p.uniqueId == payment.uniqueId,
        orElse: () => throw Exception('Payment not found after insertion'),
      );
      
      Logger.info('PaymentCollectionScreen', 'Payment verified: ${newPayment.uniqueId} for ₹${newPayment.amount}');
      
      // Update order with new advance paid amount
      await _dbService.updateOrder(verifiedOrderId, {
        'advance_paid': newAdvancePaid,
        'balance_amount': (orderMap['total_amount'] as num?)?.toDouble() ?? 0.0 - newAdvancePaid,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      Logger.info('PaymentCollectionScreen', 'Order updated successfully');
      
      // Refresh the data
      await _loadOrdersWithPendingPayments();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment of ₹${amount.toStringAsFixed(0)} collected via ${method.displayName}!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Logger.error('PaymentCollectionScreen', 'Payment processing failed: $e');
      
      // Provide specific error messages based on the error type
      String errorMessage;
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        errorMessage = 'Payment failed: Order reference issue. Please try again or contact support.';
      } else if (e.toString().contains('not found')) {
        errorMessage = 'Payment failed: Order not found in database.';
      } else {
        errorMessage = 'Failed to process payment: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              // Retry the payment
              _showPaymentDialog(orderMap);
            },
          ),
        ),
      );
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.upi:
        return Icons.qr_code;
      case PaymentMethod.bank:
        return Icons.account_balance;
    }
  }

  Color _getPaymentMethodColor(PaymentMethod method) {
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

  Future<void> _showDeleteConfirmation(Map<String, dynamic> orderMap) async {
    final orderId = orderMap['unique_id'] as String;
    final customerName = orderMap['customer_name'] as String? ?? 'Unknown';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Order',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this order?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID: $orderId',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customer: $customerName',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action will move the order to deleted items. You can restore it later if needed.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteOrder(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(
                'Deleting order...',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
          ),
        ),
      );

      final success = await _dbService.softDeleteOrder(orderId);
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Order $orderId has been deleted',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () async {
                await _dbService.restoreOrder(orderId);
                await _loadOrdersWithPendingPayments();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '↩️ Order $orderId has been restored',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ),
        );
        
        // Refresh the orders list
        await _loadOrdersWithPendingPayments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Failed to delete order',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Error deleting order: $e',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}