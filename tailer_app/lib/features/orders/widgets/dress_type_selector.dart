import 'package:flutter/material.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
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
      color: Colors.white,
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
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),

            // Custom dropdown with icon in input box
            InkWell(
              onTap: enabled ? () => _showDropdown(context) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.checkroom, color: Colors.black),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedDressType != null
                            ? _formatDressTypeName(selectedDressType!)
                            : 'Select dress type',
                        style: TextStyle(
                          fontSize: 16,
                          color: selectedDressType != null
                              ? AppColors.textPrimary
                              : Colors.black26,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.black),
                  ],
                ),
              ),
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
                      children: MeasurementConstants
                          .getMeasurementsForDressType(selectedDressType!)
                          .map((measurement) => Chip(
                                label: Text(
                                  _formatMeasurementName(measurement),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2),
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

  void _showDropdown(BuildContext context) async {
    // Show modal bottom sheet with all dress types
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
      builder: (context) {
        return ListView(
          children: MeasurementConstants.getAllDressTypes()
              .map((type) => ListTile(
                    leading: Icon(_getDressTypeIcon(type), color: Colors.black),
                    title: Text(
                  _formatDressTypeName(type),
                  style: const TextStyle(
                    color: Colors.black, // 👈 text is black
                    fontSize: 16,
                  ),
                ),
                    onTap: () => Navigator.of(context).pop(type),
                  ))
              .toList(),
        );
      },
    );

    if (selected != null) {
      onDressTypeSelected(selected);
    }
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
    return dressType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatMeasurementName(String measurement) {
    return measurement
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
