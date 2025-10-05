import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/enums/payment_method.dart';
import '../../../data/services/local_db_service.dart';
import '../../../core/utils/logger.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String? orderId;
  
  const PaymentHistoryScreen({super.key, this.orderId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Payment> _allPayments = [];
  List<Payment> _filteredPayments = [];
  bool _isLoading = true;
  PaymentMethod? _selectedMethodFilter;

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPayments();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure database is ready
      await _dbService.database;
      
      List<Payment> payments;
      if (widget.orderId != null) {
        Logger.debug('PaymentHistoryScreen', 'Loading payments for order: ${widget.orderId}');
        payments = await _dbService.getPaymentsByOrderId(widget.orderId!);
      } else {
        Logger.debug('PaymentHistoryScreen', 'Loading all payments');
        payments = await _dbService.getPayments();
      }
      
      Logger.info('PaymentHistoryScreen', 'Loaded ${payments.length} payments');
      
      // Debug: Log each payment for troubleshooting
      for (final payment in payments) {
        Logger.debug('PaymentHistoryScreen', 
          'Payment ${payment.uniqueId}: Order=${payment.orderId}, Amount=₹${payment.amount}, Method=${payment.method.displayName}, Date=${payment.paidOn}');
      }
      
      if (mounted) {
        _allPayments = payments;
        _filteredPayments = List.from(_allPayments);
        _applyFilters(); // Apply any existing filters
        
        setState(() {
          _isLoading = false;
        });
        
        // Show success message for manual refresh
        if (payments.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded ${payments.length} payments'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      Logger.error('PaymentHistoryScreen', 'Failed to load payments', 
                   error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payments: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      final searchQuery = _searchController.text.toLowerCase();
      _filteredPayments = _allPayments.where((payment) {
        final matchesSearch = payment.orderId.toLowerCase().contains(searchQuery) ||
                             payment.notes.toLowerCase().contains(searchQuery);
        final matchesMethod = _selectedMethodFilter == null || 
                             payment.method == _selectedMethodFilter;
        return matchesSearch && matchesMethod;
      }).toList();
    });
  }

  double get _totalAmount {
    return _filteredPayments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF21899C),
        foregroundColor: Colors.white,
        title: Text(
          widget.orderId != null 
              ? 'Order Payments'
              : 'Payment History',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              // Debug: Check database directly
              try {
                final db = await _dbService.database;
                
                // Query all payments (including deleted ones for debugging)
                final allResult = await db.query('payment');
                final activeResult = await db.query('payment', where: 'is_deleted = 0');
                
                Logger.info('PaymentHistoryScreen', 'Direct DB Query - Found ${allResult.length} total records, ${activeResult.length} active records in payment table');
                
                for (final row in activeResult.take(5)) { // Show only first 5 for brevity
                  Logger.debug('PaymentHistoryScreen', 'Payment Row: $row');
                }
                
                // Check if there are any database connection issues
                final ordersResult = await db.query('orders', limit: 1);
                Logger.info('PaymentHistoryScreen', 'Database connectivity test - Orders table accessible: ${ordersResult.isNotEmpty}');
                
                // Show debug info to user
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Debug Information'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total payments in DB: ${allResult.length}'),
                          Text('Active payments: ${activeResult.length}'),
                          Text('Loaded in app: ${_allPayments.length}'),
                          Text('Filtered payments: ${_filteredPayments.length}'),
                          const SizedBox(height: 8),
                          Text('Current filter: ${_selectedMethodFilter?.displayName ?? 'All'}'),
                          Text('Search query: "${_searchController.text}"'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _loadPayments(); // Force refresh
                          },
                          child: const Text('Force Refresh'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                Logger.error('PaymentHistoryScreen', 'Debug query failed: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Debug failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            tooltip: 'Debug Database',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Logger.info('PaymentHistoryScreen', 'Manual refresh triggered');
              _loadPayments();
            },
            tooltip: 'Refresh Payments',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search payments...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF21899C)),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Method Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      ...PaymentMethod.values.map((method) => 
                        _buildFilterChip(method.displayName, method)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Summary Card
          if (_filteredPayments.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Payments',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${_totalAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

          // Payments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadPayments,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredPayments.length,
                          itemBuilder: (context, index) {
                            return _buildPaymentCard(_filteredPayments[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PaymentMethod? method) {
    final isSelected = _selectedMethodFilter == method;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedMethodFilter = selected ? method : null;
          });
          _applyFilters();
        },
        selectedColor: const Color(0xFF21899C).withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected 
              ? const Color(0xFF21899C)
              : Colors.grey.shade700,
          fontWeight: isSelected 
              ? FontWeight.w600
              : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Payments Found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.orderId != null 
                ? 'No payments found for this order'
                : 'No payment transactions found',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
            label: Text(
              'Refresh',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF21899C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Navigate to payment collection screen
              context.push('/payments/collection');
            },
            child: Text(
              'Collect Payment',
              style: GoogleFonts.inter(
                color: const Color(0xFF21899C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment #${payment.uniqueId}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${payment.orderId}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      payment.getFormattedAmount(),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getMethodColor(payment.method).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payment.method.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getMethodColor(payment.method),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Date and Notes
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Text(
                  payment.getFormattedDateTime(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            if (payment.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      payment.notes,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            if (payment.transactionId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ref: ${payment.transactionId}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(PaymentMethod method) {
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
}