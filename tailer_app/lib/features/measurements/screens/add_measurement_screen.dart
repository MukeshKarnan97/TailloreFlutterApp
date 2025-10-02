import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _formKey = GlobalKey<FormState>();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  
  String? _selectedDressType;
  final Map<String, double> _measurements = {};
  bool _isLoading = false;
  String? _customerName;

  @override
  void initState() {
    super.initState();
    _selectedDressType = widget.dressType;
    _loadCustomerInfo();
  }

  Future<void> _loadCustomerInfo() async {
    try {
      final customerData = await _dbService.getCustomerByUniqueId(widget.customerId);
      if (customerData != null && mounted) {
        setState(() {
          _customerName = customerData['name'];
        });
      }
    } catch (e) {
      Logger.error('AddMeasurementScreen', 'Failed to load customer info', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: DashboardHeader(
        title: 'Add Measurement',
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
          showNavigationMessage(context, 'Notifications');
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderSection(),
            if (_selectedDressType == null) _buildDressTypeSelection(),
            if (_selectedDressType != null) 
              Expanded(
                child: MeasurementForm(
                  key: _formKey,
                  dressType: _selectedDressType!,
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
      bottomNavigationBar: _selectedDressType != null 
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildHeaderSection() {
    final dressTypeDetails = _selectedDressType != null 
        ? MeasurementConstants.getDressTypeDetails(_selectedDressType!)
        : null;
    
    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
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
                  Colors.green,
                  Colors.green.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_circle_outline_rounded,
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
                  _selectedDressType != null 
                      ? 'Add ${dressTypeDetails?['name'] ?? _selectedDressType}'
                      : 'New Measurement',
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
                if (_selectedDressType != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${MeasurementConstants.getMeasurementsForDressType(_selectedDressType!).length} Measurements Required',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDressTypeSelection() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Text(
              'Please select a dress type to continue',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: MeasurementConstants.getAllDressTypes().length,
              itemBuilder: (context, index) {
                final dressType = MeasurementConstants.getAllDressTypes()[index];
                return _buildDressTypeCard(dressType);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDressTypeCard(String dressType) {
    final dressTypeDetails = MeasurementConstants.getDressTypeDetails(dressType);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDressType = dressType;
          _measurements.clear(); // Clear any existing measurements
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_rounded,
              size: 32,
              color: const Color(AppConstants.primaryTeal),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(_selectedDressType!);
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
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _selectedDressType = null;
                      _measurements.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(AppConstants.primaryTeal)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Change Type',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(AppConstants.primaryTeal),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryTeal),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Measurement',
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

  Future<void> _saveMeasurement() async {
    if (_selectedDressType == null) {
      showNavigationMessage(
        context,
        'Error',
        customMessage: 'Please select a dress type first.',
        backgroundColor: Colors.red,
      );
      return;
    }

    // Validate that at least some measurements are entered
    if (_measurements.isEmpty) {
      showNavigationMessage(
        context,
        'Error',
        customMessage: 'Please enter at least one measurement.',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Create measurement object using factory
      final measurement = Measurement.create(
        customerId: widget.customerId,
        dressType: _selectedDressType!,
        measurements: _measurements,
        notes: '', // Can be added later if needed
      );

      // Save to database
      await _dbService.insertMeasurement(measurement);

      Logger.info('AddMeasurementScreen', 'Measurement saved successfully: ${measurement.uniqueId}');

      if (mounted) {
        // Navigate back to measurements list
        context.goNamed(RouteNames.measurementList, pathParameters: {'customerId': widget.customerId});
        
        // Show success message
        showNavigationMessage(
          context,
          'Success',
          customMessage: 'Measurement saved successfully!',
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
          'Error',
          customMessage: 'Failed to save measurement. Please try again.',
          backgroundColor: Colors.red,
        );
      }
    }
  }
}