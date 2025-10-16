import 'package:flutter/material.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/enums/payment_method.dart';
import '../../../data/services/local_db_service.dart';
import '../../../widgets/custom_header.dart';
import '../../../widgets/custom_bottom_navigation.dart';
import '../../../core/utils/logger.dart';
import '../../../core/mixins/navigation_mixin.dart';
import '../../../core/translations/app_localizations.dart';
import '../../../core/providers/simple_locale_provider.dart';
import '../../orders/widgets/sub_header.dart';
import '../../../routes/route_names.dart';
import 'package:tailer_app/core/constants/app_constants.dart';


class OrderPaymentHistoryScreen extends StatefulWidget {
  final String orderId;
  final Order? order;

  const OrderPaymentHistoryScreen({
    super.key,
    required this.orderId,
    this.order,
  });

  @override
  State<OrderPaymentHistoryScreen> createState() => _OrderPaymentHistoryScreenState();
}

class _OrderPaymentHistoryScreenState extends State<OrderPaymentHistoryScreen> with NavigationMixin {
  int _currentNavIndex = 2; // Orders section
  late SimpleLocaleProvider _localeProvider;
  final LocalDatabaseService _dbService = LocalDatabaseService();
  
  List<Payment> _payments = [];
  Order? _orderDetails;
  Map<String, dynamic>? _customerDetails;
  bool _isLoading = true;
  double _totalPaid = 0.0;
  double _balanceAmount = 0.0;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _loadPaymentHistory();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        context.goNamed(RouteNames.dashboard);
        break;
      case 1:
        context.goNamed(RouteNames.customers);
        break;
      case 2:
        context.goNamed(RouteNames.orders);
        break;
      case 3:
        context.goNamed(RouteNames.settings);
        break;
    }
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('OrderPaymentHistoryScreen', 'Loading payment history for order: ${widget.orderId}');

      // Load order details if not provided
      if (widget.order != null) {
        _orderDetails = widget.order;
      } else {
        final orderMaps = await _dbService.select(
          'orders',
          where: 'unique_id = ? AND is_deleted = 0',
          whereArgs: [widget.orderId],
          limit: 1,
        );
        
        if (orderMaps.isNotEmpty) {
          _orderDetails = Order.fromMap(orderMaps.first);
        }
      }

      if (_orderDetails == null) {
        throw Exception('Order not found: ${widget.orderId}');
      }

      // Load customer details
      final customerMaps = await _dbService.select(
        'customer',
        where: 'id = ?',
        whereArgs: [_orderDetails!.customerId],
        limit: 1,
      );

      if (customerMaps.isNotEmpty) {
        _customerDetails = customerMaps.first;
      }

      // Load payments for this order
      _payments = await _dbService.getPaymentsByOrderId(widget.orderId);
      
      // Calculate totals
      _totalPaid = _payments.fold(0.0, (sum, payment) => sum + payment.amount);
      _balanceAmount = _orderDetails!.totalAmount - _totalPaid;

      Logger.info('OrderPaymentHistoryScreen', 
        'Loaded ${_payments.length} payments, Total: ₹$_totalPaid, Balance: ₹$_balanceAmount');

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Logger.error('OrderPaymentHistoryScreen', 'Failed to load payment history', 
                   error: e, stackTrace: stackTrace);
      
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payment history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAndSharePdf() async {
    if (_orderDetails == null || _payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payment data available to generate PDF'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      Logger.info('OrderPaymentHistoryScreen', 'Generating PDF for order: ${widget.orderId}');

      final pdf = pw.Document();
      
      // Add page with payment history
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              _buildPdfHeader(),
              pw.SizedBox(height: 20),
              
              // Order Details
              _buildPdfOrderDetails(),
              pw.SizedBox(height: 20),
              
              // Customer Details
              if (_customerDetails != null) _buildPdfCustomerDetails(),
              if (_customerDetails != null) pw.SizedBox(height: 20),
              
              // Payment History Table
              _buildPdfPaymentTable(),
              pw.SizedBox(height: 20),
              
              // Summary
              _buildPdfSummary(),
              pw.SizedBox(height: 30),
              
              // Footer
              _buildPdfFooter(),
            ];
          },
        ),
      );

      // Save and share PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'payment_history_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      Logger.info('OrderPaymentHistoryScreen', 'PDF generated and shared successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment history PDF generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('OrderPaymentHistoryScreen', 'Failed to generate PDF', 
                   error: e, stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  pw.Widget _buildPdfHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(400),
              1: const pw.FixedColumnWidth(150),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Text(
                    'PAYMENT HISTORY REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${DateTime.now().toString().substring(0, 19)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Tailor Management System',
            style: pw.TextStyle(
              fontSize: 16,
              color: PdfColors.blue600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfOrderDetails() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ORDER DETAILS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(275),
              1: const pw.FixedColumnWidth(275),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfDetailRow('Order ID:', _orderDetails!.uniqueId),
                      _buildPdfDetailRow('Service Type:', _orderDetails!.serviceType),
                      _buildPdfDetailRow('Status:', _orderDetails!.status.toUpperCase()),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfDetailRow('Order Date:', _orderDetails!.createdAt.toString().substring(0, 10)),
                      _buildPdfDetailRow('Delivery Date:', _orderDetails!.deliveryDate.toString().substring(0, 10)),
                      _buildPdfDetailRow('Total Amount:', '₹${_orderDetails!.totalAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfCustomerDetails() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CUSTOMER DETAILS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(275),
              1: const pw.FixedColumnWidth(275),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfDetailRow('Name:', _customerDetails!['name'] ?? 'N/A'),
                      _buildPdfDetailRow('Phone:', _customerDetails!['phone'] ?? 'N/A'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfDetailRow('Email:', _customerDetails!['email'] ?? 'N/A'),
                      _buildPdfDetailRow('Address:', _customerDetails!['address'] ?? 'N/A'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfPaymentTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PAYMENT HISTORY',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(120), // Date
            1: const pw.FixedColumnWidth(80), // Amount
            2: const pw.FixedColumnWidth(80), // Method
            3: const pw.FixedColumnWidth(150), // Notes
            4: const pw.FixedColumnWidth(120), // Transaction ID
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildPdfTableCell('Date & Time', isHeader: true),
                _buildPdfTableCell('Amount', isHeader: true),
                _buildPdfTableCell('Method', isHeader: true),
                _buildPdfTableCell('Notes', isHeader: true),
                _buildPdfTableCell('Transaction ID', isHeader: true),
              ],
            ),
            // Payments
            ..._payments.map((payment) => pw.TableRow(
              children: [
                _buildPdfTableCell(payment.paidOn.toString().substring(0, 19)),
                _buildPdfTableCell('₹${payment.amount.toStringAsFixed(2)}'),
                _buildPdfTableCell(payment.method.displayName),
                _buildPdfTableCell(payment.notes.isEmpty ? '-' : payment.notes),
                _buildPdfTableCell(payment.transactionId ?? '-'),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfSummary() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PAYMENT SUMMARY',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(275),
              1: const pw.FixedColumnWidth(275),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfDetailRow('Total Order Amount:', '₹${_orderDetails!.totalAmount.toStringAsFixed(2)}'),
                      _buildPdfDetailRow('Total Payments:', '${_payments.length} transactions'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfDetailRow('Amount Paid:', '₹${_totalPaid.toStringAsFixed(2)}'),
                      _buildPdfDetailRow(
                        'Balance:', 
                        '₹${_balanceAmount.toStringAsFixed(2)}',
                        valueColor: _balanceAmount > 0 ? PdfColors.red600 : PdfColors.green600,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'This is a computer-generated report. No signature required.',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'For any queries, please contact our support team.',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDetailRow(String label, String value, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              color: valueColor ?? PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.grey800 : PdfColors.grey700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        final navItems = [
          BottomNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: locale.t('dashboard'),
          ),
          BottomNavItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: locale.t('customers'),
          ),
          BottomNavItem(
            icon: Icons.shopping_bag_outlined,
            activeIcon: Icons.shopping_bag,
            label: locale.t('orders'),
          ),
          BottomNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: locale.t('settings'),
          ),
        ];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: DashboardHeader(
            title: 'Payment History',
            backgroundColor: AppColors.secondary,
            notificationCount: 0,
            onBackPressed: () => Navigator.of(context).pop(),
            onNotificationTap: () {
              showNavigationMessage(context, locale.t('notifications'));
            },
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 15),
                // Sub-header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SubHeaderStyles.feature(
                    icon: Icons.history,
                    title: 'Order Payment History',
                    subtitle: 'View Payments • Order #${widget.orderId} • Transaction Details',
                    action: !_isLoading && _payments.isNotEmpty
                        ? IconButton(
                            onPressed: _isGeneratingPdf ? null : _generateAndSharePdf,
                            icon: _isGeneratingPdf 
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                                    ),
                                  )
                                : Icon(Icons.picture_as_pdf, color: AppColors.secondary, size: 20),
                            tooltip: 'Generate PDF',
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Main Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildBody(),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AnimatedBottomNavigation(
            currentIndex: _currentNavIndex,
            onTap: _onNavTap,
            items: navItems,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(AppConstants.primaryTeal),
            unselectedItemColor: Colors.grey.shade600,
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_orderDetails == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Order not found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Order Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order ${_orderDetails!.uniqueId}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_orderDetails!.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _orderDetails!.status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(_orderDetails!.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_customerDetails != null) ...[
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      _customerDetails!['name'] ?? 'Unknown Customer',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      _customerDetails!['phone'] ?? 'No Phone',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  _buildSummaryItem(
                    'Total Amount',
                    '₹${_orderDetails!.totalAmount.toStringAsFixed(0)}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 20),
                  _buildSummaryItem(
                    'Amount Paid',
                    '₹${_totalPaid.toStringAsFixed(0)}',
                    Colors.green,
                  ),
                  const SizedBox(width: 20),
                  _buildSummaryItem(
                    'Balance',
                    '₹${_balanceAmount.toStringAsFixed(0)}',
                    _balanceAmount > 0 ? Colors.red : Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Payments List
        Expanded(
          child: _payments.isEmpty ? _buildEmptyState() : _buildPaymentsList(),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No payments found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'No payments have been recorded for this order yet.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return _buildPaymentCard(payment, index);
      },
    );
  }

  Widget _buildPaymentCard(Payment payment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getPaymentMethodColor(payment.method).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPaymentMethodIcon(payment.method),
                      size: 18,
                      color: _getPaymentMethodColor(payment.method),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment #${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        payment.method.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '₹${payment.amount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                '${payment.paidOn.toString().substring(0, 10)} at ${payment.paidOn.toString().substring(11, 16)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          if (payment.transactionId != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.confirmation_number, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'TXN: ${payment.transactionId}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
          if (payment.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    payment.notes,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
      case 'cutting':
      case 'stitching':
      case 'finishing':
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
}