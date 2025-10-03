import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/data/models/customer_model.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/core/utils/logger.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';

class EditCustomerScreen extends StatefulWidget {
  final String customerId;
  
  const EditCustomerScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> with NavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedGender = 'Male';
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final LocalDatabaseService _dbService = LocalDatabaseService();
  Customer? _customer;
  bool _isLoading = true;
  bool _isSaving = false;
  late SimpleLocaleProvider _localeProvider;

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _loadCustomerData();
  }

  void _loadCustomerData() async {
    try {
      setState(() => _isLoading = true);
      
      final customerData = await _dbService.getCustomerByUniqueId(widget.customerId);
      
      if (customerData != null) {
        _customer = Customer.fromMap(customerData);
        
        // Populate form fields
        _nameController.text = _customer!.name;
        _phoneController.text = _customer!.phone;
        _emailController.text = _customer!.email ?? '';
        _addressController.text = _customer!.address;
        _notesController.text = _customer!.notes ?? '';
        _selectedGender = _customer!.gender ?? 'Male';
        
        Logger.info('EditCustomerScreen', 'Loaded customer: ${_customer!.name}');
      } else {
        Logger.error('EditCustomerScreen', 'Customer not found with ID: ${widget.customerId}');
        if (mounted) {
          final locale = AppLocalizations.of(_localeProvider.languageCode);
          showNavigationMessage(
            context,
            locale.translate('customerNotFound'),
            customMessage: locale.translate('couldNotFindCustomerData'),
            backgroundColor: Colors.red,
          );
          context.goNamed(RouteNames.viewCustomers);
          return;
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      Logger.error('EditCustomerScreen', 'Failed to load customer data', 
                  error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
      
      if (mounted) {
        showNavigationMessage(
          context,
          'Load Failed',
          customMessage: 'Failed to load customer data. Please try again.',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, _) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: DashboardHeader(
            title: locale.translate('editCustomer'),
            backgroundColor: const Color(AppConstants.primaryTeal),
            notificationCount: 3,
            onBackPressed: () {
              context.goNamed(RouteNames.customerDetails, pathParameters: {'customerId': widget.customerId});
            },
            onNotificationTap: () {
              showNavigationMessage(context, locale.translate('notifications'));
            },
          ),
          body: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(AppConstants.primaryTeal),
                    ),
                  )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(locale),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildFormFields(locale),
                    const SizedBox(height: AppConstants.spacingXL),
                    _buildActionButtons(locale),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(AppLocalizations locale) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange,
                  Colors.orange.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.translate('editCustomer'),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${locale.translate('customerID')}: ${widget.customerId}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(AppLocalizations locale) {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: locale.translate('fullName'),
          icon: Icons.person_rounded,
          isRequired: true,
          locale: locale,
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildGenderDropdown(locale),
        const SizedBox(height: AppConstants.spacingM),
        _buildTextField(
          controller: _phoneController,
          label: locale.translate('phoneNumber'),
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          isRequired: true,
          locale: locale,
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildTextField(
          controller: _emailController,
          label: locale.translate('emailAddress'),
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          locale: locale,
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildTextField(
          controller: _addressController,
          label: locale.translate('address'),
          icon: Icons.location_on_rounded,
          maxLines: 3,
          locale: locale,
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildTextField(
          controller: _notesController,
          label: locale.translate('notes'),
          icon: Icons.note_rounded,
          maxLines: 3,
          locale: locale,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppLocalizations locale,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.orange,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '${label} ${locale.translate('isRequired')}';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildGenderDropdown(AppLocalizations locale) {
    final genderTranslations = {
      'Male': locale.translate('male'),
      'Female': locale.translate('female'),
      'Other': locale.translate('other'),
      'Prefer not to say': locale.translate('preferNotToSay'),
    };
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: '${locale.translate('gender')} *',
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 20,
              color: Colors.orange,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.orange,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        items: _genderOptions.map((String gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Text(
              genderTranslations[gender] ?? gender,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedGender = newValue;
            });
          }
        },
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.orange,
        ),
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '${locale.translate('gender')} ${locale.translate('isRequired')}';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations locale) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: locale.translate('cancel'),
                icon: Icons.cancel_outlined,
                backgroundColor: Colors.grey[100]!,
                textColor: Colors.grey[700]!,
                onPressed: () => context.goNamed(RouteNames.customerDetails, pathParameters: {'customerId': widget.customerId}),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildActionButton(
                label: locale.translate('save'),
                icon: Icons.save_rounded,
                backgroundColor: Colors.orange,
                textColor: Colors.white,
                onPressed: () => _saveChanges(locale),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            label: locale.translate('deleteCustomer'),
            icon: Icons.delete_rounded,
            backgroundColor: Colors.red.withOpacity(0.1),
            textColor: Colors.red,
            onPressed: () => _deleteCustomer(locale),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges(AppLocalizations locale) async {
    if (_formKey.currentState!.validate() && _customer != null) {
      try {
        setState(() => _isSaving = true);
        
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
        
        // Update customer data in database
        await _dbService.updateCustomer(_customer!.uniqueId, {
          'name': _nameController.text.trim(),
          'gender': _selectedGender,
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        });
        
        Logger.info('EditCustomerScreen', 'Customer ${_nameController.text} updated successfully');
        
        // Hide loading indicator
        if (mounted) Navigator.of(context).pop();
        
        setState(() => _isSaving = false);
        
        // Show success message
        if (mounted) {
          showNavigationMessage(
            context,
            'Customer Updated',
            customMessage: 'Customer ${_nameController.text} has been updated successfully!',
            backgroundColor: Colors.green,
          );
        }
        
        // Navigate back to customer details
        if (mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.goNamed(RouteNames.customerDetails, pathParameters: {'customerId': widget.customerId});
          });
        }
        
      } catch (e, stackTrace) {
        Logger.error('EditCustomerScreen', 'Failed to update customer', 
                    error: e, stackTrace: stackTrace);
        
        setState(() => _isSaving = false);
        
        // Hide loading indicator
        if (mounted) Navigator.of(context).pop();
        
        // Show error message
        if (mounted) {
          showNavigationMessage(
            context,
            'Update Failed',
            customMessage: 'Failed to update customer. Please try again.',
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  void _deleteCustomer(AppLocalizations locale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            locale.translate('deleteCustomer'),
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            '${locale.translate('areYouSureDeleteCustomer')} ${_nameController.text}? ${locale.translate('thisActionCanBeUndone')}',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                locale.translate('cancel'),
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.of(context).pop();
                  
                  // Update database to mark as deleted
                  await _dbService.updateCustomer(_customer!.uniqueId, {
                    'is_deleted': 1,
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                  
                  Logger.info('EditCustomerScreen', 'Customer ${_nameController.text} deleted successfully');
                  
                  if (mounted) {
                    showNavigationMessage(
                      context,
                      locale.translate('customerDeleted'),
                      customMessage: '${_nameController.text} ${locale.translate('hasBeenMovedToDeletedCustomers')}',
                      backgroundColor: Colors.orange,
                    );
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) context.goNamed(RouteNames.viewCustomers);
                    });
                  }
                } catch (e, stackTrace) {
                  Logger.error('EditCustomerScreen', 'Failed to delete customer', 
                              error: e, stackTrace: stackTrace);
                  
                  if (mounted) {
                    showNavigationMessage(
                      context,
                      locale.translate('deleteFailed'),
                      customMessage: locale.translate('failedToDeleteCustomer'),
                      backgroundColor: Colors.red,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                locale.translate('delete'),
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}