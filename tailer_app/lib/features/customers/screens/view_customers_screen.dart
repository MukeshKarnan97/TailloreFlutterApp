import 'package:flutter/material.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/data/models/customer_model.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/core/utils/logger.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';

class ViewCustomersScreen extends StatefulWidget {
  const ViewCustomersScreen({Key? key}) : super(key: key);

  @override
  State<ViewCustomersScreen> createState() => _ViewCustomersScreenState();
}

class _ViewCustomersScreenState extends State<ViewCustomersScreen> with NavigationMixin {
  final _searchController = TextEditingController();
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  final LocalDatabaseService _dbService = LocalDatabaseService();
  late SimpleLocaleProvider _localeProvider;

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _loadCustomers();
  }

  /// Load customers from database
  Future<void> _loadCustomers() async {
    try {
      setState(() => _isLoading = true);
      
      // Get authenticated user's email as tailor ID (consistent with add customer)
      final authService = AuthService();
      await authService.initialize();
      
      String tailorId;
      if (authService.isAuthenticated && authService.currentUser != null) {
        tailorId = authService.currentUser!.email;
        Logger.info('ViewCustomersScreen', 'Loading customers for tailor: $tailorId');
      } else {
        tailorId = 'default_tailor';
        Logger.warning('ViewCustomersScreen', 'No authenticated user, using default tailor');
      }
      
      final customersData = await _dbService.getCustomersByTailorId(tailorId);
      final customers = customersData.map((data) => Customer.fromMap(data)).toList();
      
      setState(() {
        _allCustomers = customers;
        _filteredCustomers = customers;
        _isLoading = false;
      });
      
      Logger.info('ViewCustomersScreen', 'Loaded ${customers.length} customers');
    } catch (e, stackTrace) {
      Logger.error('ViewCustomersScreen', 'Failed to load customers', 
                  error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
      
      if (mounted) {
        showNavigationMessage(
          context,
          'Load Failed',
          customMessage: 'Failed to load customers. Please try again.',
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
        final locale = AppLocalizations(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: DashboardHeader(
            title: locale.translate('viewCustomers'),
            backgroundColor: AppColors.primary,
            notificationCount: 3,
            onBackPressed: () {
              context.goNamed(RouteNames.customerProfile);
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
                : Column(
                    children: [
                      _buildHeaderSection(locale),
                      _buildFilterSection(locale),
                      Expanded(child: _buildCustomerList(locale)),
                    ],
                  ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.goNamed(RouteNames.addCustomer),
            backgroundColor: const Color(AppConstants.primaryTeal),
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            label: Text(
              locale.translate('addCustomer'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(AppLocalizations locale) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppConstants.primaryOrange).withOpacity(0.1),
            const Color(AppConstants.primaryOrange).withOpacity(0.05),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(AppConstants.primaryOrange).withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(AppConstants.primaryOrange).withOpacity(0.1),
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
                  const Color(AppConstants.primaryOrange),
                  const Color(AppConstants.primaryOrange).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(AppConstants.primaryOrange).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.people_rounded,
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
                  locale.translate('customerManagement'),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locale.translate('manageAllYourCustomers'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryOrange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(AppConstants.primaryOrange).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_getVisibleCustomers().length} ${locale.translate('totalCustomersCount')}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(AppConstants.primaryOrange),
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

  Widget _buildFilterSection(AppLocalizations locale) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterCustomers,
        style: GoogleFonts.inter(fontSize: 16),
        decoration: InputDecoration(
          hintText: locale.translate('searchCustomersHint'),
          hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(AppConstants.primaryTeal)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(AppConstants.primaryTeal)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCustomerList(AppLocalizations locale) {
    final customers = _getVisibleCustomers();
    
    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty 
                  ? locale.translate('addFirstCustomer')
                  : locale.translate('noCustomersFoundMessage'),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                locale.translate('trySearchingDifferentTerm'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _buildCustomerCard(customer, locale);
      },
    );
  }

  Widget _buildCustomerCard(Customer customer, AppLocalizations locale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: customer.isDeleted 
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
            : Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: customer.isDeleted 
                  ? Colors.red.withOpacity(0.1)
                  : const Color(AppConstants.primaryTeal).withOpacity(0.1),
              child: Text(
                customer.name.substring(0, 1).toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: customer.isDeleted 
                      ? Colors.red
                      : const Color(AppConstants.primaryTeal),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    customer.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: customer.isDeleted ? Colors.grey[500] : Colors.black87,
                      decoration: customer.isDeleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (customer.isDeleted)
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'ID: ${customer.id}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(AppConstants.primaryTeal),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      customer.phone,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!customer.isDeleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.visibility_rounded,
                    label: 'View',
                    color: Colors.blue,
                    onPressed: () => _viewCustomer(customer),
                  ),
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    color: const Color(AppConstants.primaryTeal),
                    onPressed: () => _editCustomer(customer),
                  ),
                  _buildActionButton(
                    icon: Icons.delete_rounded,
                    label: 'Delete',
                    color: Colors.red,
                    onPressed: () => _deleteCustomer(customer),
                  ),
                ],
              ),
            ),
          if (customer.isDeleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.restore_rounded,
                    label: 'Restore',
                    color: Colors.green,
                    onPressed: () => _restoreCustomer(customer),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Customer> _getVisibleCustomers() {
    return _filteredCustomers.where((customer) => !customer.isDeleted).toList();
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _allCustomers;
      } else {
        _filteredCustomers = _allCustomers.where((customer) {
          return customer.name.toLowerCase().contains(query.toLowerCase()) ||
                 customer.id.toLowerCase().contains(query.toLowerCase()) ||
                 customer.phone.contains(query);
        }).toList();
      }
    });
  }

  void _viewCustomer(Customer customer) {
    context.goNamed(RouteNames.customerDetails, pathParameters: {'customerId': customer.uniqueId});
  }

  void _editCustomer(Customer customer) {
    context.goNamed(RouteNames.editCustomer, pathParameters: {'customerId': customer.uniqueId});
  }

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Customer', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          content: Text(
            'Are you sure you want to delete ${customer.name}? This action can be undone later.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Update database
                  await _dbService.updateCustomer(customer.uniqueId, {
                    'is_deleted': 1,
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                  
                  // Update local state
                  setState(() {
                    final index = _allCustomers.indexWhere((c) => c.id == customer.id);
                    if (index != -1) {
                      _allCustomers[index] = customer.copyWith(
                        isDeleted: true,
                        updatedAt: DateTime.now(),
                      );
                    }
                    _filterCustomers(_searchController.text);
                  });
                  
                  Navigator.of(context).pop();
                  showNavigationMessage(
                    context,
                    'Customer Deleted',
                    customMessage: '${customer.name} has been moved to deleted customers.',
                    backgroundColor: Colors.orange,
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  showNavigationMessage(
                    context,
                    'Delete Failed',
                    customMessage: 'Failed to delete customer. Please try again.',
                    backgroundColor: Colors.red,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _restoreCustomer(Customer customer) async {
    try {
      // Update database
      await _dbService.updateCustomer(customer.uniqueId, {
        'is_deleted': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Update local state
      setState(() {
        final index = _allCustomers.indexWhere((c) => c.id == customer.id);
        if (index != -1) {
          _allCustomers[index] = customer.copyWith(
            isDeleted: false,
            updatedAt: DateTime.now(),
          );
        }
        _filterCustomers(_searchController.text);
      });
      
      showNavigationMessage(
        context,
        'Customer Restored',
        customMessage: '${customer.name} has been restored successfully.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      showNavigationMessage(
        context,
        'Restore Failed',
        customMessage: 'Failed to restore customer. Please try again.',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}