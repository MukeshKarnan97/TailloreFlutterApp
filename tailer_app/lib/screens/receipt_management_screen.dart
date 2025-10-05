import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/services/local_db_service.dart';
import '../core/services/back_button_handler.dart';
import '../routes/route_names.dart';

class ReceiptManagementScreen extends StatefulWidget {
  const ReceiptManagementScreen({super.key});

  @override
  State<ReceiptManagementScreen> createState() => _ReceiptManagementScreenState();
}

class _ReceiptManagementScreenState extends State<ReceiptManagementScreen> {
  final LocalDatabaseService _databaseService = LocalDatabaseService();
  List<Map<String, dynamic>> _receipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load receipts from database
      final receipts = await _databaseService.select(
        'payment',
        orderBy: 'created_at DESC',
      );

      setState(() {
        _receipts = receipts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading receipts: $e')),
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
        appBar: AppBar(
          title: const Text('Receipt Management'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.goNamed(RouteNames.settings);
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _receipts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No receipts found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadReceipts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _receipts.length,
                      itemBuilder: (context, index) {
                        final receipt = _receipts[index];
                        return _buildReceiptCard(receipt);
                      },
                    ),
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to create receipt screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create receipt feature coming soon')),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> receipt) {
    final amount = receipt['amount']?.toString() ?? '0';
    final method = receipt['payment_method'] ?? 'Unknown';
    final status = receipt['payment_status'] ?? 'Unknown';
    final date = receipt['created_at'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: Icon(
            _getPaymentIcon(method),
            color: Colors.white,
          ),
        ),
        title: Text(
          'Receipt #${receipt['id']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: \$${double.parse(amount).toStringAsFixed(2)}'),
            Text('Method: $method'),
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
        onTap: () => _showReceiptDetails(receipt),
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
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'digital':
        return Icons.phone_android;
      default:
        return Icons.payment;
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

  void _showReceiptDetails(Map<String, dynamic> receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Receipt #${receipt['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '\$${double.parse(receipt['amount']?.toString() ?? '0').toStringAsFixed(2)}'),
            _buildDetailRow('Method', receipt['payment_method'] ?? 'Unknown'),
            _buildDetailRow('Status', receipt['payment_status'] ?? 'Unknown'),
            _buildDetailRow('Date', _formatDate(receipt['created_at'] ?? '')),
            _buildDetailRow('Order ID', receipt['order_id']?.toString() ?? 'N/A'),
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
              _generateReceipt(receipt);
            },
            child: const Text('Generate PDF'),
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

  void _generateReceipt(Map<String, dynamic> receipt) {
    // TODO: Implement PDF generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF generation feature coming soon')),
    );
  }
}