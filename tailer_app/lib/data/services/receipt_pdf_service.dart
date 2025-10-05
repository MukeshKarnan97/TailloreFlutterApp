import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tailer_app/core/utils/logger.dart';
import '../models/payment_model.dart';

/// Service for generating PDF receipts
class ReceiptPdfService {
  
  /// Generate order-based receipt PDF
  static Future<void> generateOrderReceipt({
    required Map<String, dynamic> orderData,
    required Map<String, dynamic>? customerData,
    required List<Payment> payments,
  }) async {
    try {
      Logger.info('ReceiptPdfService', 'Generating comprehensive order-based receipt PDF');
      Logger.debug('ReceiptPdfService', 'Order ID: ${orderData['unique_id']}, Payments count: ${payments.length}');
      Logger.debug('ReceiptPdfService', 'Full order data: ${orderData.toString()}');
      
      // Debug payment details with comprehensive logging
      if (payments.isNotEmpty) {
        Logger.info('ReceiptPdfService', 'FOUND PAYMENTS - Will show detailed payment table');
        Logger.debug('ReceiptPdfService', 'Payment details:');
        for (int i = 0; i < payments.length; i++) {
          final payment = payments[i];
          Logger.debug('ReceiptPdfService', 
            '  Payment ${i + 1}: ID=${payment.id}, Amount=₹${payment.amount}, Method=${payment.method.displayName}, Date=${payment.paidOn}, Order_ID=${payment.orderId}, Notes=${payment.notes}');
        }
      } else {
        Logger.error('ReceiptPdfService', 'NO PAYMENTS FOUND - Will show "NO PAYMENTS RECORDED" section');
        Logger.debug('ReceiptPdfService', 'This means the payment table query returned empty results');
      }
      
      final pdf = pw.Document();
      final order = orderData;
      final customer = customerData;
      final totalPaid = payments.fold<double>(0.0, (sum, payment) => sum + (payment?.amount ?? 0.0));
      final totalAmount = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
      final remainingBalance = totalAmount - totalPaid;
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with Business Information
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue200),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'TAILOR SHOP',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Professional Tailoring Services',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Order Receipt & Payment Summary',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Generated on: ${DateTime.now().toString().split(' ').first}',
                            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Customer Information - Enhanced
                if (customer != null)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Icon(
                              const pw.IconData(0xe7fd), // person icon
                              size: 18,
                              color: PdfColors.blue600,
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text(
                              'CUSTOMER DETAILS',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('Customer Name', customer['name'] ?? 'Unknown'),
                                  _buildDetailRow('Phone Number', customer['phone'] ?? 'N/A'),
                                  _buildDetailRow('Gender', customer['gender'] ?? 'N/A'),
                                ],
                              ),
                            ),
                            if (customer['email'] != null || customer['address'] != null)
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    if (customer['email'] != null)
                                      _buildDetailRow('Email', customer['email'] ?? 'N/A'),
                                    if (customer['address'] != null)
                                      _buildDetailRow('Address', customer['address'] ?? 'N/A'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                
                pw.SizedBox(height: 16),
                
                // Order Information - Enhanced
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Icon(
                            const pw.IconData(0xe8f4), // receipt icon
                            size: 18,
                            color: PdfColors.orange600,
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'ORDER DETAILS',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange800,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('Order ID', order['id']?.toString() ?? 'N/A'),
                                _buildDetailRow('Order Status', (order['status']?.toString() ?? 'UNKNOWN').toUpperCase()),
                                _buildDetailRow('Service Type', order['service_type']?.toString() ?? 'N/A'),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('Order Date', order['created_at']?.toString().split(' ').first ?? 'Unknown'),
                                if (order['due_date'] != null)
                                  _buildDetailRow('Due Date', order['due_date']?.toString().split(' ').first ?? 'Unknown'),
                                _buildDetailRow('Payment Status', (totalPaid >= totalAmount) ? 'FULLY PAID' : (totalPaid > 0) ? 'PARTIALLY PAID' : 'UNPAID'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (order['notes'] != null && order['notes'].toString().isNotEmpty)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 10),
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey50,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Order Notes:',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                order['notes'].toString(),
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 16),
                
                // Measurements Section (if available)
                if (order['measurements'] != null && order['measurements'].toString().isNotEmpty)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Icon(
                              const pw.IconData(0xe91b), // straighten icon
                              size: 18,
                              color: PdfColors.purple600,
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text(
                              'MEASUREMENTS',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.purple800,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey50,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            order['measurements'].toString(),
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                pw.SizedBox(height: 16),
                
                // Financial Summary - Enhanced
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    border: pw.Border.all(color: PdfColors.green300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Icon(
                            const pw.IconData(0xe227), // attach_money icon
                            size: 18,
                            color: PdfColors.green700,
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'FINANCIAL SUMMARY',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.green200),
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(color: PdfColors.green100),
                            children: [
                              _buildTableCell('Description', isHeader: true),
                              _buildTableCell('Amount', isHeader: true),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              _buildTableCell('Total Order Amount'),
                              _buildTableCell('₹${totalAmount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              _buildTableCell('Total Paid'),
                              _buildTableCell('₹${totalPaid.toStringAsFixed(2)}', textAlign: pw.TextAlign.right),
                            ],
                          ),
                          pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: remainingBalance > 0 ? PdfColors.orange50 : PdfColors.green100,
                            ),
                            children: [
                              _buildTableCell('Remaining Balance', isHeader: true),
                              _buildTableCell(
                                '₹${remainingBalance.toStringAsFixed(2)}', 
                                isHeader: true, 
                                textAlign: pw.TextAlign.right,
                                color: remainingBalance > 0 ? PdfColors.orange700 : PdfColors.green700,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 16),
                
                // Payment History - Always Show (Enhanced)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Icon(
                            const pw.IconData(0xe8e1), // payment icon
                            size: 18,
                            color: PdfColors.indigo600,
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'PAYMENT HISTORY (${payments.length} transaction${payments.length != 1 ? 's' : ''})',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.indigo800,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      payments.isNotEmpty 
                        ? pw.Table(
                            border: pw.TableBorder.all(color: PdfColors.grey300),
                            children: [
                              pw.TableRow(
                                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                                children: [
                                  _buildTableCell('#', isHeader: true),
                                  _buildTableCell('Date', isHeader: true),
                                  _buildTableCell('Amount', isHeader: true),
                                  _buildTableCell('Method', isHeader: true),
                                  _buildTableCell('Notes', isHeader: true),
                                ],
                              ),
                              ...payments.asMap().entries.map((entry) {
                                final index = entry.key + 1;
                                final payment = entry.value;
                                return pw.TableRow(
                                  children: [
                                    _buildTableCell(index.toString()),
                                    _buildTableCell(payment.paidOn.toString().split(' ').first),
                                    _buildTableCell('₹${payment.amount}', textAlign: pw.TextAlign.right),
                                    _buildTableCell(payment.method.displayName),
                                    _buildTableCell(payment.notes),
                                  ],
                                );
                              }),
                              // Total row
                              pw.TableRow(
                                decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                                children: [
                                  _buildTableCell('TOTAL', isHeader: true),
                                  _buildTableCell('', isHeader: true),
                                  _buildTableCell('₹${totalPaid.toStringAsFixed(2)}', isHeader: true, textAlign: pw.TextAlign.right),
                                  _buildTableCell('', isHeader: true),
                                  _buildTableCell('', isHeader: true),
                                ],
                              ),
                            ],
                          )
                        : pw.Container(
                            padding: const pw.EdgeInsets.all(16),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.orange50,
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Icon(
                                  const pw.IconData(0xe8e1), // payment icon
                                  size: 24,
                                  color: PdfColors.orange600,
                                ),
                                pw.SizedBox(height: 8),
                                pw.Text(
                                  'NO PAYMENTS RECORDED',
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.orange700,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Payment pending for this order',
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.orange600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),                pw.Spacer(),
                
                // Footer - Enhanced
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Thank you for your business!',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'For any queries, please contact us:',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Phone: +91 9876543210 | Email: info@tailorshop.com',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'This is a computer-generated receipt.',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      await _savePdf(pdf, 'order_receipt_${order['id']?.toString().substring(0, 8) ?? 'unknown'}');
      
    } catch (e) {
      Logger.error('ReceiptPdfService', 'Failed to generate order receipt', error: e);
      rethrow;
    }
  }
  
  /// Generate payment-based receipt PDF
  static Future<void> generatePaymentReceipt({
    required Map<String, dynamic> paymentData,
    required Map<String, dynamic>? orderData,
    required Map<String, dynamic>? customerData,
  }) async {
    try {
      Logger.info('ReceiptPdfService', 'Generating payment-based receipt PDF');
      
      final pdf = pw.Document();
      final payment = paymentData;
      final order = orderData;
      final customer = customerData;
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'TAILOR SHOP',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Payment Receipt',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                  ),
                ),
                
                // Payment Information
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PAYMENT DETAILS',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      _buildDetailRow('Payment ID', payment['id']?.toString() ?? 'N/A'),
                      _buildDetailRow('Amount', '₹${payment['amount']?.toString() ?? '0'}'),
                      _buildDetailRow('Payment Method', payment['method']?.toString() ?? 'Unknown'),
                      _buildDetailRow('Payment Date', payment['paid_on']?.toString().split(' ').first ?? 'Unknown'),
                      _buildDetailRow('Notes', payment['notes']?.toString() ?? 'No notes'),
                      if (payment['transaction_id'] != null)
                        _buildDetailRow('Transaction ID', payment['transaction_id']?.toString() ?? 'N/A'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Order Information (if available)
                if (order != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RELATED ORDER',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        _buildDetailRow('Order ID', order['id']?.toString() ?? 'N/A'),
                        _buildDetailRow('Service Type', order['service_type']?.toString() ?? 'N/A'),
                        _buildDetailRow('Order Status', order['status']?.toString().toUpperCase() ?? 'UNKNOWN'),
                        _buildDetailRow('Total Amount', '₹${order['total_amount']?.toString() ?? '0'}'),
                      ],
                    ),
                  ),
                
                pw.SizedBox(height: 20),
                
                // Customer Information (if available)
                if (customer != null)
                  pw.Container(
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
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        _buildDetailRow('Name', customer['name'] ?? 'Unknown'),
                        _buildDetailRow('Phone', customer['phone'] ?? 'N/A'),
                      ],
                    ),
                  ),
                
                pw.Spacer(),
                
                // Footer
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Payment received successfully!',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Thank you for your payment!',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Generated on: ${DateTime.now().toString().split(' ').first}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      await _savePdf(pdf, 'payment_receipt_${payment['id']?.toString().substring(0, 8) ?? 'unknown'}');
      
    } catch (e) {
      Logger.error('ReceiptPdfService', 'Failed to generate payment receipt', error: e);
      rethrow;
    }
  }
  
  /// Helper method to build detail rows
  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
  
  /// Helper method to build table cells
  static pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.TextAlign? textAlign, PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: textAlign,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
          color: color,
        ),
      ),
    );
  }
  
  /// Save PDF to device and open it
  static Future<void> _savePdf(pw.Document pdf, String fileName) async {
    try {
      final Uint8List pdfData = await pdf.save();
      
      // Save to device storage
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfData);
      
      Logger.info('ReceiptPdfService', 'PDF saved to: ${file.path}');
      
      // Open the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: fileName,
      );
      
    } catch (e) {
      Logger.error('ReceiptPdfService', 'Failed to save PDF', error: e);
      rethrow;
    }
  }
}