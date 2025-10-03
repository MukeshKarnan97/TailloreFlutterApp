import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/core/constants/measurement_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/widgets/unit_selector.dart';
import 'package:tailer_app/data/models/measurement_model.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/core/utils/logger.dart';
import 'package:tailer_app/core/providers/measurement_unit_provider.dart';

import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';

class AddMeasurementScreen extends StatefulWidget {
  final String customerId;
  final String? dressType;
  
  const AddMeasurementScreen({
    Key? key,
    required this.customerId,
    this.dressType,
  }) : super(key: key);

  @override
  State<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> with NavigationMixin {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  late SimpleLocaleProvider _localeProvider;
  late MeasurementUnitProvider _unitProvider;
  
  String? _selectedDressType;
  final Map<String, double> _measurements = {};
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  String? _customerName;

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _unitProvider = MeasurementUnitProvider();
    _selectedDressType = widget.dressType;
    _loadCustomerInfo();
    _initializeUnitProvider();
  }

  Future<void> _initializeUnitProvider() async {
    await _unitProvider.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerInfo() async {
    try {
      final customerData = await _dbService.getCustomerByUniqueId(widget.customerId);
      if (customerData != null && mounted) {
        setState(() {
          _customerName = customerData['name'];
        });
      }
    } catch (e, stackTrace) {
      Logger.error('AddMeasurementScreen', 'Failed to load customer info', error: e, stackTrace: stackTrace);
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
            title: locale.translate('addMeasurement'),
            backgroundColor: const Color(AppConstants.primaryTeal),
            notificationCount: 3,
            onBackPressed: () {
              if (_selectedDressType == null) {
                context.goNamed(RouteNames.measurementCategory, pathParameters: {'customerId': widget.customerId});
              } else {
                context.goNamed(RouteNames.measurementList, pathParameters: {'customerId': widget.customerId});
              }
            },
            onNotificationTap: () {
              showNavigationMessage(context, locale.translate('notifications'));
            },
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeaderSection(locale),
                if (_selectedDressType == null) _buildDressTypeSelection(locale),
                if (_selectedDressType != null) 
                  Expanded(
                    child: _buildMeasurementForm(locale),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: _selectedDressType != null ? _buildBottomBar(locale) : null,
        );
      },
    );
  }

