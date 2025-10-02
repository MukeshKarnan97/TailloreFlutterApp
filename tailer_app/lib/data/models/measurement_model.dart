import 'dart:convert';
import 'dart:math';

/// Measurement model for storing customer measurements
class Measurement {
  final String id;
  final String uniqueId;
  final String customerId;
  final String dressType;
  final Map<String, double> measurements;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const Measurement({
    required this.id,
    required this.uniqueId,
    required this.customerId,
    required this.dressType,
    required this.measurements,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  /// Generate a stylish unique ID for measurements
  static String _generateStylishId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String result = 'MES'; // Measurement prefix
    
    for (int i = 0; i < 7; i++) {
      result += chars[random.nextInt(chars.length)];
    }
    
    return result;
  }

  /// Create a new measurement instance
  factory Measurement.create({
    required String customerId,
    required String dressType,
    required Map<String, double> measurements,
    String? notes,
  }) {
    final now = DateTime.now();
    final uniqueId = _generateStylishId();
    
    return Measurement(
      id: uniqueId, // Using uniqueId as id for simplicity
      uniqueId: uniqueId,
      customerId: customerId,
      dressType: dressType,
      measurements: Map<String, double>.from(measurements),
      notes: notes,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }

  /// Create from database map
  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id']?.toString() ?? '',
      uniqueId: map['unique_id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      dressType: map['dress_type']?.toString() ?? '',
      measurements: _parseMeasurements(map['measurements']),
      notes: map['notes']?.toString(),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      isDeleted: (map['is_deleted'] ?? 0) == 1,
    );
  }

  /// Parse measurements from JSON string or Map
  static Map<String, double> _parseMeasurements(dynamic measurementsData) {
    if (measurementsData == null) return {};
    
    Map<String, dynamic> measurementsMap;
    
    if (measurementsData is String) {
      try {
        measurementsMap = jsonDecode(measurementsData);
      } catch (e) {
        return {};
      }
    } else if (measurementsData is Map<String, dynamic>) {
      measurementsMap = measurementsData;
    } else {
      return {};
    }

    return measurementsMap.map((key, value) {
      double doubleValue = 0.0;
      if (value is num) {
        doubleValue = value.toDouble();
      } else if (value is String) {
        doubleValue = double.tryParse(value) ?? 0.0;
      }
      return MapEntry(key, doubleValue);
    });
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unique_id': uniqueId,
      'customer_id': customerId,
      'dress_type': dressType,
      'measurements': jsonEncode(measurements),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  /// Convert to JSON string
  String toJson() => jsonEncode(toMap());

  /// Create from JSON string
  factory Measurement.fromJson(String source) => 
      Measurement.fromMap(jsonDecode(source));

  /// Copy with new values
  Measurement copyWith({
    String? id,
    String? uniqueId,
    String? customerId,
    String? dressType,
    Map<String, double>? measurements,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Measurement(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      customerId: customerId ?? this.customerId,
      dressType: dressType ?? this.dressType,
      measurements: measurements ?? Map<String, double>.from(this.measurements),
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Get a specific measurement value
  double? getMeasurement(String measurementKey) {
    return measurements[measurementKey];
  }

  /// Check if measurement exists
  bool hasMeasurement(String measurementKey) {
    return measurements.containsKey(measurementKey) && 
           measurements[measurementKey] != null &&
           measurements[measurementKey]! > 0;
  }

  /// Get formatted measurement value with unit
  String getFormattedMeasurement(String measurementKey, {String unit = 'inches'}) {
    final value = getMeasurement(measurementKey);
    if (value == null || value <= 0) return 'Not measured';
    return '${value.toStringAsFixed(1)} $unit';
  }

  /// Get completion percentage (how many measurements are filled)
  double getCompletionPercentage(List<String> requiredMeasurements) {
    if (requiredMeasurements.isEmpty) return 0.0;
    
    int filledCount = 0;
    for (String measurementKey in requiredMeasurements) {
      if (hasMeasurement(measurementKey)) {
        filledCount++;
      }
    }
    
    return (filledCount / requiredMeasurements.length) * 100;
  }

  /// Get missing measurements
  List<String> getMissingMeasurements(List<String> requiredMeasurements) {
    return requiredMeasurements.where((key) => !hasMeasurement(key)).toList();
  }

  /// Get available measurements
  List<String> getAvailableMeasurements() {
    return measurements.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
  }

  @override
  String toString() {
    return 'Measurement(id: $id, uniqueId: $uniqueId, customerId: $customerId, '
           'dressType: $dressType, measurements: $measurements, notes: $notes, '
           'createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Measurement &&
           other.uniqueId == uniqueId &&
           other.customerId == customerId &&
           other.dressType == dressType;
  }

  @override
  int get hashCode {
    return uniqueId.hashCode ^ customerId.hashCode ^ dressType.hashCode;
  }
}
