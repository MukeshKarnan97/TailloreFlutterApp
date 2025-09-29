import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final String customerId;
  
  const CustomerDetailsScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> with NavigationMixin {
  late Map<String, dynamic> customer;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  void _loadCustomerData() {
    // Mock data - replace with actual data loading
    customer = {
      'id': widget.customerId,
      'name': 'John Doe',
      'phone': '+1 234 567 8900',
      'email': 'john.doe@email.com',
      'address': '123 Main St, City, State 12345',
      'notes': 'Preferred fabric: Cotton. Regular customer since 2020.',
      'createdAt': DateTime.now().subtract(const Duration(days: 10)),
      'totalOrders': 15,
      'lastOrderDate': DateTime.now().subtract(const Duration(days: 3)),
      'preferredStyle': 'Business Casual',
      'measurements': {
        'chest': '42\"',
        'waist': '36\"',
        'hip': '40\"',
        'shoulder': '18\"',
        'armLength': '25\"',
        'neckSize': '16\"',
      },
    };
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
          context.go('/customers/view');
        },
        onNotificationTap: () {
          showNavigationMessage(context, 'Notifications');
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: AppConstants.spacingL),
              _buildPersonalInfoSection(),
              const SizedBox(height: AppConstants.spacingL),
              _buildOrderHistorySection(),
              const SizedBox(height: AppConstants.spacingL),
              _buildMeasurementsSection(),
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
            backgroundColor: Colors.blue,
            child: Text(
              customer['name'].substring(0, 1).toUpperCase(),
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
                Text(
                  customer['name'],
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
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
                    'ID: ${customer['id']}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer since ${_formatDate(customer['createdAt'])}',
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
        _buildInfoRow('Phone', customer['phone'], Icons.phone_rounded),
        _buildInfoRow('Email', customer['email'], Icons.email_rounded),
        _buildInfoRow('Address', customer['address'], Icons.location_on_rounded),
        _buildInfoRow('Preferred Style', customer['preferredStyle'], Icons.style_rounded),
        if (customer['notes'].isNotEmpty)
          _buildInfoRow('Notes', customer['notes'], Icons.note_rounded),
      ],
    );
  }

  Widget _buildOrderHistorySection() {
    return _buildSection(
      title: 'Order History',
      icon: Icons.shopping_bag_rounded,
      color: const Color(AppConstants.primaryOrange),
      children: [
        _buildInfoRow('Total Orders', '${customer['totalOrders']}', Icons.shopping_cart_rounded),
        _buildInfoRow('Last Order', _formatDate(customer['lastOrderDate']), Icons.access_time_rounded),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            showNavigationMessage(context, 'Order History', customMessage: 'Order history feature coming soon!');
          },
          icon: const Icon(Icons.history_rounded, size: 20),
          label: Text(
            'View Order History',
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

  Widget _buildMeasurementsSection() {
    return _buildSection(
      title: 'Measurements',
      icon: Icons.straighten_rounded,
      color: Colors.purple,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: customer['measurements'].length,
          itemBuilder: (context, index) {
            final measurement = customer['measurements'].entries.elementAt(index);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _capitalize(measurement.key),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    measurement.value,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            showNavigationMessage(context, 'Measurements', customMessage: 'Measurement editing feature coming soon!');
          },
          icon: const Icon(Icons.edit_rounded, size: 20),
          label: Text(
            'Update Measurements',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
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
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/customers/edit/${widget.customerId}'),
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
          child: OutlinedButton.icon(
            onPressed: () {
              showNavigationMessage(context, 'New Order', customMessage: 'Create new order feature coming soon!');
            },
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
            label: Text(
              'New Order',
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

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}