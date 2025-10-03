import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/measurement_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/data/models/measurement_model.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/core/utils/logger.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';

class MeasurementListScreen extends StatefulWidget {
  final String customerId;
  
  const MeasurementListScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<MeasurementListScreen> createState() => _MeasurementListScreenState();
}

class _MeasurementListScreenState extends State<MeasurementListScreen> with NavigationMixin {
  final _searchController = TextEditingController();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  late SimpleLocaleProvider _localeProvider;
  
  List<Measurement> _allMeasurements = [];
  List<Measurement> _filteredMeasurements = [];
  bool _isLoading = true;
  String? _customerName;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _loadMeasurements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load measurements for the customer
  Future<void> _loadMeasurements() async {
    try {
      setState(() => _isLoading = true);
      
      // Load customer name first
      final customerData = await _dbService.getCustomerByUniqueId(widget.customerId);
      if (customerData != null) {
        _customerName = customerData['name'];
      }
      
      // Load measurements for this customer
      final measurementsData = await _dbService.getMeasurementsByCustomerId(widget.customerId);
      final measurements = measurementsData.map((data) => Measurement.fromMap(data)).toList();
      
      // Sort by created date (newest first)
      measurements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() {
        _allMeasurements = measurements;
        _filteredMeasurements = measurements;
        _isLoading = false;
      });
      
    } catch (e, stackTrace) {
      Logger.error('MeasurementListScreen', 'Failed to load measurements', error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
    }
  }

