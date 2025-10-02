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

class CustomerDetailsScreen extends StatefulWidget {
  final String customerId;
  
  const CustomerDetailsScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> with NavigationMixin {
  Customer? customer;
  bool _isLoading = true;
  final LocalDatabaseService _dbService = LocalDatabaseService();

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  void _loadCustomerData() async {
    try {
      setState(() => _isLoading = true);
      
      final customerData = await _dbService.getCustomerByUniqueId(widget.customerId);
      
      if (customerData != null) {
        setState(() {
          customer = Customer.fromMap(customerData);
          _isLoading = false;
        });
        
        Logger.info('CustomerDetailsScreen', 'Loaded customer: ${customer!.name}');
      } else {
        Logger.error('CustomerDetailsScreen', 'Customer not found with ID: ${widget.customerId}');
        setState(() => _isLoading = false);
        
        if (mounted) {
          showNavigationMessage(
            context,
            'Customer Not Found',
            customMessage: 'Could not find customer data.',
            backgroundColor: Colors.red,
          );
          context.goNamed(RouteNames.viewCustomers);
        }
      }
    } catch (e, stackTrace) {
      Logger.error('CustomerDetailsScreen', 'Failed to load customer data', 
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: DashboardHeader(
        title: 'Customer Details',
        backgroundColor: const Color(AppConstants.primaryTeal),
        notificationCount: 3,
        onBackPressed: () {
          context.goNamed(RouteNames.viewCustomers);
        },
        onNotificationTap: () {
          showNavigationMessage(context, 'Notifications');
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(AppConstants.primaryTeal),
                ),
              )
            : customer == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Customer not found',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildPersonalInfoSection(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildOrderHistorySection(),
                        const SizedBox(height: AppConstants.spacingXL),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: customer!.isDeleted ? Colors.red : Colors.blue,
            child: Text(
              customer!.name.substring(0, 1).toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer!.name,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: customer!.isDeleted ? Colors.grey[500] : Colors.black87,
                          decoration: customer!.isDeleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (customer!.isDeleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'DELETED',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'ID: ${customer!.uniqueId}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer since ${_formatDate(customer!.createdAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (customer!.gender != null)
                  Text(
                    'Gender: ${customer!.gender}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_rounded,
      color: const Color(AppConstants.primaryTeal),
      children: [
        _buildInfoRow('Phone', customer!.phone, Icons.phone_rounded),
        if (customer!.email != null && customer!.email!.isNotEmpty)
          _buildInfoRow('Email', customer!.email!, Icons.email_rounded),
        _buildInfoRow('Address', customer!.address, Icons.location_on_rounded),
        if (customer!.gender != null)
          _buildInfoRow('Gender', customer!.gender!, Icons.wc_rounded),
        if (customer!.notes != null && customer!.notes!.isNotEmpty)
          _buildInfoRow('Notes', customer!.notes!, Icons.note_rounded),
      ],
    );
  }

  Widget _buildOrderHistorySection() {
    return _buildSection(
      title: 'Order History',
      icon: Icons.shopping_bag_rounded,
      color: const Color(AppConstants.primaryOrange),
      children: [
        _buildInfoRow('Customer Since', _formatDate(customer!.createdAt), Icons.calendar_today_rounded),
        _buildInfoRow('Last Updated', _formatDate(customer!.updatedAt), Icons.access_time_rounded),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No orders yet',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Orders will appear here once created',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            showNavigationMessage(context, 'Create Order', customMessage: 'Order creation feature coming soon!');
          },
          icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
          label: Text(
            'Create New Order',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(AppConstants.primaryOrange),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        // First row - Edit and Measurements
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.goNamed(RouteNames.editCustomer, pathParameters: {'customerId': widget.customerId}),
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: Text(
                  'Edit Customer',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryTeal),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.goNamed(RouteNames.measurementList, pathParameters: {'customerId': widget.customerId}),
                icon: const Icon(Icons.straighten_rounded, size: 20),
                label: Text(
                  'Measurements',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row - New Order (full width)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showNavigationMessage(context, 'New Order', customMessage: 'Create new order feature coming soon!');
            },
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
            label: Text(
              'Create New Order',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(AppConstants.primaryTeal),
              side: const BorderSide(color: Color(AppConstants.primaryTeal)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}