  Widget _buildHeaderSection(AppLocalizations locale) {
    final dressTypeDetails = _selectedDressType != null 
        ? MeasurementConstants.getDressTypeDetails(_selectedDressType!)
        : null;
    
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
              color: _selectedDressType != null 
                  ? const Color(AppConstants.primaryTeal) 
                  : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getDressTypeIcon(dressTypeDetails?['icon']),
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
                  _selectedDressType != null 
                      ? '${locale.translate('newMeasurement')} - ${dressTypeDetails?['name'] ?? _selectedDressType}'
                      : locale.translate('chooseDressType'),
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
                if (_selectedDressType != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${_getCompletionPercentage().toStringAsFixed(0)}% ${locale.translate('completed')}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_selectedDressType != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDressType = null;
                  _measurements.clear();
                });
              },
              child: Text(
                locale.translate('changeType'),
                style: GoogleFonts.inter(
                  color: const Color(AppConstants.primaryTeal),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDressTypeSelection(AppLocalizations locale) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.translate('selectDressType'),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: MeasurementConstants.getAllDressTypes().length,
                itemBuilder: (context, index) {
                  final dressType = MeasurementConstants.getAllDressTypes()[index];
                  return _buildDressTypeCard(dressType, locale);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDressTypeCard(String dressType, AppLocalizations locale) {
    final dressTypeDetails = MeasurementConstants.getDressTypeDetails(dressType);
    
    return Container(
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
            setState(() {
              _selectedDressType = dressType;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                    size: 32,
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementForm(AppLocalizations locale) {
    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(_selectedDressType!);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.translate('measurementsRequired'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Unit Selector
          UnitSelector(
            currentUnit: _unitProvider.currentUnit,
            onUnitChanged: (newUnit) async {
              await _unitProvider.updateUnit(newUnit);
              setState(() {});
            },
          ),
          const SizedBox(height: 20),
          
          ...requiredMeasurements.map((measurement) => _buildMeasurementField(measurement, locale)),
          const SizedBox(height: 24),
          _buildAdditionalDetailsSection(locale),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildMeasurementField(String measurement, AppLocalizations locale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MeasurementConstants.getMeasurementDetails(measurement)?['name'] ?? measurement,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _measurements[measurement]?.toString() ?? '',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: locale.translate('enterMeasurement'),
              suffixText: _unitProvider.unitSymbol,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(AppConstants.primaryTeal)),
              ),
            ),
            onChanged: (value) {
              setState(() {
                if (value.isEmpty) {
                  _measurements.remove(measurement);
                } else {
                  final doubleValue = double.tryParse(value);
                  if (doubleValue != null) {
                    _measurements[measurement] = doubleValue;
                  }
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetailsSection(AppLocalizations locale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_add_rounded,
                color: const Color(AppConstants.primaryTeal),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                locale.translate('additionalDetails'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  locale.translate('optional'),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: locale.translate('additionalDetailsHint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(AppConstants.primaryTeal)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations locale) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  value: _getCompletionPercentage() / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(AppConstants.primaryTeal)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getCompletionPercentage().toStringAsFixed(0)}% ${locale.translate('completed')}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _saveMeasurement(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryTeal),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    locale.translate('saveMeasurement'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _getCompletionPercentage() {
    if (_selectedDressType == null) return 0.0;
    
    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(_selectedDressType!);
    if (requiredMeasurements.isEmpty) return 0.0;
    
    int completedCount = 0;
    for (String category in requiredMeasurements) {
      if (_measurements.containsKey(category) && _measurements[category]! > 0) {
        completedCount++;
      }
    }
    
    return (completedCount / requiredMeasurements.length) * 100;
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

  Future<void> _saveMeasurement() async {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    if (_selectedDressType == null) {
      showNavigationMessage(
        context,
        locale.translate('error'),
        customMessage: locale.translate('pleaseSelectDressTypeFirst'),
        backgroundColor: Colors.red,
      );
      return;
    }

    // Validate that at least some measurements are entered
    if (_measurements.isEmpty) {
      showNavigationMessage(
        context,
        locale.translate('error'),
        customMessage: locale.translate('pleaseEnterAtLeastOneMeasurement'),
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Validate customer ID
      if (widget.customerId.isEmpty) {
        throw Exception('Invalid customer ID');
      }

      // Validate measurements data
      final filteredMeasurements = Map<String, double>.from(_measurements);
      filteredMeasurements.removeWhere((key, value) => value <= 0);
      
      if (filteredMeasurements.isEmpty) {
        throw Exception('Please enter at least one valid measurement value');
      }

      // Create measurement object using factory
      final measurement = Measurement.create(
        customerId: widget.customerId,
        dressType: _selectedDressType!,
        measurements: filteredMeasurements,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      Logger.info('AddMeasurementScreen', 'Attempting to save measurement: ${measurement.uniqueId}');

      // Save to database
      await _dbService.insertMeasurement(measurement);

      Logger.info('AddMeasurementScreen', 'Measurement saved successfully: ${measurement.uniqueId}');

      if (mounted) {
        // Navigate back to measurements list
        context.goNamed(RouteNames.measurementList, pathParameters: {'customerId': widget.customerId});
        
        // Show success message
        showNavigationMessage(
          context,
          locale.translate('success'),
          customMessage: locale.translate('measurementSavedSuccessfully'),
          backgroundColor: Colors.green,
        );
      }
    } catch (e, stackTrace) {
      Logger.error('AddMeasurementScreen', 'Failed to save measurement', 
                  error: e, stackTrace: stackTrace);
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        showNavigationMessage(
          context,
          locale.translate('error'),
          customMessage: locale.translate('failedToSaveMeasurement'),
          backgroundColor: Colors.red,
        );
      }
    }
  }
}