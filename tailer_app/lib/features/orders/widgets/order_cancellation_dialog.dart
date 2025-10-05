import 'package:flutter/material.dart';
import '../../../data/enums/order_enums.dart';
import '../../../data/services/order_cancellation_service.dart';
import '../../../core/utils/logger.dart';

/// Dialog for cancelling an order
class OrderCancellationDialog extends StatefulWidget {
  final String orderId;
  final String customerName;
  final double orderTotal;
  final VoidCallback? onCancellationComplete;

  const OrderCancellationDialog({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.orderTotal,
    this.onCancellationComplete,
  });

  @override
  State<OrderCancellationDialog> createState() => _OrderCancellationDialogState();
}

class _OrderCancellationDialogState extends State<OrderCancellationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customReasonController = TextEditingController();
  final _refundAmountController = TextEditingController();
  final _refundNotesController = TextEditingController();
  final OrderCancellationService _cancellationService = OrderCancellationService();

  CancellationReason _selectedReason = CancellationReason.customerRequest;
  bool _isProcessing = false;
  bool _refundRequired = false;

  @override
  void initState() {
    super.initState();
    _refundAmountController.text = widget.orderTotal.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    _refundAmountController.dispose();
    _refundNotesController.dispose();
    super.dispose();
  }

  Future<void> _processCancellation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final customReason = _selectedReason == CancellationReason.other
          ? _customReasonController.text.trim()
          : null;

      final refundAmount = _refundRequired
          ? double.tryParse(_refundAmountController.text) ?? 0.0
          : 0.0;

      final refundNotes = _refundRequired && _refundNotesController.text.isNotEmpty
          ? _refundNotesController.text.trim()
          : null;

      await _cancellationService.cancelOrder(
        orderId: widget.orderId,
        reason: _selectedReason,
        customReason: customReason,
        cancelledBy: 'tailor_001', // TODO: Get from current user context
        refundAmount: refundAmount,
        refundNotes: refundNotes,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onCancellationComplete?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${widget.orderId} has been cancelled successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('OrderCancellationDialog', 'Failed to cancel order', 
                   error: e, stackTrace: stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text('Cancel Order'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order: ${widget.orderId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Customer: ${widget.customerName}'),
                      Text('Total: ₹${widget.orderTotal.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cancellation reason
                const Text(
                  'Reason for Cancellation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CancellationReason>(
                  value: _selectedReason,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: CancellationReason.values.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a cancellation reason';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Custom reason field
                if (_selectedReason == CancellationReason.other) ...[
                  TextFormField(
                    controller: _customReasonController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Reason',
                      border: OutlineInputBorder(),
                      hintText: 'Please specify the reason for cancellation',
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (_selectedReason == CancellationReason.other &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please provide a custom reason';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Refund section
                CheckboxListTile(
                  title: const Text('Refund Required'),
                  subtitle: const Text('Check if customer paid and needs refund'),
                  value: _refundRequired,
                  onChanged: (value) {
                    setState(() {
                      _refundRequired = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                if (_refundRequired) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _refundAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Refund Amount (₹)',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_refundRequired) {
                        final amount = double.tryParse(value ?? '');
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid refund amount';
                        }
                        if (amount > widget.orderTotal) {
                          return 'Refund amount cannot exceed order total';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _refundNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Refund Notes (Optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Additional notes about the refund',
                    ),
                    maxLines: 2,
                  ),
                ],

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This action cannot be undone. The order will be marked as cancelled.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processCancellation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cancel Order'),
        ),
      ],
    );
  }
}