import 'package:flutter/material.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/simple_locale_provider.dart';
import '../../../core/translations/app_localizations.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/enums/payment_method.dart';
import '../../../data/services/local_db_service.dart';
import '../../../core/utils/logger.dart';
import '../widgets/customer_selector.dart';
import '../widgets/dress_type_selector.dart';
import '../widgets/order_measurement_form.dart';
import '../../../widgets/custom_header.dart';


class AddOrderScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;

  const AddOrderScreen({super.key, this.extra});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _advanceController = TextEditingController();
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  
  Customer? _selectedCustomer;
  String? _selectedDressType;
  Map<String, double> _measurements = {};
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));
  PaymentMethod _advancePaymentMethod = PaymentMethod.cash; // Default to cash
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeWithPreSelection();
  }

  void _initializeWithPreSelection() {
    if (widget.extra != null) {
      final customerData = widget.extra!['customer'] as Map<String, dynamic>?;
      if (customerData != null) {
        _selectedCustomer = Customer.fromMap(customerData);
        Logger.info('AddOrderScreen', 'Pre-selected customer: ${_selectedCustomer!.name}');
        Logger.debug('AddOrderScreen', 'Customer ID: ${_selectedCustomer!.id}');
        Logger.debug('AddOrderScreen', 'Customer UniqueID: ${_selectedCustomer!.uniqueId}');
        Logger.debug('AddOrderScreen', 'Customer data: $customerData');
      } else {
        Logger.warning('AddOrderScreen', 'No customer data found in extra');
      }
    } else {
      Logger.warning('AddOrderScreen', 'No extra data provided');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _totalAmountController.dispose();
    _advanceController.dispose();
    // Don't dispose singleton _localeProvider
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(AppConstants.primaryTeal),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _deliveryDate) {
      setState(() {
        _deliveryDate = picked;
      });
    }
  }

  void _onMeasurementsChanged(Map<String, double> measurements) {
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _measurements = measurements;
      });
    });
  }

  void _onCustomerSelected(Customer? customer) {
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedCustomer = customer;
        // Reset measurements when customer changes
        _measurements = {};
      });
    });
  }

  void _onDressTypeSelected(String? dressType) {
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedDressType = dressType;
        // Reset measurements when dress type changes
        _measurements = {};
      });
    });
  }

  double get _balanceAmount {
    final total = double.tryParse(_totalAmountController.text) ?? 0.0;
    final advance = double.tryParse(_advanceController.text) ?? 0.0;
    return total - advance;
  }

  bool get _isFormValid {
    return _selectedCustomer != null &&
           _selectedDressType != null &&
           _measurements.isNotEmpty &&
           _totalAmountController.text.isNotEmpty &&
           double.tryParse(_totalAmountController.text) != null &&
           double.tryParse(_totalAmountController.text)! > 0;
  }

  Future<void> _createOrder() async {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locale.t('pleaseFillAllRequiredFields')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('AddOrderScreen', 'Creating new order');
      
      // Validate customer exists in database
      Logger.debug('AddOrderScreen', 'Validating customer: ${_selectedCustomer!.uniqueId}');
      final customerExists = await _dbService.getCustomerByUniqueId(_selectedCustomer!.uniqueId);
      if (customerExists == null) {
        throw Exception('Customer not found in database: ${_selectedCustomer!.uniqueId}');
      }
      Logger.info('AddOrderScreen', 'Customer validation successful: ${customerExists['name']}');
      
      final totalAmount = double.parse(_totalAmountController.text);
      final advancePaid = double.tryParse(_advanceController.text) ?? 0.0;
      
      Logger.debug('AddOrderScreen', 'Order details - Customer: ${_selectedCustomer!.uniqueId}, DressType: $_selectedDressType, Amount: $totalAmount');
      
      final order = Order.create(
        customerId: _selectedCustomer!.uniqueId,
        tailorId: 'tailor_001', // Default tailor ID for now
        serviceType: _selectedDressType!,
        status: 'pending', // Default status
        deliveryDate: _deliveryDate,
        notes: _notesController.text.trim(),
        totalAmount: totalAmount,
        advancePaid: advancePaid,
        balanceAmount: totalAmount - advancePaid,
        measurements: _measurements,
      );

      final result = await _dbService.insertOrderWithoutTailorForeignKeyCheck(order);
      
      if (result > 0) {
        // If advance payment is made, create a payment record
        if (advancePaid > 0) {
          final payment = Payment.create(
            orderId: order.uniqueId,
            amount: advancePaid,
            method: _advancePaymentMethod,
            notes: 'Advance payment during order creation',
          );
          
          await _dbService.addPayment(payment);
          Logger.info('AddOrderScreen', 'Advance payment record created: ${payment.uniqueId}');
        }
        
        Logger.info('AddOrderScreen', 'Order created successfully: ${order.uniqueId}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${locale.t('orderCreatedSuccessfully')} ${order.uniqueId}'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to customer details or dashboard
          context.pop();
        }
      } else {
        throw Exception('Failed to save order to database');
      }
    } catch (e, stackTrace) {
      Logger.error('AddOrderScreen', 'Failed to create order', error: e, stackTrace: stackTrace);
      
      String errorMessage = locale.t('failedToCreateOrder');
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        errorMessage = '${locale.t('failedToCreateOrder')}: Customer not found in database';
      } else if (e.toString().contains('NOT NULL constraint failed')) {
        errorMessage = '${locale.t('failedToCreateOrder')}: Missing required information';
      } else {
        errorMessage = '${locale.t('failedToCreateOrder')}: ${e.toString()}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          backgroundColor: AppColors.background,
          appBar: DashboardHeader(
            title: locale.t('createNewOrder'),
            backgroundColor: AppColors.primary,
            notificationCount: 3,
            onBackPressed: () {
              context.pop();
            },
            onNotificationTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(locale.t('notifications'))),
              );
            },
          ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.background,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      // _buildSectionHeader(
                      //   icon: Icons.person_outline,
                      //   title: AppLocalizations.of(_localeProvider.languageCode).t('customerInformation'),
                      //   color: AppColors.primary,
                      // ),
                      const SizedBox(height: 12),
                      
                      // Customer Selection
                      CustomerSelector(
                        selectedCustomer: _selectedCustomer,
                        onCustomerSelected: _onCustomerSelected,
                        enabled: !_isLoading,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Service Section
                      _buildSectionHeader(
                        icon: Icons.checkroom,
                        title: AppLocalizations.of(_localeProvider.languageCode).t('serviceDetails'),
                        color: AppColors.secondary,
                      ),
                      const SizedBox(height: 12),
                      
                      // Dress Type Selection
                      DressTypeSelector(
                        selectedDressType: _selectedDressType,
                        onDressTypeSelected: _onDressTypeSelected,
                        enabled: !_isLoading,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Measurements Section
                      if (_selectedCustomer != null && _selectedDressType != null) ...[
                        _buildSectionHeader(
                          icon: Icons.straighten,
                          title: AppLocalizations.of(_localeProvider.languageCode).t('measurements'),
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 12),
                        OrderMeasurementForm(
                          customerId: _selectedCustomer!.uniqueId,
                          dressType: _selectedDressType,
                          initialMeasurements: _measurements,
                          onMeasurementsChanged: _onMeasurementsChanged,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Order Details Section
                      if (_selectedCustomer != null && _selectedDressType != null)
                        _buildOrderDetailsSection(),
                      
                      const SizedBox(height: 100), // Space for button
                    ],
                  ),
                ),
              ),
              
              // Create Order Button
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading || !_isFormValid ? null : _createOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.textHint,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _isFormValid ? 4 : 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_shopping_cart, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  locale.t('createOrder'),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.receipt_long,
          title: locale.t('orderDetails'),
          color: AppColors.success,
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          elevation: 2,
          shadowColor: AppColors.shadow.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Date
                InkWell(
                  onTap: _isLoading ? null : _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale.t('deliveryDate'),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Total Amount
                TextFormField(
                  controller: _totalAmountController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: locale.t('totalAmount'),
                    floatingLabelStyle: const TextStyle(color: Colors.black),
                    labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.currency_rupee, color: AppColors.secondary),
                    suffixStyle: const TextStyle(color: Colors.black87),
                    filled: true,
                    fillColor: AppColors.secondary.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.secondary.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.secondary, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return locale.t('pleaseEnterTotalAmount');
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return locale.t('pleaseEnterValidAmount');
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Defer setState to avoid calling during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {}); // Refresh balance calculation
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Advance Amount
                TextFormField(
                  controller: _advanceController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black
                  ),
                  decoration: InputDecoration(
                    labelText: locale.t('advanceAmount'),
                    labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                    floatingLabelStyle: const TextStyle(color: Colors.black),
                    prefixIcon: Icon(Icons.payment, color: AppColors.accent),
                    suffixStyle: const TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: AppColors.accent.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return locale.t('pleaseEnterValidAdvanceAmount');
                      }
                      final total = double.tryParse(_totalAmountController.text) ?? 0.0;
                      if (amount > total) {
                        return locale.t('advanceCannotBeMoreThanTotal');
                      }
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Defer setState to avoid calling during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {}); // Refresh balance calculation
                    });
                  },
                ),
                
                // Payment Method Selection (only show if advance amount is entered)
                if (_advanceController.text.isNotEmpty && 
                    double.tryParse(_advanceController.text) != null && 
                    double.parse(_advanceController.text) > 0) ...[
                  const SizedBox(height: 20),
                  
                  Text(
                    'Advance Payment Method',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PaymentMethod>(
                        value: _advancePaymentMethod,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        dropdownColor: Colors.white,
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
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _isLoading ? null : (PaymentMethod? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _advancePaymentMethod = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
                
                // Balance Amount Display
               if (_totalAmountController.text.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 20),
    child: SizedBox(
      width: double.infinity, // 👈 makes it full width
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.success.withOpacity(0.1),
              AppColors.success.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.success.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${locale.t('balanceAmount')}:',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '₹${_balanceAmount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    ),
  ),

                const SizedBox(height: 20),
                
                // Notes
                TextFormField(
                  controller: _notesController,
                  enabled: !_isLoading,
                  maxLines: 4,
                  
                  style: GoogleFonts.inter(
    fontSize: 15,
    color: Colors.black, // 👈 text color while typing
  ),
  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    labelText: locale.t('notesOptional'),
                    labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                    hintText: locale.t('specialInstructions'),
                    hintStyle: GoogleFonts.inter(color: AppColors.textHint),
                    prefixIcon: Icon(Icons.note_alt, color: AppColors.textSecondary),
                    floatingLabelStyle: const TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.textHint.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.textHint.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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