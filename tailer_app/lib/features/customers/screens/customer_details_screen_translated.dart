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
  
  const CustomerDetailsScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> with NavigationMixin {
  Customer? customer;
  bool _isLoading = true;
  final LocalDatabaseService _dbService = LocalDatabaseService();
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
        setState(() {
          customer = Customer.fromMap(customerData);
          _isLoading = false;
        });
        
        Logger.info('CustomerDetailsScreen', 'Loaded customer: ${customer!.name}');
      } else {
        Logger.error('CustomerDetailsScreen', 'Customer not found with ID: ${widget.customerId}');
        setState(() => _isLoading = false);
        
        if (mounted) {
          final locale = AppLocalizations.of(_localeProvider.languageCode);
          showNavigationMessage(
            context,
            locale.translate('error'),
            customMessage: locale.translate('noDataFound'),
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
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        showNavigationMessage(
          context,
          locale.translate('error'),
          customMessage: locale.translate('connectionError'),
          backgroundColor: Colors.red,
        );
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(AppConstants.primaryTeal),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          locale.translate('loading'),
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
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
                              locale.translate('noDataFound'),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              locale.translate('noCustomersFound'),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => context.goNamed(RouteNames.viewCustomers),
                              icon: const Icon(Icons.arrow_back),
                              label: Text(locale.translate('back')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(AppConstants.primaryTeal),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            _buildCustomerInfoCard(locale),
                            const SizedBox(height: AppConstants.spacingL),
                            _buildActionButtons(locale),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerInfoCard(AppLocalizations locale) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(AppConstants.primaryTeal),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      customer!.name.isNotEmpty ? customer!.name[0].toUpperCase() : 'C',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer!.name,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${customer!.id}',
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
            const SizedBox(height: 24),
            _buildInfoRow(Icons.phone, locale.translate('phoneNumber'), customer!.phone, locale),
            const SizedBox(height: 16),
            if (customer!.email != null && customer!.email!.isNotEmpty)
              _buildInfoRow(Icons.email, locale.translate('emailAddress'), customer!.email!, locale),
            if (customer!.email != null && customer!.email!.isNotEmpty)
              const SizedBox(height: 16),
            _buildInfoRow(Icons.location_on, locale.translate('address'), customer!.address, locale),
            if (customer!.notes != null && customer!.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(Icons.note, locale.translate('notes'), customer!.notes!, locale),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, AppLocalizations locale) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(AppConstants.primaryTeal)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations locale) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.goNamed(RouteNames.editCustomer, 
                pathParameters: {'customerId': widget.customerId});
            },
            icon: const Icon(Icons.edit),
            label: Text(locale.translate('editCustomer')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryTeal),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.goNamed(RouteNames.measurementList, 
                pathParameters: {'customerId': widget.customerId});
            },
            icon: const Icon(Icons.straighten),
            label: Text(locale.translate('measurements')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteDialog(locale),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: Text(
              locale.translate('deleteCustomer'),
              style: const TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(AppLocalizations locale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            locale.translate('deleteCustomer'),
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            locale.translate('areYouSureDeleteCustomer'),
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
                Navigator.of(context).pop();
                await _deleteCustomer(locale);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(locale.translate('delete')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCustomer(AppLocalizations locale) async {
    try {
      await _dbService.updateCustomer(customer!.uniqueId, {'is_deleted': 1});
      
      if (mounted) {
        showNavigationMessage(
          context,
          locale.translate('success'),
          customMessage: locale.translate('customerDeleted'),
          backgroundColor: Colors.green,
        );
        context.goNamed(RouteNames.viewCustomers);
      }
    } catch (e) {
      if (mounted) {
        showNavigationMessage(
          context,
          locale.translate('error'),
          customMessage: locale.translate('serverError'),
          backgroundColor: Colors.red,
        );
      }
    }
  }
}