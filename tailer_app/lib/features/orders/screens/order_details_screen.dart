import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/simple_locale_provider.dart';
import '../../../core/translations/app_localizations.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/local_db_service.dart';
import '../../../core/utils/logger.dart';
import '../../../routes/route_names.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;

  const OrderDetailsScreen({super.key, this.extra});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  
  Order? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  @override
  void dispose() {
    // Don't dispose singleton _localeProvider
    super.dispose();
  }

  void _loadOrderDetails() {
    try {
      if (widget.extra != null && widget.extra!['order'] != null) {
        final orderData = widget.extra!['order'] as Map<String, dynamic>;
        _order = Order.fromMap(orderData);
      }
    } catch (e, stackTrace) {
      Logger.error('OrderDetailsScreen', 'Failed to load order details', error: e, stackTrace: stackTrace);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editOrder() {
    if (_order != null) {
      context.pushNamed(
        RouteNames.editOrder,
        extra: {'order': _order!.toMap()},
      );
    }
  }

  void _deleteOrder() async {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.t('confirmDelete')),
        content: Text('${locale.t('confirmDeleteOrder')} ${_order?.uniqueId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(locale.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(locale.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && _order != null) {
      try {
        await _dbService.deleteOrder(_order!.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locale.t('orderDeletedSuccessfully')),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${locale.t('failedToDeleteOrder')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: const Color(AppConstants.primaryTeal),
            foregroundColor: Colors.white,
            title: Text(
              _order?.uniqueId ?? locale.t('orderDetails'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            elevation: 0,
            actions: [
              if (_order != null) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editOrder,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteOrder,
                ),
              ],
            ],
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(AppConstants.primaryTeal),
                    ),
                  ),
                )
              : _order == null
                  ? _buildErrorState(locale)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOrderHeader(locale),
                          const SizedBox(height: 16),
                          _buildOrderInfo(locale),
                          const SizedBox(height: 16),
                          _buildAmountDetails(locale),
                          const SizedBox(height: 16),
                          _buildMeasurements(locale),
                          if (_order!.notes.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildNotes(locale),
                          ],
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildErrorState(AppLocalizations locale) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              locale.t('orderDetailsNotAvailable'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryTeal),
                foregroundColor: Colors.white,
              ),
              child: Text(locale.t('back')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(AppLocalizations locale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _order!.uniqueId,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(AppConstants.primaryTeal),
                    ),
                  ),
                ),
                const Spacer(),
                _buildStatusChip(_order!.status, locale),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _order!.serviceType,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo(AppLocalizations locale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.t('orderDetails'),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              locale.t('orderDate'),
              _formatDate(_order!.createdAt),
              Icons.calendar_today,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              locale.t('deliveryDate'),
              _formatDate(_order!.deliveryDate),
              Icons.schedule,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              locale.t('customerId'),
              _order!.customerId,
              Icons.person,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountDetails(AppLocalizations locale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.t('amountDetails'),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildAmountRow(
              locale.t('totalAmount'),
              _order!.totalAmount,
              Colors.blue.shade700,
            ),
            const Divider(height: 24),
            _buildAmountRow(
              locale.t('advanceAmount'),
              _order!.advancePaid,
              Colors.green.shade700,
            ),
            const Divider(height: 24),
            _buildAmountRow(
              locale.t('balanceAmount'),
              _order!.balanceAmount,
              _order!.balanceAmount > 0 ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurements(AppLocalizations locale) {
    if (_order!.measurements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.t('measurements'),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ..._order!.measurements.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${entry.value}"',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes(AppLocalizations locale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.t('notes'),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _order!.notes,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
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
              const SizedBox(height: 2),
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
    );
  }

  Widget _buildAmountRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, AppLocalizations locale) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        displayText = locale.t('pending');
        break;
      case 'in_progress':
      case 'inprogress':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        displayText = locale.t('inProgress');
        break;
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        displayText = locale.t('completed');
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        displayText = locale.t('cancelled');
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}