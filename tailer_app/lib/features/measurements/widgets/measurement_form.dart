import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/measurement_constants.dart';

class MeasurementForm extends StatefulWidget {
  final String dressType;
  final Map<String, double> measurements;
  final Function(String category, double value) onMeasurementChanged;

  const MeasurementForm({
    Key? key,
    required this.dressType,
    required this.measurements,
    required this.onMeasurementChanged,
  }) : super(key: key);

  @override
  State<MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<MeasurementForm> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(widget.dressType);
    
    for (String category in requiredMeasurements) {
      _controllers[category] = TextEditingController(
        text: widget.measurements[category]?.toString() ?? '',
      );
      _focusNodes[category] = FocusNode();
      
      // Add listener to update measurements
      _controllers[category]!.addListener(() {
        final text = _controllers[category]!.text;
        if (text.isEmpty) {
          widget.measurements.remove(category);
        } else {
          final value = double.tryParse(text);
          if (value != null && value > 0) {
            widget.onMeasurementChanged(category, value);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(widget.dressType);
    final groupedMeasurements = _groupMeasurementsByBodyPart(requiredMeasurements);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dress type info card
          _buildDressTypeInfoCard(),
          const SizedBox(height: 20),
          
          // Measurement sections
          ...groupedMeasurements.entries.map((entry) {
            return _buildMeasurementSection(entry.key, entry.value);
          }).toList(),
          
          // Bottom spacing for the floating action buttons
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDressTypeInfoCard() {
    final dressTypeDetails = MeasurementConstants.getDressTypeDetails(widget.dressType);
    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(widget.dressType);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppConstants.primaryTeal).withOpacity(0.1),
            const Color(AppConstants.primaryTeal).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(AppConstants.primaryTeal).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: const Color(AppConstants.primaryTeal),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                dressTypeDetails?['name'] ?? widget.dressType,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(AppConstants.primaryTeal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dressTypeDetails?['description'] != null) ...[
            Text(
              dressTypeDetails!['description'],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(AppConstants.primaryTeal).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.straighten_rounded,
                  color: const Color(AppConstants.primaryTeal),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${requiredMeasurements.length} measurements required',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(AppConstants.primaryTeal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementSection(String bodyPart, List<String> measurements) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getBodyPartIcon(bodyPart),
                  color: const Color(AppConstants.primaryTeal),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  bodyPart.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${measurements.length} items',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(AppConstants.primaryTeal),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Measurement fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: measurements.map((category) {
                return _buildMeasurementField(category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementField(String category) {
    final measurementDetails = MeasurementConstants.getMeasurementDetails(category);
    final isCompleted = widget.measurements.containsKey(category) && 
                       widget.measurements[category]! > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field label with completion indicator
          Row(
            children: [
              Expanded(
                child: Text(
                  measurementDetails?['name'] ?? category,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Input field
          TextFormField(
            controller: _controllers[category],
            focusNode: _focusNodes[category],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Enter ${measurementDetails?['name'] ?? category}',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              suffixText: measurementDetails?['unit'] ?? 'inches',
              suffixStyle: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                Icons.straighten_rounded,
                color: isCompleted 
                    ? Colors.green 
                    : const Color(AppConstants.primaryTeal),
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isCompleted 
                      ? Colors.green.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isCompleted 
                      ? Colors.green
                      : const Color(AppConstants.primaryTeal),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isCompleted 
                  ? Colors.green.withOpacity(0.05)
                  : Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onFieldSubmitted: (_) {
              // Move to next field
              _focusNextField(category);
            },
          ),
          
          // Instruction text
          if (measurementDetails?['instruction'] != null) ...[
            const SizedBox(height: 6),
            Text(
              measurementDetails!['instruction'],
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getBodyPartIcon(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'chest':
      case 'bust':
        return Icons.favorite_rounded;
      case 'waist':
        return Icons.fitness_center_rounded;
      case 'hip':
        return Icons.accessibility_rounded;
      case 'shoulder':
        return Icons.accessibility_new_rounded;
      case 'arm':
      case 'sleeve':
        return Icons.pan_tool_rounded;
      case 'neck':
        return Icons.face_rounded;
      case 'length':
        return Icons.height_rounded;
      case 'leg':
        return Icons.directions_walk_rounded;
      default:
        return Icons.straighten_rounded;
    }
  }

  Map<String, List<String>> _groupMeasurementsByBodyPart(List<String> measurements) {
    final grouped = <String, List<String>>{};
    
    for (String measurement in measurements) {
      final bodyPart = _categorizeByBodyPart(measurement);
      grouped.putIfAbsent(bodyPart, () => []).add(measurement);
    }
    
    // Sort body parts in logical order
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final order = ['Chest', 'Waist', 'Hip', 'Shoulder', 'Arm', 'Neck', 'Length', 'Leg', 'Other'];
      final aIndex = order.indexOf(a);
      final bIndex = order.indexOf(b);
      if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });
    
    final sortedGrouped = <String, List<String>>{};
    for (String key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }
    
    return sortedGrouped;
  }

  String _categorizeByBodyPart(String measurement) {
    final lowerMeasurement = measurement.toLowerCase();
    
    if (lowerMeasurement.contains('chest') || lowerMeasurement.contains('bust')) {
      return 'Chest';
    } else if (lowerMeasurement.contains('waist')) {
      return 'Waist';
    } else if (lowerMeasurement.contains('hip')) {
      return 'Hip';
    } else if (lowerMeasurement.contains('shoulder')) {
      return 'Shoulder';
    } else if (lowerMeasurement.contains('arm') || 
               lowerMeasurement.contains('sleeve') ||
               lowerMeasurement.contains('bicep') ||
               lowerMeasurement.contains('wrist')) {
      return 'Arm';
    } else if (lowerMeasurement.contains('neck')) {
      return 'Neck';
    } else if (lowerMeasurement.contains('length') || 
               lowerMeasurement.contains('height')) {
      return 'Length';
    } else if (lowerMeasurement.contains('thigh') || 
               lowerMeasurement.contains('leg') ||
               lowerMeasurement.contains('inseam') ||
               lowerMeasurement.contains('outseam')) {
      return 'Leg';
    } else {
      return 'Other';
    }
  }

  void _focusNextField(String currentCategory) {
    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(widget.dressType);
    final currentIndex = requiredMeasurements.indexOf(currentCategory);
    
    if (currentIndex != -1 && currentIndex < requiredMeasurements.length - 1) {
      final nextCategory = requiredMeasurements[currentIndex + 1];
      _focusNodes[nextCategory]?.requestFocus();
    } else {
      // Last field, dismiss keyboard
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes
    _controllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((focusNode) => focusNode.dispose());
    super.dispose();
  }
}