  /// Filter measurements based on search query and filter type
  void _filterMeasurements(String query) {
    setState(() {
      List<Measurement> filtered = _allMeasurements;
      
      // Apply dress type filter
      if (_selectedFilter != 'all') {
        filtered = filtered.where((measurement) => measurement.dressType == _selectedFilter).toList();
      }
      
      // Apply search query
      if (query.isNotEmpty) {
        filtered = filtered.where((measurement) {
          final dressTypeDetails = MeasurementConstants.getDressTypeDetails(measurement.dressType);
          final dressTypeName = dressTypeDetails?['name']?.toLowerCase() ?? measurement.dressType.toLowerCase();
          return dressTypeName.contains(query.toLowerCase()) ||
                 measurement.dressType.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
      
      _filteredMeasurements = filtered;
    });
  }

  /// Delete measurement with confirmation
  Future<void> _deleteMeasurement(Measurement measurement, AppLocalizations locale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          locale.translate('deleteMeasurement'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          locale.translate('deleteMeasurementConfirmation'),
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              locale.translate('cancel'),
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(
              locale.translate('delete'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbService.deleteMeasurement(measurement.uniqueId);
        await _loadMeasurements(); // Reload the list
        
        if (mounted) {
          showNavigationMessage(
            context,
            locale.translate('success'),
            customMessage: locale.translate('measurementDeletedSuccessfully'),
            backgroundColor: Colors.green,
          );
        }
      } catch (e, stackTrace) {
        Logger.error('MeasurementListScreen', 'Failed to delete measurement', error: e, stackTrace: stackTrace);
        
        if (mounted) {
          showNavigationMessage(
            context,
            locale.translate('error'),
            customMessage: locale.translate('failedToDeleteMeasurement'),
            backgroundColor: Colors.red,
          );
        }
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
            title: locale.translate('measurements'),
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
            child: Column(
              children: [
                _buildHeaderSection(locale),
                _buildSearchAndFilterSection(locale),
                Expanded(child: _buildMeasurementsList(locale)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              context.goNamed(
                RouteNames.measurementCategory,
                pathParameters: {'customerId': widget.customerId},
              );
            },
            backgroundColor: const Color(AppConstants.primaryTeal),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              locale.translate('addMeasurement'),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryTeal),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.straighten_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.translate('customerMeasurements'),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _customerName != null 
                      ? '${locale.translate('customer')}: $_customerName'
                      : locale.translate('loadingCustomerInfo'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${_allMeasurements.length} ${locale.translate('totalMeasurements')}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection(AppLocalizations locale) {
    final uniqueDressTypes = _allMeasurements
        .map((m) => m.dressType)
        .toSet()
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: locale.translate('searchMeasurements'),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(AppConstants.primaryTeal),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterMeasurements('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: _filterMeasurements,
            ),
          ),
          // Filter chips
          if (uniqueDressTypes.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('all', locale.translate('all'), locale),
                  ...uniqueDressTypes.map((dressType) {
                    final details = MeasurementConstants.getDressTypeDetails(dressType);
                    return _buildFilterChip(
                      dressType,
                      details?['name'] ?? dressType,
                      locale,
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, AppLocalizations locale) {
    final isSelected = _selectedFilter == filter;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
          });
          _filterMeasurements(_searchController.text);
        },
        backgroundColor: Colors.grey[100],
        selectedColor: const Color(AppConstants.primaryTeal),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected 
              ? const Color(AppConstants.primaryTeal) 
              : Colors.grey.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildMeasurementsList(AppLocalizations locale) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(AppConstants.primaryTeal)),
        ),
      );
    }

    if (_filteredMeasurements.isEmpty) {
      return _buildEmptyState(locale);
    }

    return RefreshIndicator(
      onRefresh: _loadMeasurements,
      color: const Color(AppConstants.primaryTeal),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        itemCount: _filteredMeasurements.length,
        itemBuilder: (context, index) {
          final measurement = _filteredMeasurements[index];
          return _buildMeasurementCard(measurement, locale);
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.straighten_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty || _selectedFilter != 'all'
                ? locale.translate('noMeasurementsFound')
                : locale.translate('noMeasurementsYet'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _selectedFilter != 'all'
                ? locale.translate('tryDifferentSearchTerm')
                : locale.translate('addFirstMeasurement'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          if (_searchController.text.isEmpty && _selectedFilter == 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.goNamed(
                  RouteNames.measurementCategory,
                  pathParameters: {'customerId': widget.customerId},
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                locale.translate('addMeasurement'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryTeal),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(Measurement measurement, AppLocalizations locale) {
    final dressTypeDetails = MeasurementConstants.getDressTypeDetails(measurement.dressType);
    final measurementCount = measurement.measurements.length;
    final requiredCount = MeasurementConstants.getMeasurementsForDressType(measurement.dressType).length;
    final completionPercentage = requiredCount > 0 ? (measurementCount / requiredCount * 100) : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            context.goNamed(
              RouteNames.editMeasurement,
              pathParameters: {'measurementId': measurement.uniqueId},
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getDressTypeIcon(dressTypeDetails?['icon']),
                        color: const Color(AppConstants.primaryTeal),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dressTypeDetails?['name'] ?? measurement.dressType,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    context.goNamed(
                                      RouteNames.editMeasurement,
                                      pathParameters: {'measurementId': measurement.uniqueId},
                                    );
                                  } else if (action == 'delete') {
                                    _deleteMeasurement(measurement, locale);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit, size: 18),
                                        const SizedBox(width: 8),
                                        Text(locale.translate('edit')),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete, size: 18, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Text(
                                          locale.translate('delete'),
                                          style: const TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                child: const Icon(Icons.more_vert, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${locale.translate('created')}: ${_formatDate(measurement.createdAt)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (measurement.createdAt != measurement.updatedAt) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${locale.translate('updated')}: ${_formatDate(measurement.updatedAt)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.translate('progress'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: completionPercentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(AppConstants.primaryTeal)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$measurementCount/$requiredCount ${locale.translate('measurements')} (${completionPercentage.toStringAsFixed(0)}%)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: completionPercentage == 100 
                            ? Colors.green.withOpacity(0.1)
                            : const Color(AppConstants.primaryTeal).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        completionPercentage == 100 
                            ? locale.translate('complete')
                            : locale.translate('incomplete'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: completionPercentage == 100 
                              ? Colors.green[700]
                              : const Color(AppConstants.primaryTeal),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get appropriate icon for dress type
  IconData _getDressTypeIcon(String? iconString) {
    switch (iconString) {
      case 'shirt':
        return Icons.checkroom_rounded;
      case 'pant':
        return Icons.straighten_rounded;
      case 'suit':
        return Icons.business_center_rounded;
      case 'blazer':
        return Icons.work_outline_rounded;
      case 'kurta':
        return Icons.person_rounded;
      case 'sherwani':
        return Icons.star_rounded;
      case 'dress':
        return Icons.woman_rounded;
      case 'skirt':
        return Icons.woman_2_rounded;
      case 'blouse':
        return Icons.checkroom_outlined;
      case 'lehenga':
        return Icons.celebration_rounded;
      case 'saree':
        return Icons.accessibility_new_rounded;
      case 'gown':
        return Icons.nightlife_rounded;
      default:
        return Icons.checkroom_rounded;
    }
  }
}