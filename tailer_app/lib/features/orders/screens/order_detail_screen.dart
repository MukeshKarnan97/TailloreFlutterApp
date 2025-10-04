import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/local_db_service.dart';
import '../../../data/models/order_model.dart';
import '../../../core/utils/logger.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  late Order _currentOrder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
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

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order received, waiting to start';
      case 'cutting':
        return 'Fabric cutting in progress';
      case 'stitching':
        return 'Stitching work in progress';
      case 'in_progress':
        return 'General work in progress';
      case 'ready':
        return 'Order completed, ready for delivery';
      case 'completed':
        return 'Order delivered and completed';
      case 'cancelled':
        return 'Order has been cancelled';
      default:
        return 'Status unknown';
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _dbService.updateOrderStatus(_currentOrder.uniqueId, newStatus);
      
      // Create new order with updated status
      _currentOrder = Order(
        id: _currentOrder.id,
        uniqueId: _currentOrder.uniqueId,
        customerId: _currentOrder.customerId,
        tailorId: _currentOrder.tailorId,
        serviceType: _currentOrder.serviceType,
        status: newStatus,
        paymentStatus: _currentOrder.paymentStatus,
        deliveryDate: _currentOrder.deliveryDate,
        notes: _currentOrder.notes,
        designImageUrl: _currentOrder.designImageUrl,
        totalAmount: _currentOrder.totalAmount,
        advancePaid: _currentOrder.advancePaid,
        balanceAmount: _currentOrder.balanceAmount,
        measurements: _currentOrder.measurements,
        createdAt: _currentOrder.createdAt,
        updatedAt: DateTime.now(),
        isDeleted: _currentOrder.isDeleted,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('OrderDetailScreen', 'Failed to update order status', 
                   error: e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update order status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _getAvailableStatuses() {
    // Define status progression
    switch (_currentOrder.status.toLowerCase()) {
      case 'pending':
        return ['pending', 'cutting', 'stitching', 'in_progress'];
      case 'cutting':
        return ['cutting', 'stitching', 'in_progress', 'ready'];
      case 'stitching':
        return ['stitching', 'in_progress', 'ready'];
      case 'in_progress':
        return ['in_progress', 'ready', 'completed'];
      case 'ready':
        return ['ready', 'completed', 'delivered'];
      case 'completed':
        return ['completed', 'delivered'];
      case 'delivered':
        return ['delivered'];
      default:
        return ['pending', 'cutting', 'stitching', 'in_progress', 'ready', 'completed', 'delivered'];
    }
  }

  void _showStatusUpdateDialog() {
    // Status mapping: pending -> in_progress (cutting/stitching) -> completed -> delivered
    final statuses = _getAvailableStatuses();
    String selectedStatus = _currentOrder.status;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Update Order Status',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        'Current Status: ${_currentOrder.status.toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(_currentOrder.status),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(_currentOrder.status),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select New Status:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...statuses.map((status) => RadioListTile<String>(
                  title: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: selectedStatus == status ? FontWeight.w600 : FontWeight.normal,
                      color: _getStatusColor(status),
                    ),
                  ),
                  subtitle: Text(
                    _getStatusDescription(status),
                    style: GoogleFonts.inter(fontSize: 11),
                  ),
                  value: status,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                  dense: true,
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: selectedStatus != _currentOrder.status
                ? () {
                    Navigator.pop(context);
                    _updateOrderStatus(selectedStatus);
                  }
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(selectedStatus),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Update Status',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _getStatusColor(_currentOrder.status),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentOrder.status.toLowerCase() != 'completed' && 
              _currentOrder.status.toLowerCase() != 'cancelled')
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'update_status') {
                  _showStatusUpdateDialog();
                } else if (value == 'update_payment') {
                  _showPaymentUpdateDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'update_status',
                  child: Row(
                    children: [
                      Icon(Icons.update, size: 20, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text('Update Status', style: GoogleFonts.inter()),
                    ],
                  ),
                ),
                if (_currentOrder.balanceAmount > 0)
                  PopupMenuItem(
                    value: 'update_payment',
                    child: Row(
                      children: [
                        Icon(Icons.payment, size: 20, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Text('Add Payment', style: GoogleFonts.inter()),
                      ],
                    ),
                  ),
              ],
              icon: const Icon(Icons.more_vert, color: Colors.white),
            ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                _buildOrderHeader(),
                const SizedBox(height: 20),
                
                // Customer & Service Details
                _buildCustomerDetails(),
                const SizedBox(height: 20),
                
                // Financial Information
                _buildFinancialInfo(),
                const SizedBox(height: 20),
                
                // Order Timeline
                _buildOrderTimeline(),
                const SizedBox(height: 20),
                
                // Measurements
                if (_currentOrder.measurements.isNotEmpty)
                  _buildMeasurements(),
                
                const SizedBox(height: 20),
                
                // Additional Details
                _buildAdditionalDetails(),
                const SizedBox(height: 30),
                
                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentOrder.uniqueId,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order ID',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(_currentOrder.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(_currentOrder.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  _currentOrder.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(_currentOrder.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getStatusDescription(_currentOrder.status),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer & Service Details',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Customer ID', _currentOrder.customerId, Icons.person),
          _buildDetailRow('Service Type', _currentOrder.serviceType, Icons.build),
          _buildDetailRow('Tailor ID', _currentOrder.tailorId, Icons.person_outline),
          if (_currentOrder.designImageUrl != null && _currentOrder.designImageUrl!.isNotEmpty)
            _buildDetailRow('Design Image', 'Available', Icons.image),
        ],
      ),
    );
  }

  Widget _buildFinancialInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Information',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(
                  'Total Amount',
                  '₹${_currentOrder.totalAmount.toStringAsFixed(0)}',
                  Colors.blue,
                  Icons.receipt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinancialCard(
                  'Advance Paid',
                  '₹${_currentOrder.advancePaid.toStringAsFixed(0)}',
                  Colors.green,
                  Icons.payment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFinancialCard(
            'Balance Due',
            '₹${_currentOrder.balanceAmount.toStringAsFixed(0)}',
            _currentOrder.balanceAmount > 0 ? Colors.red : Colors.green,
            Icons.account_balance_wallet,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Timeline',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            'Order Created',
            _currentOrder.createdAt.toString().substring(0, 16),
            Icons.add_circle,
            Colors.blue,
            isCompleted: true,
          ),
          _buildTimelineItem(
            'Delivery Date',
            _currentOrder.deliveryDate.toString().substring(0, 16),
            Icons.local_shipping,
            Colors.orange,
            isCompleted: DateTime.now().isAfter(_currentOrder.deliveryDate),
          ),
          _buildTimelineItem(
            'Last Updated',
            _currentOrder.updatedAt.toString().substring(0, 16),
            Icons.update,
            Colors.grey,
            isCompleted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurements() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Measurements',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _currentOrder.measurements.entries.map((entry) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${entry.value}\"',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Payment Status', _currentOrder.paymentStatus, Icons.payment),
          _buildDetailRow('Delivery Date', _currentOrder.deliveryDate.toString().substring(0, 10), Icons.calendar_today),
          if (_currentOrder.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Notes:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _currentOrder.notes,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentOrder.status.toLowerCase() == 'completed' || 
        _currentOrder.status.toLowerCase() == 'cancelled') {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showStatusUpdateDialog,
        icon: const Icon(Icons.update),
        label: Text(
          'Update Order Status',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getStatusColor(_currentOrder.status),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(String label, String amount, Color color, IconData icon, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isFullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: isFullWidth ? 20 : 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String date, IconData icon, Color color, {required bool isCompleted}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? color : color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentUpdateDialog() {
    final TextEditingController paymentController = TextEditingController();
    final remainingAmount = _currentOrder.totalAmount - _currentOrder.advancePaid;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Payment',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount: ₹${_currentOrder.totalAmount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              'Paid Amount: ₹${_currentOrder.advancePaid.toStringAsFixed(0)}',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              'Remaining: ₹${remainingAmount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 14, 
                fontWeight: FontWeight.w600,
                color: remainingAmount > 0 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paymentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Add Payment Amount',
                prefixText: '₹',
                border: const OutlineInputBorder(),
                hintText: 'Enter amount to add',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(paymentController.text);
              if (amount != null && amount > 0) {
                _updatePayment(amount);
                Navigator.pop(context);
              }
            },
            child: Text('Add Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePayment(double additionalPayment) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newAdvancePaid = _currentOrder.advancePaid + additionalPayment;
      final newBalanceAmount = _currentOrder.totalAmount - newAdvancePaid;
      
      // Update in database
      await _dbService.updateOrder(_currentOrder.uniqueId, {
        'advance_paid': newAdvancePaid,
        'balance_amount': newBalanceAmount,
        'payment_status': newBalanceAmount <= 0 ? 'paid' : 'partial',
      });
      
      // Update local order object
      _currentOrder = Order(
        id: _currentOrder.id,
        uniqueId: _currentOrder.uniqueId,
        customerId: _currentOrder.customerId,
        tailorId: _currentOrder.tailorId,
        serviceType: _currentOrder.serviceType,
        status: _currentOrder.status,
        paymentStatus: newBalanceAmount <= 0 ? 'paid' : 'partial',
        deliveryDate: _currentOrder.deliveryDate,
        notes: _currentOrder.notes,
        designImageUrl: _currentOrder.designImageUrl,
        totalAmount: _currentOrder.totalAmount,
        advancePaid: newAdvancePaid,
        balanceAmount: newBalanceAmount,
        measurements: _currentOrder.measurements,
        createdAt: _currentOrder.createdAt,
        updatedAt: DateTime.now(),
        isDeleted: _currentOrder.isDeleted,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ₹${additionalPayment.toStringAsFixed(0)} added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('OrderDetailScreen', 'Failed to update payment', 
                   error: e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update payment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}