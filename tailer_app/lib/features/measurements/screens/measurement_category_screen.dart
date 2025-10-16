import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/measurement_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/core/utils/logger.dart';

class MeasurementCategoryScreen extends StatefulWidget {
  final String customerId;
  
  const MeasurementCategoryScreen({super.key, required this.customerId});

  @override
  State<MeasurementCategoryScreen> createState() => _MeasurementCategoryScreenState();
}

class _MeasurementCategoryScreenState extends State<MeasurementCategoryScreen> with NavigationMixin {
  final _searchController = TextEditingController();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  
  List<String> _filteredDressTypes = [];
  late SimpleLocaleProvider _localeProvider;
  String? _customerName;
  bool _isLoading = true;
  Map<String, int> _measurementCounts = {};

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _filteredDressTypes = MeasurementConstants.getAllDressTypes();
    _loadCustomerData();
    _loadMeasurementCounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    try {
      final customerData = await _dbService.getCustomerByUniqueId(widget.customerId);
      if (customerData != null && mounted) {
        setState(() {
          _customerName = customerData['name'];
        });
      }
    } catch (e, stackTrace) {
      Logger.error('MeasurementCategoryScreen', 'Failed to load customer data', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _loadMeasurementCounts() async {
    try {
      setState(() => _isLoading = true);
      
      // Get all measurements for this customer
      final measurements = await _dbService.select(
        'measurement',
        where: 'customer_id = ?',
        whereArgs: [widget.customerId],
      );
      
      // Count measurements by dress type
      final counts = <String, int>{};
      for (final measurementData in measurements) {
        final dressType = measurementData['dress_type'] as String;
        counts[dressType] = (counts[dressType] ?? 0) + 1;
      }
      
      setState(() {
        _measurementCounts = counts;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Logger.error('MeasurementCategoryScreen', 'Failed to load measurement counts', error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
    }
  }

  void _filterDressTypes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDressTypes = MeasurementConstants.getAllDressTypes();
      } else {
        _filteredDressTypes = MeasurementConstants.getAllDressTypes()
            .where((dressType) {
          final dressTypeDetails = MeasurementConstants.getDressTypeDetails(dressType);
          final name = dressTypeDetails?['name']?.toLowerCase() ?? dressType.toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, _) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: DashboardHeader(
            title: locale.translate('selectDressType'),
            backgroundColor: const Color(AppConstants.primaryTeal),
            notificationCount: 3,
            onBackPressed: () {
              context.goNamed(
                RouteNames.measurementList,
                pathParameters: {'customerId': widget.customerId},
              );
            },
            onNotificationTap: () {
              showNavigationMessage(context, locale.translate('notifications'));
            },
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeaderSection(locale),
                _buildSearchSection(locale),
                Expanded(child: _buildDressTypeGrid(locale)),
              ],
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
              Icons.category_rounded,
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
                  locale.translate('chooseDressTypeToMeasure'),
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
                      locale.translate('selectDressTypeDescription'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
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

  Widget _buildSearchSection(AppLocalizations locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: Container(
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
            hintText: locale.translate('searchDressTypes'),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(AppConstants.primaryTeal),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterDressTypes('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: _filterDressTypes,
        ),
      ),
    );
  }

  Widget _buildDressTypeGrid(AppLocalizations locale) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(AppConstants.primaryTeal)),
        ),
      );
    }

    if (_filteredDressTypes.isEmpty) {
      return _buildEmptyState(locale);
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredDressTypes.length,
        itemBuilder: (context, index) {
          final dressType = _filteredDressTypes[index];
          return _buildDressTypeCard(dressType, locale);
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
            Icons.search_off,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            locale.translate('noDressTypesFound'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            locale.translate('tryDifferentSearchTerm'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDressTypeCard(String dressType, AppLocalizations locale) {
    final dressTypeDetails = MeasurementConstants.getDressTypeDetails(dressType);
    final measurementCount = _measurementCounts[dressType] ?? 0;
    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(dressType);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: measurementCount > 0 
              ? const Color(AppConstants.primaryTeal).withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          width: measurementCount > 0 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: measurementCount > 0 
                ? const Color(AppConstants.primaryTeal).withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: measurementCount > 0 ? 15 : 10,
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
              RouteNames.addMeasurement,
              pathParameters: {
                'customerId': widget.customerId,
              },
              queryParameters: {
                'dressType': dressType,
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: measurementCount > 0 
                            ? const Color(AppConstants.primaryTeal)
                            : const Color(AppConstants.primaryTeal).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getDressTypeIcon(dressTypeDetails?['icon']),
                        color: measurementCount > 0 
                            ? Colors.white
                            : const Color(AppConstants.primaryTeal),
                        size: 28,
                      ),
                    ),
                    if (measurementCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$measurementCount',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  dressTypeDetails?['name'] ?? dressType,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${requiredMeasurements.length} ${locale.translate('measurements')}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (measurementCount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$measurementCount ${locale.translate('existing')}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}