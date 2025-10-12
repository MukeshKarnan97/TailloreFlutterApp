import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../data/services/local_db_service.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/receipt_pdf_service.dart';
import '../../../../data/models/payment_model.dart';
import '../../../../data/enums/payment_method.dart';
import '../../../../core/services/back_button_handler.dart';
import '../../../../core/utils/logger.dart';
import '../../../../routes/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/mixins/navigation_mixin.dart';
import '../../../../widgets/custom_header.dart';

class ReceiptManagementScreen extends StatefulWidget {
  const ReceiptManagementScreen({super.key});

  @override
  State<ReceiptManagementScreen> createState() => _ReceiptManagementScreenState();
}

class _ReceiptManagementScreenState extends State<ReceiptManagementScreen> with NavigationMixin {
  final LocalDatabaseService _databaseService = LocalDatabaseService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _receipts = [];
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  bool _showPayments = true; // Toggle between payments and orders

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current tailor
      final currentTailor = _authService.currentUser;
      if (currentTailor == null) {
        Logger.warning('ReceiptManagementScreen', 'No tailor logged in');
        setState(() {
          _receipts = [];
          _orders = [];
          _isLoading = false;
        });
        return;
      }
      
      final tailorId = currentTailor.email;
      Logger.info('ReceiptManagementScreen', 'Loading receipts for tailor: $tailorId');

      // Load payments filtered by tailor (via orders)
      final payments = await _databaseService.getPayments(tailorId: tailorId);
      
      // Convert Payment objects to Map for UI compatibility
      final receipts = payments.map((payment) => payment.toMap()).toList();
      
      // Load orders filtered by tailor
      final orders = await _databaseService.select(
        'orders',
        where: 'tailor_id = ? AND is_deleted = 0',
        whereArgs: [tailorId],
        orderBy: 'created_at DESC',
      );

