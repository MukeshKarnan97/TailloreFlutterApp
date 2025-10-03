import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/simple_locale_provider.dart';
import '../../../core/translations/app_localizations.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/local_db_service.dart';
import '../../../core/utils/logger.dart';
import '../widgets/customer_selector.dart';
import '../widgets/dress_type_selector.dart';
import '../widgets/order_measurement_form.dart';

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
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: const Color(AppConstants.primaryTeal),
            foregroundColor: Colors.white,
            title: Text(
              locale.t('createNewOrder'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            elevation: 0,
            actions: [
              if (_isFormValid)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Selection
                    CustomerSelector(
                      selectedCustomer: _selectedCustomer,
                      onCustomerSelected: _onCustomerSelected,
                      enabled: !_isLoading,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dress Type Selection
                    DressTypeSelector(
                      selectedDressType: _selectedDressType,
                      onDressTypeSelected: _onDressTypeSelected,
                      enabled: !_isLoading,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Measurements Form
                    if (_selectedCustomer != null && _selectedDressType != null)
                      OrderMeasurementForm(
                        customerId: _selectedCustomer!.uniqueId,
                        dressType: _selectedDressType,
                        initialMeasurements: _measurements,
                        onMeasurementsChanged: _onMeasurementsChanged,
                        enabled: !_isLoading,
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Order Details Section
                    if (_selectedCustomer != null && _selectedDressType != null)
                      _buildOrderDetailsSection(),
                  ],
                ),
              ),
            ),
            
            // Create Order Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || !_isFormValid ? null : _createOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppConstants.primaryTeal),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_shopping_cart, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                locale.t('createOrder'),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
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
        );
      },
    );
  }

  Widget _buildOrderDetailsSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.t('orderDetails'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Delivery Date
            InkWell(
              onTap: _isLoading ? null : _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(AppConstants.primaryTeal)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.t('deliveryDate'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Total Amount
            TextFormField(
              controller: _totalAmountController,
              enabled: !_isLoading,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: locale.t('totalAmount'),
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
              decoration: InputDecoration(
                labelText: locale.t('advanceAmount'),
                prefixIcon: const Icon(Icons.payment),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
            
            // Balance Amount Display
            if (_totalAmountController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${locale.t('balanceAmount')}:',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '₹${_balanceAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(AppConstants.primaryTeal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Notes
            TextFormField(
              controller: _notesController,
              enabled: !_isLoading,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: locale.t('notesOptional'),
                hintText: locale.t('specialInstructions'),
                prefixIcon: const Icon(Icons.note_alt),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}