import 'package:flutter/material.dart';
import '../../../core/constants/measurement_constants.dart';

class DressTypeSelector extends StatelessWidget {
  final String? selectedDressType;
  final Function(String?) onDressTypeSelected;
  final bool enabled;

  const DressTypeSelector({
    super.key,
    required this.selectedDressType,
    required this.onDressTypeSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dress Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: selectedDressType,
              decoration: const InputDecoration(
                hintText: 'Select dress type',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              isExpanded: true,
              items: MeasurementConstants.getAllDressTypes().map((String dressType) {
                return DropdownMenuItem<String>(
                  value: dressType,
                  child: Row(
                    children: [
                      Icon(
                        _getDressTypeIcon(dressType),
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDressTypeName(dressType),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: enabled ? onDressTypeSelected : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a dress type';
                }
                return null;
              },
            ),
            
            if (selectedDressType != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required Measurements:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: MeasurementConstants.getMeasurementsForDressType(selectedDressType!)
                          .map((measurement) => Chip(
                                label: Text(
                                  _formatMeasurementName(measurement),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getDressTypeIcon(String dressType) {
    switch (dressType.toLowerCase()) {
      case 'shirt':
        return Icons.checkroom;
      case 'pant':
        return Icons.dry_cleaning;
      case 'suit':
        return Icons.business_center;
      case 'kurta':
        return Icons.accessibility_new;
      case 'sherwani':
        return Icons.account_balance;
      case 'dress':
        return Icons.woman;
      case 'skirt':
        return Icons.woman_2;
      case 'blouse':
        return Icons.checkroom_outlined;
      case 'lehenga':
        return Icons.festival;
      case 'saree':
        return Icons.emoji_people;
      case 'gown':
        return Icons.night_shelter;
      default:
        return Icons.checkroom;
    }
  }

  String _formatDressTypeName(String dressType) {
    return dressType.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatMeasurementName(String measurement) {
    return measurement.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}