      setState(() {
        _receipts = receipts;
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler.wrapWithBackHandler(
      type: BackHandlerType.detail,
      context: context,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: DashboardHeader(
          title: _showPayments ? 'Payment Receipts' : 'Order Receipts',
          backgroundColor: AppColors.accent,
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
                AppColors.accent.withOpacity(0.03),
                AppColors.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // View Toggle Section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: AppColors.accent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Receipt Type',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildToggleButton(
                              'Payments',
                              _showPayments,
                              () {
                                setState(() {
                                  _showPayments = true;
                                });
                              },
                            ),
                            _buildToggleButton(
                              'Orders',
                              !_showPayments,
                              () {
                                setState(() {
                                  _showPayments = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(Icons.refresh, color: AppColors.accent),
                        onPressed: _loadData,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        )
                      : _showPayments
                          ? _buildPaymentReceiptsList()
                          : _buildOrderReceiptsList(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Create receipt feature coming soon',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppColors.accent,
              ),
            );
          },
          backgroundColor: AppColors.accent,
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            'New Receipt',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentReceiptsList() {
    if (_receipts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No payment receipts found',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _receipts.length,
      itemBuilder: (context, index) {
        final payment = _receipts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.payment, color: Colors.white),
            ),
            title: Text(
              'Payment #${payment['id']}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: ₹${payment['amount']?.toString() ?? '0'}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
                Text(
                  'Method: ${payment['method'] ?? 'Unknown'}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
                Text(
                  'Date: ${_formatDate(payment['paid_on'] ?? '')}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
                if (payment['order_id'] != null)
                  Text(
                    'Order: ${payment['order_id']?.toString() ?? 'N/A'}',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _generatePaymentReceipt(payment),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'PDF',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            onTap: () => _showPaymentReceiptDetails(payment),
          ),
        );
      },
    );
  }

  Widget _buildOrderReceiptsList() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No order receipts found',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppColors.panel,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.accent.withOpacity(0.2),
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.receipt_long, color: Colors.white),
            ),
            title: Text(
              'Order #${order['id']}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: ₹${order['total_amount']?.toString() ?? '0'}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
                Text(
                  'Status: ${order['status'] ?? 'Unknown'}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
                Text(
                  'Date: ${_formatDate(order['created_at'] ?? '')}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
                if (order['service_type'] != null)
                  Text(
                    'Service: ${order['service_type']?.toString() ?? 'N/A'}',
                    style: GoogleFonts.inter(
                      color: AppColors.success,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _generateOrderReceipt(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'PDF',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            onTap: () => _showOrderReceiptDetails(order),
          ),
        );
      },
    );
  }

  Future<void> _generatePaymentReceipt(Map<String, dynamic> payment) async {
    try {
      // Get related order data if available
      Map<String, dynamic>? orderData;
      Map<String, dynamic>? customerData;
      
      if (payment['order_id'] != null) {
        final orders = await _databaseService.select(
          'orders',
          where: 'unique_id = ?',
          whereArgs: [payment['order_id']],
          limit: 1,
        );
        if (orders.isNotEmpty) {
          orderData = orders.first;
          
          // Get customer data
          if (orderData['customer_id'] != null) {
            final customers = await _databaseService.select(
              'customer',
              where: 'id = ?',
              whereArgs: [orderData['customer_id']],
              limit: 1,
            );
            if (customers.isNotEmpty) {
              customerData = customers.first;
            }
          }
        }
      }
      
      await ReceiptPdfService.generatePaymentReceipt(
        paymentData: payment,
        orderData: orderData,
        customerData: customerData,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment receipt generated successfully!')),
        );
      }
    } catch (e) {
      Logger.error('ReceiptManagementScreen', 'Error generating payment receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating receipt: $e')),
        );
      }
    }
  }

  Future<void> _generateOrderReceipt(Map<String, dynamic> order) async {
    try {
      // Get customer data
      Map<String, dynamic>? customerData;
      if (order['customer_id'] != null) {
        final customers = await _databaseService.select(
          'customer',
          where: 'id = ?',
          whereArgs: [order['customer_id']],
          limit: 1,
        );
        if (customers.isNotEmpty) {
          customerData = customers.first;
        }
      }
      
      // Get payment history for this order using the same method as working payment screens
      Logger.info('ReceiptManagementScreen', 
        'DEBUG: Getting payments using getPaymentsByOrderId for order ${order['unique_id']}');
      Logger.debug('ReceiptManagementScreen', 
        'Full order data: ${order.toString()}');
      
      // Use the same method as payment_history_screen.dart - this is the proven working approach
      final paymentObjects = await _databaseService.getPaymentsByOrderId(order['unique_id']);
      
      Logger.info('ReceiptManagementScreen', 
        'Payment query results: Found ${paymentObjects.length} payments using getPaymentsByOrderId()');
      
      // If no payments found, let's also try raw query for debugging
      if (paymentObjects.isEmpty) {
        Logger.warning('ReceiptManagementScreen', 
          'No payments found with getPaymentsByOrderId, trying raw query for debugging...');
        
        final rawPayments = await _databaseService.select(
          'payment',
          where: 'order_id = ? AND is_deleted = 0',
          whereArgs: [order['unique_id']],
        );
        
        Logger.debug('ReceiptManagementScreen', 
          'Raw query result: ${rawPayments.length} payments found');
      }
      
      // Convert Payment objects to Map format for PDF service compatibility - REMOVED, now passing objects directly
      // Use paymentObjects directly instead of converting to maps
      final finalPayments = paymentObjects;
      
      if (finalPayments.isNotEmpty) {
        Logger.info('ReceiptManagementScreen', 
          'Found ${finalPayments.length} payments for order ${order['unique_id']}');
        for (int i = 0; i < finalPayments.length; i++) {
          final payment = finalPayments[i];
          Logger.debug('ReceiptManagementScreen', 
            'Payment ${i + 1}: ID=${payment.id}, Amount=₹${payment.amount}, Method=${payment.method}, Date=${payment.paidOn}, Order_ID=${payment.orderId}');
        }
      } else {
        Logger.error('ReceiptManagementScreen', 
          'CRITICAL: No payments found for order ${order['unique_id']} with any query method!');
        Logger.debug('ReceiptManagementScreen', 
          'Order ID: ${order['id']}, Unique ID: ${order['unique_id']}');
        
        // 🔧 AUTO-FIX: If there's an advance_paid amount but no payment records, create the missing record
        final advancePaid = order['advance_paid'] ?? 0.0;
        if (advancePaid > 0) {
          Logger.info('ReceiptManagementScreen', 
            '🔧 AUTO-FIX: Creating missing payment record for advance payment of ₹$advancePaid');
          
          try {
            // ENHANCED: Verify order exists in database before creating payment
            final db = await _databaseService.database;
            final orderVerification = await db.rawQuery(
              'SELECT unique_id, customer_id FROM orders WHERE unique_id = ? AND is_deleted = 0',
              [order['unique_id']]
            );
            
            String verifiedOrderId;
            if (orderVerification.isEmpty) {
              Logger.warning('ReceiptManagementScreen', 'Order ${order['unique_id']} not found, trying flexible search');
              
              // Try flexible matching
              final flexibleSearch = await db.rawQuery(
                'SELECT unique_id FROM orders WHERE TRIM(UPPER(unique_id)) = TRIM(UPPER(?)) AND is_deleted = 0',
                [order['unique_id']]
              );
              
              if (flexibleSearch.isEmpty) {
                throw Exception('Order ${order['unique_id']} not found in database');
              }
              
              verifiedOrderId = flexibleSearch.first['unique_id'] as String;
              Logger.info('ReceiptManagementScreen', 'Found order with corrected ID: $verifiedOrderId');
            } else {
              verifiedOrderId = orderVerification.first['unique_id'] as String;
            }
            
            // Create Payment object using the model's create method
            final payment = Payment.create(
              orderId: verifiedOrderId, // Use verified order ID
              amount: advancePaid,
              method: PaymentMethod.cash, // Use cash for advance payments
              notes: 'Advance payment - Auto-created missing record',
            );
            
            // Use the database service's addPayment method for proper validation
            final paymentSaved = await _databaseService.addPayment(payment);
            
            if (!paymentSaved) {
              throw Exception('Failed to save payment to database');
            }
            
            Logger.info('ReceiptManagementScreen', 
              '✅ AUTO-FIX: Successfully created payment record ${payment.uniqueId} for ₹$advancePaid');
            
            // Re-query using the same method to get the newly created payment
            final updatedPaymentObjects = await _databaseService.getPaymentsByOrderId(verifiedOrderId);
            
            // Update finalPayments with Payment objects directly
            finalPayments.clear();
            finalPayments.addAll(updatedPaymentObjects);
            
            Logger.info('ReceiptManagementScreen', 
              '✅ AUTO-FIX: Updated payment list, now contains ${finalPayments.length} payments');
            
          } catch (fixError) {
            Logger.error('ReceiptManagementScreen', 
              '❌ AUTO-FIX FAILED: Could not create missing payment record', error: fixError);
          }
        }
        
        // Let's check all payments in the database
        final allPayments = await _databaseService.select('payment');
        Logger.debug('ReceiptManagementScreen', 
          'Total payments in database: ${allPayments.length}');
        for (int i = 0; i < allPayments.length && i < 5; i++) {
          final payment = allPayments[i];
          Logger.debug('ReceiptManagementScreen', 
            'Payment sample ${i + 1}: ID=${payment['id']}, Order_ID=${payment['order_id']}, Amount=₹${payment['amount']}');
        }
      }
      
      await ReceiptPdfService.generateOrderReceipt(
        orderData: order,
        customerData: customerData,
        payments: finalPayments,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order receipt generated successfully!')),
        );
      }
    } catch (e) {
      Logger.error('ReceiptManagementScreen', 'Error generating order receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating receipt: $e')),
        );
      }
    }
  }

  void _showPaymentReceiptDetails(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment #${payment['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '₹${payment['amount']?.toString() ?? '0'}'),
            _buildDetailRow('Method', payment['method'] ?? 'Unknown'),
            _buildDetailRow('Status', payment['status'] ?? 'Unknown'),
            _buildDetailRow('Date', _formatDate(payment['paid_on'] ?? '')),
            _buildDetailRow('Order ID', payment['order_id']?.toString() ?? 'N/A'),
            if (payment['notes'] != null && payment['notes'].toString().isNotEmpty)
              _buildDetailRow('Notes', payment['notes'].toString()),
            if (payment['transaction_id'] != null && payment['transaction_id'].toString().isNotEmpty)
              _buildDetailRow('Transaction ID', payment['transaction_id'].toString()),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This payment will appear in comprehensive PDF receipt',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generatePaymentReceipt(payment);
            },
            child: const Text('Generate PDF'),
          ),
        ],
      ),
    );
  }

  void _showOrderReceiptDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Total Amount', '₹${order['total_amount']?.toString() ?? '0'}'),
            _buildDetailRow('Status', order['status'] ?? 'Unknown'),
            _buildDetailRow('Service Type', order['service_type'] ?? 'Unknown'),
            _buildDetailRow('Date', _formatDate(order['created_at'] ?? '')),
            _buildDetailRow('Due Date', _formatDate(order['due_date'] ?? '')),
            if (order['notes'] != null && order['notes'].toString().isNotEmpty)
              _buildDetailRow('Notes', order['notes'].toString()),
            if (order['measurements'] != null && order['measurements'].toString().isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Measurements:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(order['measurements'].toString(), style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PDF will include customer details, order information, measurements & all payments',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateOrderReceipt(order);
            },
            child: const Text('Generate PDF'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}