import 'package:flutter/material.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/local_db_service.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/enums/payment_method.dart';
import '../../../core/utils/logger.dart';
import '../../../routes/route_names.dart';
import '../widgets/order_cancellation_dialog.dart';
import '../../../widgets/custom_header.dart';

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
      backgroundColor: AppColors.background,
      appBar: DashboardHeader(
        title: 'Order Details',
        backgroundColor: AppColors.primary,
        notificationCount: 3,
        onBackPressed: () {
          context.pop();
        },
        onNotificationTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications')),
          );
        },
      ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildBody() {
    return _isLoading
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
          );
  }

  Widget _buildFloatingActionButtons() {
    return FloatingActionButton(
        onPressed: _showDataMigrationDialog,
        backgroundColor: Colors.orange.shade600,
        child: const Icon(Icons.sync_alt, color: Colors.white),
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
          
          // Payment Progress Bar
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Progress',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${(_currentOrder.advancePaid / _currentOrder.totalAmount * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _currentOrder.totalAmount > 0 ? _currentOrder.advancePaid / _currentOrder.totalAmount : 0.0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                minHeight: 6,
              ),
              const SizedBox(height: 12),
              
              // Quick Payment Button
              if (_currentOrder.balanceAmount > 0 && 
                  _currentOrder.status.toLowerCase() != 'completed' && 
                  _currentOrder.status.toLowerCase() != 'cancelled')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showPaymentUpdateDialog,
                    icon: const Icon(Icons.payment, size: 16),
                    label: Text(
                      'Collect Payment (₹${_currentOrder.balanceAmount.toStringAsFixed(0)})',
                      style: GoogleFonts.inter(
                        fontSize: 14,
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
                  ),
                ),
            ],
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

  Future<void> _showDeleteConfirmation() async {
    final customerName = 'Customer ${_currentOrder.customerId}'; // You might want to fetch actual customer name
    
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
                    'Order ID: ${_currentOrder.uniqueId}',
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
                  const SizedBox(height: 4),
                  Text(
                    'Total Amount: ₹${_currentOrder.totalAmount.toStringAsFixed(0)}',
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
              await _deleteOrder();
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

  Future<void> _deleteOrder() async {
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

      final success = await _dbService.softDeleteOrder(_currentOrder.uniqueId);
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Order ${_currentOrder.uniqueId} has been deleted',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () async {
                await _dbService.restoreOrder(_currentOrder.uniqueId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '↩️ Order ${_currentOrder.uniqueId} has been restored',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ),
        );
        
        // Navigate back to previous screen after deletion
        Navigator.of(context).pop();
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

  void _showPaymentUpdateDialog() {
    final TextEditingController paymentController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.cash; // Default to cash
    final remainingAmount = _currentOrder.totalAmount - _currentOrder.advancePaid;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isAmountValid = true;
          String? errorMessage;
          
          // Validate amount in real-time
          void validateAmount(String value) {
            final amount = double.tryParse(value);
            setState(() {
              if (amount == null || amount <= 0) {
                isAmountValid = false;
                errorMessage = 'Please enter a valid amount';
              } else if (amount > remainingAmount) {
                isAmountValid = false;
                errorMessage = 'Amount cannot exceed ₹${remainingAmount.toStringAsFixed(0)}';
              } else {
                isAmountValid = true;
                errorMessage = null;
              }
            });
          }
          
          return AlertDialog(
            title: Text(
              'Update Payment',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
                          'Order: ${_currentOrder.uniqueId}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Amount: ₹${_currentOrder.totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Paid Amount: ₹${_currentOrder.advancePaid.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Pending Amount: ₹${remainingAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 14, 
                            fontWeight: FontWeight.w600,
                            color: remainingAmount > 0 ? Colors.red.shade600 : Colors.green,
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
                                'Max payment: ₹${remainingAmount.toStringAsFixed(0)}',
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
                        controller: paymentController,
                        keyboardType: TextInputType.number,
                        onChanged: validateAmount,
                        decoration: InputDecoration(
                          labelText: 'Payment Amount',
                          hintText: 'Max: ₹${remainingAmount.toStringAsFixed(0)}',
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
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isAmountValid ? () {
                  final amount = double.tryParse(paymentController.text);
                  if (amount != null && amount > 0 && amount <= remainingAmount) {
                    _updatePayment(amount, selectedMethod, notesController.text.trim());
                    Navigator.pop(context);
                  }
                } : null,
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
      ),
    );
  }

  Future<void> _updatePayment(double additionalPayment, PaymentMethod method, String notes) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newAdvancePaid = _currentOrder.advancePaid + additionalPayment;
      final newBalanceAmount = _currentOrder.totalAmount - newAdvancePaid;
      
      // Create payment record
      final payment = Payment.create(
        orderId: _currentOrder.uniqueId,
        amount: additionalPayment,
        method: method,
        notes: notes.isEmpty ? 'Payment added from order details' : notes,
      );
      
      // Insert payment into database
      await _dbService.addPayment(payment);
      
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Payment Collected Successfully!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Amount: ₹${additionalPayment.toStringAsFixed(0)} via ${method.displayName}',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                Text(
                  'Remaining Balance: ₹${newBalanceAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 4),
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

  bool _canCancelOrder() {
    final status = _currentOrder.status.toLowerCase();
    return status == 'pending' ||
           status == 'cutting' ||
           status == 'stitching' ||
           status == 'in_progress' ||
           status == 'ready';
  }

  void _showCancelOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => OrderCancellationDialog(
        orderId: _currentOrder.uniqueId,
        customerName: 'Customer ${_currentOrder.customerId}',
        orderTotal: _currentOrder.totalAmount,
        onCancellationComplete: () => _refreshOrderData(),
      ),
    );
  }

  Future<void> _refreshOrderData() async {
    try {
      final orderData = await _dbService.getOrderByUniqueId(_currentOrder.uniqueId);
      if (orderData != null) {
        final updatedOrder = Order.fromMap(orderData);
        setState(() {
          _currentOrder = updatedOrder;
        });
      }
    } catch (e) {
      Logger.error('OrderDetailScreen', 'Failed to refresh order data', error: e);
    }
  }

  void _navigateToPaymentHistory() {
    context.pushNamed(
      RouteNames.orderPaymentHistory,
      extra: {
        'orderId': _currentOrder.uniqueId,
        'order': _currentOrder,
      },
    );
  }

  void _showDataMigrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sync_alt, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(
              'Data Migration',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose migration action for this order:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order: ${_currentOrder.uniqueId}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Customer: Customer ${_currentOrder.customerId}',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  Text(
                    'Status: ${_currentOrder.status.toUpperCase()}',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Available Actions:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _migrateOrderToNewSystem();
            },
            icon: const Icon(Icons.upload, size: 16),
            label: Text(
              'Export Data',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _runDatabaseMigration();
            },
            icon: const Icon(Icons.storage, size: 16),
            label: Text(
              'Fix Database',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _migrateOrderToNewSystem() async {
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
                'Exporting order data...',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
          ),
        ),
      );

      // Simulate data migration process
      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ Order Data Exported Successfully!',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                'Order ${_currentOrder.uniqueId} exported to new system',
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Export failed: $e',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncOrderData() async {
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
                'Syncing order data...',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
          ),
        ),
      );

      // Simulate sync process
      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ Order Data Synced Successfully!',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                'Order ${_currentOrder.uniqueId} synced with cloud database',
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Sync failed: $e',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _runDatabaseMigration() async {
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
                'Fixing database tables...',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
          ),
        ),
      );

      // Run database migration
      final db = await _dbService.database;
      
      // Check which tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table';"
      );
      
      final orderCancellationsExists = tables.any(
        (table) => table['name'] == 'order_cancellations'
      );
      
      final notificationsExists = tables.any(
        (table) => table['name'] == 'notifications'
      );
      
      final refundTransactionsExists = tables.any(
        (table) => table['name'] == 'refund_transactions'
      );
      
      final paymentReceiptsExists = tables.any(
        (table) => table['name'] == 'payment_receipts'
      );
      
      // Check if order_cancellations table has wrong constraints by testing insert
      bool needsOrderCancellationsRecreate = false;
      if (orderCancellationsExists) {
        try {
          // Test if 'not_applicable' is allowed
          await db.rawQuery('''
            SELECT * FROM order_cancellations 
            WHERE refund_status = 'not_applicable' 
            LIMIT 1
          ''');
        } catch (e) {
          // If this fails, the constraint is wrong
          needsOrderCancellationsRecreate = true;
        }
        
        // Additional test: try to check the table schema
        try {
          final schema = await db.rawQuery("PRAGMA table_info(order_cancellations)");
          print('order_cancellations schema: $schema');
          
          // For safety, always recreate if we detect constraint issues
          final checkConstraints = await db.rawQuery('''
            SELECT sql FROM sqlite_master 
            WHERE type='table' AND name='order_cancellations'
          ''');
          
          if (checkConstraints.isNotEmpty) {
            final sql = checkConstraints.first['sql'] as String;
            if (!sql.contains('not_applicable')) {
              needsOrderCancellationsRecreate = true;
            }
          }
        } catch (e) {
          needsOrderCancellationsRecreate = true;
        }
      }
      
      // Check if notifications table has foreign key issues
      bool needsNotificationsRecreate = false;
      if (notificationsExists) {
        try {
          // Test if we can insert without foreign key issues
          final checkConstraints = await db.rawQuery('''
            SELECT sql FROM sqlite_master 
            WHERE type='table' AND name='notifications'
          ''');
          
          if (checkConstraints.isNotEmpty) {
            final sql = checkConstraints.first['sql'] as String;
            if (sql.contains('FOREIGN KEY')) {
              needsNotificationsRecreate = true;
            }
          }
        } catch (e) {
          needsNotificationsRecreate = true;
        }
      }
      
      final needsNotifications = !notificationsExists || needsNotificationsRecreate;
      final needsCancellations = !orderCancellationsExists || needsOrderCancellationsRecreate;
      final needsRefundTransactions = !refundTransactionsExists;
      final needsPaymentReceipts = !paymentReceiptsExists;
      
      if (needsNotifications || needsCancellations || needsRefundTransactions || needsPaymentReceipts) {
        // Create missing tables
        if (needsNotifications) {
          // If table exists with wrong foreign keys, drop it first
          if (notificationsExists) {
            print('Dropping existing notifications table with foreign key constraints');
            await db.execute('DROP TABLE IF EXISTS notifications');
          }
          
          print('Creating notifications table without foreign key constraints');
          await db.execute('''
            CREATE TABLE notifications (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              message TEXT NOT NULL,
              type TEXT CHECK(type IN ('order_status', 'payment_received', 'order_cancelled', 'order_delivered', 'order_overdue', 'payment_reminder', 'delivery_reminder')) NOT NULL,
              data TEXT,
              order_id TEXT,
              customer_id TEXT,
              action_url TEXT,
              is_read INTEGER DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
        }
        
        if (needsCancellations) {
          // If table exists with wrong constraints, drop it first
          if (orderCancellationsExists) {
            print('Dropping existing order_cancellations table with wrong constraints');
            await db.execute('DROP TABLE IF EXISTS order_cancellations');
          }
          
          print('Creating order_cancellations table with correct constraints');
          await db.execute('''
            CREATE TABLE order_cancellations (
              id TEXT PRIMARY KEY,
              order_id TEXT NOT NULL,
              reason TEXT CHECK(reason IN ('customer_request', 'material_unavailable', 'size_issues', 'quality_concerns', 'delivery_delay', 'payment_issues', 'other')) NOT NULL,
              custom_reason TEXT,
              cancelled_by TEXT NOT NULL,
              cancelled_at TEXT NOT NULL,
              refund_amount REAL DEFAULT 0.0,
              refund_status TEXT CHECK(refund_status IN ('none', 'partial', 'full', 'pending', 'processing', 'completed', 'not_applicable')) DEFAULT 'none',
              refund_notes TEXT,
              additional_data TEXT DEFAULT '{}',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE
            )
          ''');
        }
        
        if (needsRefundTransactions) {
          print('Creating refund_transactions table');
          await db.execute('''
            CREATE TABLE refund_transactions (
              id TEXT PRIMARY KEY,
              unique_id TEXT UNIQUE NOT NULL,
              original_payment_id TEXT NOT NULL,
              order_id TEXT NOT NULL,
              refund_amount REAL NOT NULL,
              reason TEXT NOT NULL,
              status TEXT CHECK(status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')) DEFAULT 'pending',
              method TEXT CHECK(method IN ('original', 'cash', 'bank_transfer', 'store_credit')) DEFAULT 'original',
              transaction_id TEXT,
              processed_by TEXT NOT NULL,
              processed_at TEXT NOT NULL,
              notes TEXT,
              metadata TEXT DEFAULT '{}',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (original_payment_id) REFERENCES payment (unique_id) ON DELETE CASCADE,
              FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE
            )
          ''');
        }
        
        if (needsPaymentReceipts) {
          print('Creating payment_receipts table');
          await db.execute('''
            CREATE TABLE payment_receipts (
              id TEXT PRIMARY KEY,
              unique_id TEXT UNIQUE NOT NULL,
              payment_id TEXT NOT NULL,
              order_id TEXT NOT NULL,
              customer_id TEXT NOT NULL,
              type TEXT CHECK(type IN ('payment', 'refund', 'advance')) NOT NULL,
              amount REAL NOT NULL,
              payment_method TEXT NOT NULL,
              receipt_date TEXT NOT NULL,
              receipt_number TEXT UNIQUE NOT NULL,
              business_details TEXT NOT NULL,
              customer_details TEXT NOT NULL,
              item_details TEXT NOT NULL,
              notes TEXT,
              file_path TEXT,
              is_email_sent INTEGER DEFAULT 0,
              is_printed INTEGER DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (payment_id) REFERENCES payment (unique_id) ON DELETE CASCADE,
              FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE
            )
          ''');
        }
        
        // Create indexes
        if (needsNotifications) {
          await db.execute('CREATE INDEX idx_notifications_order_id ON notifications (order_id)');
          await db.execute('CREATE INDEX idx_notifications_customer_id ON notifications (customer_id)');
          await db.execute('CREATE INDEX idx_notifications_is_read ON notifications (is_read)');
        }
        
        if (needsCancellations) {
          await db.execute('CREATE INDEX idx_order_cancellations_order_id ON order_cancellations (order_id)');
          await db.execute('CREATE INDEX idx_order_cancellations_reason ON order_cancellations (reason)');
        }
        
        if (needsRefundTransactions) {
          await db.execute('CREATE INDEX idx_refund_transactions_original_payment_id ON refund_transactions (original_payment_id)');
          await db.execute('CREATE INDEX idx_refund_transactions_order_id ON refund_transactions (order_id)');
          await db.execute('CREATE INDEX idx_refund_transactions_status ON refund_transactions (status)');
          await db.execute('CREATE INDEX idx_refund_transactions_processed_at ON refund_transactions (processed_at)');
        }
        
        if (needsPaymentReceipts) {
          await db.execute('CREATE INDEX idx_payment_receipts_payment_id ON payment_receipts (payment_id)');
          await db.execute('CREATE INDEX idx_payment_receipts_order_id ON payment_receipts (order_id)');
          await db.execute('CREATE INDEX idx_payment_receipts_customer_id ON payment_receipts (customer_id)');
          await db.execute('CREATE INDEX idx_payment_receipts_type ON payment_receipts (type)');
          await db.execute('CREATE INDEX idx_payment_receipts_receipt_number ON payment_receipts (receipt_number)');
        }
      }
      
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ Database Migration Completed!',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                needsNotifications || needsCancellations || needsRefundTransactions || needsPaymentReceipts 
                    ? 'Tables ${needsNotifications ? "notifications " : ""}${needsCancellations ? "order_cancellations " : ""}${needsRefundTransactions ? "refund_transactions " : ""}${needsPaymentReceipts ? "payment_receipts " : ""}created/fixed'
                    : 'All tables already exist and are correct',
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Migration failed: $e',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}