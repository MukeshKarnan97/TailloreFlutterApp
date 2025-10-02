import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/core/constants/measurement_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/data/models/measurement_model.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/core/utils/logger.dart';
import 'package:tailer_app/features/measurements/widgets/measurement_form.dart';

class EditMeasurementScreen extends StatefulWidget {
  final String measurementId;
  
  const EditMeasurementScreen({Key? key, required this.measurementId}) : super(key: key);

  @override
  State<EditMeasurementScreen> createState() => _EditMeasurementScreenState();
}

class _EditMeasurementScreenState extends State<EditMeasurementScreen> with NavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  
  Measurement? _measurement;
  Map<String, double> _measurements = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _customerName;

  @override
  void initState() {
    super.initState();
    _loadMeasurement();
  }

  Future<void> _loadMeasurement() async {
    try {
      setState(() => _isLoading = true);
      
      // Load measurement data
      final measurementData = await _dbService.select(
        'measurement',
        where: 'unique_id = ?',
        whereArgs: [widget.measurementId],
      );
      
      if (measurementData.isNotEmpty) {
        _measurement = Measurement.fromMap(measurementData.first);
        _measurements = Map<String, double>.from(_measurement!.measurements);
        
        // Load customer name
        final customerData = await _dbService.getCustomerByUniqueId(_measurement!.customerId);
        if (customerData != null) {
          _customerName = customerData['name'];
        }
      }
      
      setState(() => _isLoading = false);
      
      Logger.info('EditMeasurementScreen', 'Loaded measurement ${widget.measurementId}');
    } catch (e, stackTrace) {
      Logger.error('EditMeasurementScreen', 'Failed to load measurement', 
                  error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
      
      if (mounted) {
        showNavigationMessage(
          context,
          'Load Failed',
          customMessage: 'Failed to load measurement. Please try again.',
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
        title: 'Edit Measurement',
        backgroundColor: const Color(AppConstants.primaryTeal),
        notificationCount: 3,
        onBackPressed: () {
          if (_measurement?.customerId != null) {
            context.goNamed(RouteNames.measurementList, pathParameters: {'customerId': _measurement!.customerId});
          }
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
            : _measurement == null
                ? _buildErrorView()
                : Column(
                    children: [
                      _buildHeaderSection(),
                      Expanded(
                        child: MeasurementForm(
                          key: _formKey,
                          dressType: _measurement!.dressType,
                          measurements: _measurements,
                          onMeasurementChanged: (category, value) {
                            setState(() {
                              _measurements[category] = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: _measurement != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildHeaderSection() {
    final dressTypeDetails = MeasurementConstants.getDressTypeDetails(_measurement!.dressType);
    
    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
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
                  Colors.orange,
                  Colors.orange.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_rounded,
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
                  'Edit ${dressTypeDetails?['name'] ?? _measurement!.dressType}',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _customerName ?? 'Customer Measurement',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'ID: ${_measurement!.uniqueId}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Created: ${_formatDate(_measurement!.createdAt)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                          letterSpacing: 0.2,
                        ),
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

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Measurement Not Found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The requested measurement could not be loaded.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.goNamed(RouteNames.customers),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryTeal),
            ),
            child: Text(
              'Go Back',
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

  Widget _buildBottomBar() {
    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(_measurement!.dressType);
    final completionPercentage = _getCompletionPercentage(requiredMeasurements);
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress: ${completionPercentage.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${_measurements.length} / ${requiredMeasurements.length} completed',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completionPercentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              completionPercentage >= 80 
                  ? Colors.green 
                  : completionPercentage >= 50 
                      ? Colors.orange 
                      : Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () {
                    context.goNamed(RouteNames.measurementList, pathParameters: {'customerId': _measurement!.customerId});
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Update Measurement',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getCompletionPercentage(List<String> requiredMeasurements) {
    if (requiredMeasurements.isEmpty) return 0.0;
    
    int completedCount = 0;
    for (String category in requiredMeasurements) {
      if (_measurements.containsKey(category) && _measurements[category]! > 0) {
        completedCount++;
      }
    }
    
    return (completedCount / requiredMeasurements.length) * 100;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveMeasurement() async {
    if (_measurement == null) return;

    try {
      setState(() => _isSaving = true);

      // Update measurement in database
      await _dbService.updateMeasurement(_measurement!.uniqueId, {
        'measurements': _measurements,
        'updated_at': DateTime.now().toIso8601String(),
      });

      Logger.info('EditMeasurementScreen', 'Measurement updated successfully: ${_measurement!.uniqueId}');

      if (mounted) {
        // Navigate back to measurements list
        context.goNamed(RouteNames.measurementList, pathParameters: {'customerId': _measurement!.customerId});
        
        // Show success message
        showNavigationMessage(
          context,
          'Success',
          customMessage: 'Measurement updated successfully!',
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
          'Error',
          customMessage: 'Failed to update measurement. Please try again.',
          backgroundColor: Colors.red,
        );
      }
    }
  }
}