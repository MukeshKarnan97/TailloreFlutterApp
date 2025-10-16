import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/mixins/navigation_mixin.dart';
import '../../../../widgets/custom_header.dart';
import '../../../../data/services/local_db_service.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../core/services/back_button_handler.dart';
import '../../../../core/utils/logger.dart';
import '../../../../routes/route_names.dart';

class RefundManagementScreen extends StatefulWidget {
  const RefundManagementScreen({super.key});

  @override
  State<RefundManagementScreen> createState() => _RefundManagementScreenState();
}

class _RefundManagementScreenState extends State<RefundManagementScreen> with NavigationMixin {
  final LocalDatabaseService _databaseService = LocalDatabaseService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _refunds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ensureRefundTableExists();
    _loadRefunds();
  }

  Future<void> _ensureRefundTableExists() async {
    try {
      final db = await _databaseService.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS refund_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          payment_id INTEGER,
          order_id INTEGER,
          customer_id INTEGER,
          tailor_id TEXT,
          refund_amount REAL NOT NULL,
          refund_reason TEXT,
          refund_method TEXT NOT NULL,
          refund_status TEXT NOT NULL DEFAULT 'pending',
          processed_by TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
          processed_at TEXT,
          notes TEXT,
          FOREIGN KEY (payment_id) REFERENCES payment(id),
          FOREIGN KEY (order_id) REFERENCES orders(id),
          FOREIGN KEY (customer_id) REFERENCES customer(id)
        )
      ''');
    } catch (e) {
      Logger.error('RefundManagementScreen', 'Error creating refund table', error: e);
    }
  }

  Future<void> _loadRefunds() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current tailor
      final currentTailor = _authService.currentUser;
      if (currentTailor == null) {
        Logger.warning('RefundManagementScreen', 'No tailor logged in');
        setState(() {
          _refunds = [];
          _isLoading = false;
        });
        return;
      }
      
      final tailorId = currentTailor.email;
      Logger.info('RefundManagementScreen', 'Loading refunds for tailor: $tailorId');

      // Load refunds filtered by tailor
      final refunds = await _databaseService.select(
        'refund_transactions',
        where: 'tailor_id = ?',
        whereArgs: [tailorId],
        orderBy: 'created_at DESC',
      );

      setState(() {
        _refunds = refunds;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('RefundManagementScreen', 'Failed to load refunds', error: e);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading refunds: $e')),
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
          title: 'Refund Management',
          backgroundColor: AppColors.warning,
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
                AppColors.warning.withOpacity(0.03),
                AppColors.background,
              ],
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.warning,
                    ),
                  )
                : _refunds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.money_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No refunds found',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRefunds,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _refunds.length,
                          itemBuilder: (context, index) {
                            final refund = _refunds[index];
                            return _buildRefundCard(refund);
                          },
                        ),
                      ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateRefundDialog,
          backgroundColor: AppColors.warning,
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add Refund',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefundCard(Map<String, dynamic> refund) {
    final amount = refund['refund_amount']?.toString() ?? '0';
    final method = refund['refund_method'] ?? 'Unknown';
    final status = refund['refund_status'] ?? 'Unknown';
    final reason = refund['refund_reason'] ?? 'No reason provided';
    final date = refund['created_at'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: Icon(
            _getRefundIcon(status),
            color: Colors.white,
          ),
        ),
        title: Text(
          'Refund #${refund['id']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: \$${double.parse(amount).toStringAsFixed(2)}'),
            Text('Method: $method'),
            Text('Reason: $reason'),
            Text('Date: ${_formatDate(date)}'),
          ],
        ),
        trailing: Chip(
          label: Text(
            status.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _getStatusColor(status).withOpacity(0.2),
        ),
        onTap: () => _showRefundDetails(refund),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getRefundIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.money_off;
    }
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

  void _showRefundDetails(Map<String, dynamic> refund) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Refund #${refund['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '\$${double.parse(refund['refund_amount']?.toString() ?? '0').toStringAsFixed(2)}'),
            _buildDetailRow('Method', refund['refund_method'] ?? 'Unknown'),
            _buildDetailRow('Status', refund['refund_status'] ?? 'Unknown'),
            _buildDetailRow('Reason', refund['refund_reason'] ?? 'No reason provided'),
            _buildDetailRow('Date', _formatDate(refund['created_at'] ?? '')),
            _buildDetailRow('Order ID', refund['order_id']?.toString() ?? 'N/A'),
            _buildDetailRow('Payment ID', refund['payment_id']?.toString() ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (refund['refund_status'] == 'pending')
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processRefund(refund);
              },
              child: const Text('Process'),
            ),
        ],
      ),
    );
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

  void _showCreateRefundDialog() {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    String selectedMethod = 'cash';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Refund Amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedMethod,
              decoration: const InputDecoration(labelText: 'Refund Method'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
              ],
              onChanged: (value) {
                selectedMethod = value ?? 'cash';
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Refund Reason',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createRefund(
                double.tryParse(amountController.text) ?? 0,
                selectedMethod,
                reasonController.text,
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createRefund(double amount, String method, String reason) async {
    try {
      final db = await _databaseService.database;
      await db.insert('refund_transactions', {
        'refund_amount': amount,
        'refund_method': method,
        'refund_reason': reason,
        'refund_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      await _loadRefunds();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refund created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating refund: $e')),
        );
      }
    }
  }

  Future<void> _processRefund(Map<String, dynamic> refund) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'refund_transactions',
        {
          'refund_status': 'completed',
          'processed_at': DateTime.now().toIso8601String(),
          'processed_by': 'admin', // You can get this from current user
        },
        where: 'id = ?',
        whereArgs: [refund['id']],
      );

      await _loadRefunds();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refund processed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing refund: $e')),
        );
      }
    }
  }
}