import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/utils/unit_converter.dart';
import 'package:tailer_app/core/constants/app_colors.dart';

/// Widget for selecting measurement units (inches or centimeters)
class UnitSelector extends StatelessWidget {
  final String currentUnit;
  final Function(String) onUnitChanged;
  final bool showLabel;
  final bool compact;

  const UnitSelector({
    super.key,
    required this.currentUnit,
    required this.onUnitChanged,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactSelector();
    }
    return _buildFullSelector();
  }

  Widget _buildCompactSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentUnit,
          isDense: true,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
          items: UnitConverter.getAllUnits().map((String unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: Text(UnitConverter.getUnitSymbol(unit)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onUnitChanged(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildFullSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Measurement Unit',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentUnit,
              isExpanded: true,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: const Color(AppConstants.primaryTeal),
                size: 20,
              ),
              items: UnitConverter.getAllUnits().map((String unit) {
                return DropdownMenuItem<String>(
                  value: unit,
                  child: Row(
                    children: [
                      Icon(
                        Icons.straighten_rounded,
                        size: 18,
                        color: unit == currentUnit 
                            ? const Color(AppConstants.primaryTeal)
                            : Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(UnitConverter.getUnitDisplayName(unit)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onUnitChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Toggle switch widget for quickly switching between inches and centimeters
class UnitToggleSwitch extends StatelessWidget {
  final String currentUnit;
  final Function(String) onUnitChanged;
  final bool showLabels;

  const UnitToggleSwitch({
    super.key,
    required this.currentUnit,
    required this.onUnitChanged,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('inches', 'in'),
          const SizedBox(width: 4),
          _buildToggleButton('cm', 'cm'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String unit, String symbol) {
    final isSelected = currentUnit == unit;
    
    return GestureDetector(
      onTap: () => onUnitChanged(unit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(AppConstants.primaryTeal) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          showLabels ? UnitConverter.getUnitDisplayName(unit) : symbol,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

/// Floating action button for unit switching
class UnitSwitchFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final String currentUnit;

  const UnitSwitchFAB({
    super.key,
    required this.onPressed,
    required this.currentUnit,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: onPressed,
      backgroundColor: const Color(AppConstants.primaryTeal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            color: Colors.white,
            size: 16,
          ),
          Text(
            UnitConverter.getUnitSymbol(currentUnit),
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}