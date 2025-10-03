/// Unit conversion utility for measurements
/// Provides conversion between inches and centimeters

class UnitConverter {
  // Conversion constants
  static const double inchesToCm = 2.54;
  static const double cmToInches = 1 / inchesToCm;

  /// Convert from inches to centimeters
  static double inchesToCentimeters(double inches) {
    return inches * inchesToCm;
  }

  /// Convert from centimeters to inches
  static double centimetersToInches(double cm) {
    return cm * cmToInches;
  }

  /// Convert value from one unit to another
  static double convertValue(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;
    
    if (fromUnit == 'inches' && toUnit == 'cm') {
      return inchesToCentimeters(value);
    } else if (fromUnit == 'cm' && toUnit == 'inches') {
      return centimetersToInches(value);
    }
    
    return value; // Return original value if units are unknown
  }

  /// Format measurement value with appropriate precision
  static String formatMeasurement(double value, String unit) {
    if (unit == 'cm') {
      // For centimeters, show 1 decimal place
      return value.toStringAsFixed(1);
    } else {
      // For inches, show 2 decimal places
      return value.toStringAsFixed(2);
    }
  }

  /// Get all available measurement units
  static List<String> getAllUnits() {
    return ['inches', 'cm'];
  }

  /// Get unit display name
  static String getUnitDisplayName(String unit) {
    switch (unit) {
      case 'inches':
        return 'Inches (in)';
      case 'cm':
        return 'Centimeters (cm)';
      default:
        return unit;
    }
  }

  /// Get unit symbol
  static String getUnitSymbol(String unit) {
    switch (unit) {
      case 'inches':
        return 'in';
      case 'cm':
        return 'cm';
      default:
        return unit;
    }
  }

  /// Validate if a unit is supported
  static bool isValidUnit(String unit) {
    return getAllUnits().contains(unit);
  }
}