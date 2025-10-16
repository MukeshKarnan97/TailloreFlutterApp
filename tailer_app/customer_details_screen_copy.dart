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

class CustomerDetailsScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> with NavigationMixin {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  Customer? customer;
  bool _isLoading = true;
  late SimpleLocaleProvider _localeProvider;
  late Map<String, dynamic> customerData;

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _loadCustomerData();
  }

  void _loadCustomerData() async {
    try {
      setState(() => _isLoading = true);
      
      final dbCustomerData = await _dbService.getCustomerByUniqueId(widget.customerId);
      
      if (dbCustomerData != null) {
        customer = Customer.fromMap(dbCustomerData);
        Logger.info('CustomerDetailsScreen', 'Loaded customer: ${customer!.name}');
        
        // Enhanced customer data with measurements and order history
        customerData = {
          'id': customer!.id,
          'name': customer!.name,
          'phone': customer!.phone,
          'email': customer!.email ?? 'N/A',
          'address': customer!.address,
          'gender': customer!.gender ?? 'Male',
          'notes': customer!.notes ?? 'No additional notes',
          'createdAt': customer!.createdAt,
          'totalOrders': 15, // Mock data - replace with actual from database
          'lastOrderDate': DateTime.now().subtract(const Duration(days: 3)),
          'preferredStyle': 'Business Casual', // Mock data
          'measurements': {
            'chest': '42"',
            'waist': '36"', 
            'hip': '40"',
            'shoulder': '18"',
            'armLength': '25"',
            'neckSize': '16"',
          },
        };
      } else {
        Logger.error('CustomerDetailsScreen', 'Customer not found with ID: ${widget.customerId}');
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
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, _) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: DashboardHeader(
            title: locale.translate('customerDetails'),
            backgroundColor: const Color(AppConstants.primaryTeal),
            notificationCount: 3,
            onBackPressed: () {
              context.goNamed(RouteNames.viewCustomers);
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
                : customer == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              locale.translate('customerNotFound'),
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
                            _buildProfileHeader(locale),
                            const SizedBox(height: AppConstants.spacingL),
                            _buildPersonalInfoSection(locale),
                            const SizedBox(height: AppConstants.spacingL),
                            _buildOrderHistorySection(locale),
                            const SizedBox(height: AppConstants.spacingL),
                            _buildMeasurementsSection(locale),
                            const SizedBox(height: AppConstants.spacingXL),
                            _buildActionButtons(locale),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(AppLocalizations locale) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(AppConstants.primaryTeal),
            child: Text(
              customerData['name'].substring(0, 1).toUpperCase(),
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
                  customerData['name'],
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
                    color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(AppConstants.primaryTeal).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${locale.translate('customerID')}: ${customerData['id']}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(AppConstants.primaryTeal),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${locale.translate('customerSince')} ${_formatDate(customerData['createdAt'])}',
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

  Widget _buildPersonalInfoSection(AppLocalizations locale) {
    return _buildSection(
      title: locale.translate('personalInformation'),
      icon: Icons.person_rounded,
      color: const Color(AppConstants.primaryTeal),
      children: [
        _buildInfoRow(locale.translate('phoneNumber'), customerData['phone'], Icons.phone_rounded),
        _buildInfoRow(locale.translate('emailAddress'), customerData['email'], Icons.email_rounded),
        _buildInfoRow(locale.translate('address'), customerData['address'], Icons.location_on_rounded),
        _buildInfoRow(locale.translate('gender'), _getGenderTranslation(customerData['gender'], locale), Icons.wc_rounded),
        _buildInfoRow('Preferred Style', customerData['preferredStyle'], Icons.style_rounded),
        if (customerData['notes'] != 'No additional notes')
          _buildInfoRow(locale.translate('notes'), customerData['notes'], Icons.note_rounded),
      ],
    );
  }

  Widget _buildOrderHistorySection(AppLocalizations locale) {
    return _buildSection(
      title: locale.translate('orderHistory'),
      icon: Icons.shopping_bag_rounded,
      color: const Color(AppConstants.primaryOrange),
      children: [
        _buildInfoRow('Total Orders', '${customerData['totalOrders']}', Icons.shopping_cart_rounded),
        _buildInfoRow('Last Order', _formatDate(customerData['lastOrderDate']), Icons.access_time_rounded),
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
                locale.translate('noOrdersYet'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                locale.translate('ordersWillAppearHere'),
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
            showNavigationMessage(context, locale.translate('createOrder'), customMessage: locale.translate('orderCreationFeatureComingSoon'));
          },
          icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
          label: Text(
            locale.translate('createNewOrder'),
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

  Widget _buildMeasurementsSection(AppLocalizations locale) {
    return _buildSection(
      title: locale.translate('measurements'),
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
          itemCount: customerData['measurements'].length,
          itemBuilder: (context, index) {
            final measurement = customerData['measurements'].entries.elementAt(index);
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
            context.goNamed(
              RouteNames.measurementList,
              pathParameters: {'customerId': widget.customerId},
            );
          },
          icon: const Icon(Icons.straighten_rounded, size: 20),
          label: Text(
            locale.translate('measurements'),
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

  Widget _buildActionButtons(AppLocalizations locale) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.goNamed(
              RouteNames.editCustomer,
              pathParameters: {'customerId': widget.customerId},
            ),
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: Text(
              locale.translate('editCustomer'),
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
              showNavigationMessage(context, locale.translate('createOrder'), customMessage: locale.translate('orderCreationFeatureComingSoon'));
            },
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
            label: Text(
              locale.translate('createOrder'),
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

  String _getGenderTranslation(String gender, AppLocalizations locale) {
    switch (gender.toLowerCase()) {
      case 'male':
        return locale.translate('male');
      case 'female':
        return locale.translate('female');
      case 'other':
        return locale.translate('other');
      case 'prefer not to say':
        return locale.translate('preferNotToSay');
      default:
        return gender;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}