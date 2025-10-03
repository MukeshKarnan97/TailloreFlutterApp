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

class EditMeasurementScreen extends StatefulWidget {
  final String measurementId;
  
  const EditMeasurementScreen({Key? key, required this.measurementId}) : super(key: key);

  @override
  State<EditMeasurementScreen> createState() => _EditMeasurementScreenState();
}

class _EditMeasurementScreenState extends State<EditMeasurementScreen> with NavigationMixin {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  late SimpleLocaleProvider _localeProvider;
  late MeasurementUnitProvider _unitProvider;
  
  Measurement? _measurement;
  Map<String, double> _measurements = {};
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _customerName;

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider();
    _unitProvider = MeasurementUnitProvider();
    _loadMeasurement();
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

  Future<void> _loadMeasurement() async {
    try {
      setState(() => _isLoading = true);
      
      Logger.info('EditMeasurementScreen', 'Loading measurement with ID: ${widget.measurementId}');
      
      // Load measurement data
      final measurementData = await _dbService.select(
        'measurement',
        where: 'unique_id = ?',
        whereArgs: [widget.measurementId],
      );
      
      Logger.info('EditMeasurementScreen', 'Raw measurement data: $measurementData');
      
      if (measurementData.isNotEmpty) {
        _measurement = Measurement.fromMap(measurementData.first);
        _measurements = Map<String, double>.from(_measurement!.measurements);
        _notesController.text = _measurement!.notes ?? '';
        
        Logger.info('EditMeasurementScreen', 'Parsed measurement - Dress type: ${_measurement!.dressType}');
        Logger.info('EditMeasurementScreen', 'Parsed measurements: $_measurements');
        Logger.info('EditMeasurementScreen', 'Notes: ${_measurement!.notes}');
        
        // Load customer info
        final customerData = await _dbService.getCustomerByUniqueId(_measurement!.customerId);
        if (customerData != null) {
          _customerName = customerData['name'];
          Logger.info('EditMeasurementScreen', 'Customer name: $_customerName');
        }
        
        // Check required measurements for dress type
        final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(_measurement!.dressType);
        Logger.info('EditMeasurementScreen', 'Required measurements for ${_measurement!.dressType}: $requiredMeasurements');
      } else {
        Logger.warning('EditMeasurementScreen', 'No measurement found with ID: ${widget.measurementId}');
      }
      
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      Logger.error('EditMeasurementScreen', 'Failed to load measurement', error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
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
            title: locale.translate('editMeasurement'),
            backgroundColor: const Color(AppConstants.primaryTeal),
            notificationCount: 3,
            onBackPressed: () {
              if (_measurement != null) {
                context.goNamed(RouteNames.measurementList, pathParameters: {'customerId': _measurement!.customerId});
              } else {
                context.pop();
              }
            },
            onNotificationTap: () {
              showNavigationMessage(context, locale.translate('notifications'));
            },
          ),
          body: SafeArea(
            child: _isLoading ? _buildLoadingState(locale) : _buildContent(locale),
          ),
          bottomNavigationBar: !_isLoading && _measurement != null ? _buildBottomBar(locale) : null,
        );
      },
    );
  }

  Widget _buildLoadingState(AppLocalizations locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(AppConstants.primaryTeal)),
          ),
          const SizedBox(height: 16),
          Text(
            locale.translate('loadingMeasurement'),
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations locale) {
    if (_measurement == null) {
      return _buildErrorState(locale);
    }

    return Column(
      children: [
        _buildHeaderSection(locale),
        Expanded(child: _buildMeasurementForm(locale)),
      ],
    );
  }

  Widget _buildErrorState(AppLocalizations locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            locale.translate('measurementNotFound'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            locale.translate('measurementNotFoundDescription'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryTeal),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              locale.translate('goBack'),
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

  Widget _buildHeaderSection(AppLocalizations locale) {
    final dressTypeDetails = MeasurementConstants.getDressTypeDetails(_measurement!.dressType);
    
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
                  '${locale.translate('editMeasurement')} - ${dressTypeDetails?['name'] ?? _measurement!.dressType}',
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
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${locale.translate('lastUpdated')}: ${_formatDate(_measurement!.updatedAt)}',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 14, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  locale.translate('editing'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementForm(AppLocalizations locale) {
    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(_measurement!.dressType);
    
    Logger.info('EditMeasurementScreen', 'Building form - Required measurements: $requiredMeasurements');
    Logger.info('EditMeasurementScreen', 'Building form - Current measurements: $_measurements');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.translate('measurementDetails'),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  MeasurementConstants.getMeasurementDetails(measurement)?['name'] ?? measurement,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (_measurements.containsKey(measurement))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    locale.translate('filled'),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(AppConstants.primaryTeal),
                    ),
                  ),
                ),
            ],
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
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => _resetMeasurements(locale),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(AppConstants.primaryTeal)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                locale.translate('resetChanges'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(AppConstants.primaryTeal),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _saveMeasurement(locale),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryTeal),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      locale.translate('saveChanges'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetMeasurements(AppLocalizations locale) {
    setState(() {
      _measurements = Map<String, double>.from(_measurement!.measurements);
      _notesController.text = _measurement!.notes ?? '';
    });
    
    showNavigationMessage(
      context,
      locale.translate('success'),
      customMessage: locale.translate('changesReset'),
      backgroundColor: Colors.blue,
    );
  }

  Future<void> _saveMeasurement(AppLocalizations locale) async {
    try {
      setState(() => _isSaving = true);

      // Update measurement object
      final updatedMeasurement = _measurement!.copyWith(
        measurements: _measurements,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        updatedAt: DateTime.now(),
      );

      // Save to database
      await _dbService.updateMeasurement(updatedMeasurement.uniqueId, updatedMeasurement.toMap());

      Logger.info('EditMeasurementScreen', 'Measurement updated successfully: ${updatedMeasurement.uniqueId}');

      if (mounted) {
        // Navigate back to measurements list
        context.goNamed(RouteNames.measurementList, pathParameters: {'customerId': _measurement!.customerId});
        
        // Show success message
        showNavigationMessage(
          context,
          locale.translate('success'),
          customMessage: locale.translate('measurementUpdatedSuccessfully'),
          backgroundColor: Colors.green,
        );
      }
    } catch (e, stackTrace) {
      Logger.error('EditMeasurementScreen', 'Failed to update measurement', 
                  error: e, stackTrace: stackTrace);
      
      setState(() => _isSaving = false);
      
      if (mounted) {
        showNavigationMessage(
          context,
          locale.translate('error'),
          customMessage: locale.translate('failedToUpdateMeasurement'),
          backgroundColor: Colors.red,
        );
      }
    }
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