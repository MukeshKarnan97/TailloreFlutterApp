import 'package:flutter/material.dart';
import '../../../core/constants/measurement_constants.dart';
import '../../../data/models/measurement_model.dart';
import '../../../data/services/local_db_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/unit_converter.dart';

class OrderMeasurementForm extends StatefulWidget {
  final String? customerId;
  final String? dressType;
  final Map<String, double>? initialMeasurements;
  final Function(Map<String, double>) onMeasurementsChanged;
  final bool enabled;

  const OrderMeasurementForm({
    super.key,
    required this.customerId,
    required this.dressType,
    this.initialMeasurements,
    required this.onMeasurementsChanged,
    this.enabled = true,
  });

  @override
  State<OrderMeasurementForm> createState() => _OrderMeasurementFormState();
}

class _OrderMeasurementFormState extends State<OrderMeasurementForm> {
  final Map<String, TextEditingController> _controllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, double> _measurements = {};
  bool _isLoading = false;
  bool _measurementsLoaded = false;
  String _currentUnit = 'inches';

  @override
  void initState() {
    super.initState();
    _initializeMeasurements();
  }

  @override
  void didUpdateWidget(OrderMeasurementForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Re-initialize if customer or dress type changed
    if (oldWidget.customerId != widget.customerId || 
        oldWidget.dressType != widget.dressType) {
      _initializeMeasurements();
    }
  }

  void _initializeMeasurements() {
    if (widget.dressType == null) {
      _clearMeasurements();
      return;
    }

    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(widget.dressType!);
    
    // Clear existing controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    
    // Initialize controllers and measurements
    _measurements.clear();
    for (final measurement in requiredMeasurements) {
      _controllers[measurement] = TextEditingController();
      _measurements[measurement] = 0.0;
    }
    
    // Load existing measurements or use initial values
    if (widget.initialMeasurements != null) {
      _loadInitialMeasurements();
    } else if (widget.customerId != null) {
      _loadExistingMeasurements();
    }
    
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _clearMeasurements() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _measurements.clear();
    _measurementsLoaded = false;
    
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _loadInitialMeasurements() {
    for (final entry in widget.initialMeasurements!.entries) {
      if (_controllers.containsKey(entry.key)) {
        final value = _convertToDisplayUnit(entry.value);
        _controllers[entry.key]!.text = value.toStringAsFixed(2);
        _measurements[entry.key] = entry.value; // Store in inches
      }
    }
    
    _measurementsLoaded = true;
    widget.onMeasurementsChanged(_measurements);
  }

  void _loadExistingMeasurements() async {
    if (widget.customerId == null || widget.dressType == null) return;
    
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });

      try {
        Logger.info('OrderMeasurementForm', 'Loading existing measurements for customer ${widget.customerId}');
        
        final dbService = LocalDatabaseService();
        final measurementMaps = await dbService.getMeasurementsByType(
          widget.customerId!,
          widget.dressType!,
        );
        
        if (measurementMaps.isNotEmpty && mounted) {
          final measurement = Measurement.fromMap(measurementMaps.first);
          
          Logger.info('OrderMeasurementForm', 'Found existing measurements, populating form');
          
          for (final entry in measurement.measurements.entries) {
            if (_controllers.containsKey(entry.key)) {
              final value = _convertToDisplayUnit(entry.value);
              _controllers[entry.key]!.text = value.toStringAsFixed(2);
              _measurements[entry.key] = entry.value; // Store in inches
            }
          }
          
          _measurementsLoaded = true;
          widget.onMeasurementsChanged(_measurements);
        } else {
          Logger.info('OrderMeasurementForm', 'No existing measurements found');
          _measurementsLoaded = true;
        }
      } catch (e, stackTrace) {
        Logger.error('OrderMeasurementForm', 'Failed to load existing measurements', error: e, stackTrace: stackTrace);
        _measurementsLoaded = true;
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  double _convertToDisplayUnit(double valueInInches) {
    return UnitConverter.convertValue(valueInInches, 'inches', _currentUnit);
  }

  double _convertFromDisplayUnit(double displayValue) {
    return UnitConverter.convertValue(displayValue, _currentUnit, 'inches');
  }

  void _onMeasurementChanged(String measurementKey, String value) {
    final numericValue = double.tryParse(value) ?? 0.0;
    
    // Convert to inches for storage
    final valueInInches = _convertFromDisplayUnit(numericValue);
    _measurements[measurementKey] = valueInInches;
    
    widget.onMeasurementsChanged(_measurements);
  }

  void _onUnitChanged(String newUnit) {
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentUnit = newUnit;
        });
        
        // Update all displayed values
        for (final entry in _measurements.entries) {
          if (_controllers.containsKey(entry.key) && entry.value > 0) {
            final displayValue = _convertToDisplayUnit(entry.value);
            _controllers[entry.key]!.text = displayValue.toStringAsFixed(2);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dressType == null) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.straighten,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Select a dress type to enter measurements',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Measurements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.black
                  ),
                ),
                const Spacer(),
                _buildUnitSelector(),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (_controllers.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No measurements required for this dress type',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ] else ...[
              if (_measurementsLoaded && widget.customerId != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Measurements pre-populated from existing customer data',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              Form(
                key: _formKey,
                child: Column(
                  children: _controllers.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        controller: entry.value,
                        enabled: widget.enabled,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
            color: Colors.black, // <-- main text color while typing
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
                        decoration: InputDecoration(
                          labelText: _formatMeasurementName(entry.key),
                          floatingLabelStyle: const TextStyle(color: Colors.black),
                          suffixText: UnitConverter.getUnitSymbol(_currentUnit),
                          suffixStyle: const TextStyle(color: Colors.black87),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter ${_formatMeasurementName(entry.key).toLowerCase()}';
                          }
                          final numValue = double.tryParse(value);
                          if (numValue == null || numValue <= 0) {
                            return 'Please enter a valid measurement';
                          }
                          return null;
                        },
                        onChanged: (value) => _onMeasurementChanged(entry.key, value),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnitSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border.all(color: Theme.of(context).primaryColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentUnit,
          isDense: true,
          icon: Icon(
          Icons.arrow_drop_down, // 👈 Make dropdown icon visible
          color: Theme.of(context).primaryColor,
        ),
        dropdownColor: Colors.white,
          items: UnitConverter.getAllUnits().map((String unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: Text(
                UnitConverter.getUnitSymbol(unit),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: widget.enabled ? (String? newValue) {
            if (newValue != null) {
              _onUnitChanged(newValue);
            }
          } : null,
        ),
      ),
    );
  }

  String _formatMeasurementName(String measurement) {
    return measurement.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  bool isValid() {
    return _formKey.currentState?.validate() ?? false;
  }
}