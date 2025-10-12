import 'package:flutter/foundation.dart';
// import 'package:tailer_app/data/services/local_db_service.dart'; // TODO: Re-enable after preferences table migration
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/core/utils/unit_converter.dart';
import 'package:tailer_app/core/utils/logger.dart';

/// Provider for managing user measurement unit preferences
class MeasurementUnitProvider extends ChangeNotifier {
  static final MeasurementUnitProvider _instance = MeasurementUnitProvider._internal();
  factory MeasurementUnitProvider() => _instance;
  MeasurementUnitProvider._internal();

  // final LocalDatabaseService _dbService = LocalDatabaseService(); // TODO: Re-enable after preferences table migration
  final AuthService _authService = AuthService();
  
  String _currentUnit = 'inches';
  bool _isLoading = false;

  /// Current measurement unit
  String get currentUnit => _currentUnit;
  
  /// Is the provider currently loading/updating
  bool get isLoading => _isLoading;

  /// Unit symbol for display
  String get unitSymbol => UnitConverter.getUnitSymbol(_currentUnit);

  /// Unit display name
  String get unitDisplayName => UnitConverter.getUnitDisplayName(_currentUnit);

  /// Initialize the provider by loading user preferences
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _authService.currentUser;
      if (user != null) {
        // TODO: Update user_preferences table to use tailor_id (String) instead of user_id (int)
        // For now, use default inches - preferences will be re-enabled after table migration
        _currentUnit = 'inches';
        
        Logger.info('MeasurementUnitProvider', 'Initialized with default unit: $_currentUnit');
      }
    } catch (e, stackTrace) {
      Logger.error('MeasurementUnitProvider', 'Failed to initialize', error: e, stackTrace: stackTrace);
      _currentUnit = 'inches'; // Fallback to default
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update the measurement unit preference
  Future<bool> updateUnit(String newUnit) async {
    if (!UnitConverter.isValidUnit(newUnit)) {
      Logger.warning('MeasurementUnitProvider', 'Invalid unit: $newUnit');
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final user = _authService.currentUser;
      if (user != null) {
        // TODO: Update user_preferences table to use tailor_id (String) instead of user_id (int)
        // For now, just update in memory - preferences will be re-enabled after table migration
        _currentUnit = newUnit;
        
        Logger.info('MeasurementUnitProvider', 'Updated unit to: $newUnit (in-memory only)');
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e, stackTrace) {
      Logger.error('MeasurementUnitProvider', 'Failed to update unit', error: e, stackTrace: stackTrace);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Convert a measurement value to the current unit
  double convertToCurrentUnit(double value, String fromUnit) {
    return UnitConverter.convertValue(value, fromUnit, _currentUnit);
  }

  /// Convert a measurement value from the current unit
  double convertFromCurrentUnit(double value, String toUnit) {
    return UnitConverter.convertValue(value, _currentUnit, toUnit);
  }

  /// Format a measurement value with the current unit
  String formatMeasurement(double value) {
    return UnitConverter.formatMeasurement(value, _currentUnit);
  }

  /// Get all available units
  List<String> getAllUnits() {
    return UnitConverter.getAllUnits();
  }

  /// Toggle between inches and centimeters
  Future<bool> toggleUnit() async {
    final newUnit = _currentUnit == 'inches' ? 'cm' : 'inches';
    return await updateUnit(newUnit);
  }
}