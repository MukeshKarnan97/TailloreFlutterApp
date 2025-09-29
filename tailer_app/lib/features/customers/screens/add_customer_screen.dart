import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/data/models/customer_model.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/core/utils/logger.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({Key? key}) : super(key: key);

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> with NavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedGender = 'Male';
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: DashboardHeader(
        title: 'Add Customer',
        backgroundColor: const Color(AppConstants.primaryTeal),
        notificationCount: 3,
        onBackPressed: () {
          context.go('/customers/profile');
        },
        onNotificationTap: () {
          showNavigationMessage(context, 'Notifications');
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: AppConstants.spacingL),
                _buildFormFields(),
                const SizedBox(height: AppConstants.spacingL),
                _buildActionButtons(),
                const SizedBox(height: AppConstants.spacingL), // Extra bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppConstants.primaryTeal).withOpacity(0.1),
            const Color(AppConstants.primaryTeal).withOpacity(0.05),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(AppConstants.primaryTeal).withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
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
                  const Color(AppConstants.primaryTeal),
                  const Color(AppConstants.primaryTeal).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(AppConstants.primaryTeal).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_add_rounded,
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
                  'Add New Customer',
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
                    color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(AppConstants.primaryTeal).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Customer Registration',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(AppConstants.primaryTeal),
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

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person_rounded,
          isRequired: true,
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildGenderDropdown(),
        const SizedBox(height: AppConstants.spacingM),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          isRequired: true,
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildTextField(
          controller: _addressController,
          label: 'Address',
          icon: Icons.location_on_rounded,
          maxLines: 3,
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildTextField(
          controller: _notesController,
          label: 'Notes (Optional)',
          icon: Icons.note_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
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
        onChanged: (String? newValue) {
          setState(() {
            _selectedGender = newValue!;
          });
        },
        dropdownColor: Colors.white,
        iconEnabledColor: const Color(AppConstants.primaryTeal),
        iconDisabledColor: Colors.grey,
        iconSize: 20,
        isExpanded: true,
        menuMaxHeight: 250,
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        alignment: Alignment.centerLeft,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: 'Gender *',
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: Color(AppConstants.primaryTeal),
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
              color: Color(AppConstants.primaryTeal),
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
            horizontal: 16,
            vertical: 18,
          ),
        ),
        items: _genderOptions.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
          );
        }).toList(),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Gender is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
              color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(AppConstants.primaryTeal),
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
              color: Color(AppConstants.primaryTeal),
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
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Cancel',
            icon: Icons.cancel_outlined,
            backgroundColor: Colors.grey[100]!,
            textColor: Colors.grey[700]!,
            onPressed: () => context.go('/customers/profile'),
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: _buildActionButton(
            label: 'Save Customer',
            icon: Icons.save_rounded,
            backgroundColor: const Color(AppConstants.primaryTeal),
            textColor: Colors.white,
            onPressed: _saveCustomer,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      try {
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

        // Get current authenticated user
        final authService = AuthService();
        await authService.initialize();
        
        String tailorId;
        if (authService.isAuthenticated && authService.currentUser != null) {
          // Use the current user's ID as tailor ID
          tailorId = authService.currentUser!.email;
          Logger.info('AddCustomerScreen', 'Using authenticated user ID as tailor ID: $tailorId');
        } else {
          // Fallback to temporary ID if no user is authenticated
          tailorId = 'default_tailor';
          Logger.warning('AddCustomerScreen', 'No authenticated user found, using temporary tailor ID');
        }

        // Create customer object
        final customer = Customer.create(
          tailorId: tailorId,
          name: _nameController.text.trim(),
          gender: _selectedGender,
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          address: _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        // Save to database (tailor app - simplified)
        final dbService = LocalDatabaseService();
        await dbService.insertCustomerWithoutForeignKeyCheck(customer);
        Logger.info('AddCustomerScreen', 'Customer ${customer.name} saved successfully with tailor ID: $tailorId');

        // Hide loading indicator
        if (mounted) Navigator.of(context).pop();

        // Show success message
        if (mounted) {
          showNavigationMessage(
            context,
            'Customer Saved',
            customMessage: 'Customer ${_nameController.text} has been saved successfully!',
            backgroundColor: Colors.green,
          );
        }

        // Navigate back to customer view
        if (mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.go('/customers/view');
          });
        }

      } catch (e, stackTrace) {
        Logger.error('AddCustomerScreen', 'Failed to save customer', 
                    error: e, stackTrace: stackTrace);

        // Hide loading indicator
        if (mounted) Navigator.of(context).pop();

        // Show error message
        if (mounted) {
          showNavigationMessage(
            context,
            'Save Failed',
            customMessage: 'Failed to save customer. Please try again.',
            backgroundColor: Colors.red,
          );
        }
      }
    }
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