import '../../../core/utils/logger.dart';
import '../models/tailor_model.dart';

/// Example Service demonstrating Logger usage
/// 
/// This service shows how to integrate the Logger utility
/// into your service classes for comprehensive debugging
class ExampleService {
  static const String _className = 'ExampleService';

  /// Example method showing basic logging
  Future<String> processData(String input) async {
    return Logger.traceAsyncMethod(_className, 'processData', () async {
      Logger.info(_className, 'Starting data processing');
      
      try {
        // Simulate some processing
        Logger.debug(_className, 'Processing input: $input');
        
        if (input.isEmpty) {
          Logger.warning(_className, 'Empty input received');
          return 'No data to process';
        }
        
        // Simulate async operation
        await Future.delayed(Duration(milliseconds: 100));
        
        final result = 'Processed: $input';
        Logger.info(_className, 'Data processing completed successfully');
        return result;
        
      } catch (e, stackTrace) {
        Logger.exception(_className, 'processData', e, stackTrace, 
          context: 'Failed to process input: $input');
        rethrow;
      }
    }, parameters: {'input': input});
  }

  /// Example method showing performance measurement
  Future<List<Tailor>> fetchTailors() async {
    return Logger.measurePerformanceAsync('fetchTailors', () async {
      Logger.info(_className, 'Fetching tailors from database');
      
      // Simulate database fetch
      await Future.delayed(Duration(milliseconds: 200));
      
      final tailors = <Tailor>[]; // Mock data
      Logger.info(_className, 'Fetched ${tailors.length} tailors');
      
      return tailors;
    });
  }

  /// Example method showing safe execution
  String? safeOperation(String? data) {
    return Logger.safeExecute(_className, 'safeOperation', () {
      if (data == null) throw ArgumentError('Data cannot be null');
      return data.toUpperCase();
    }, context: 'Converting data to uppercase', defaultValue: null);
  }

  /// Example method using extension methods
  void demonstrateExtensions() {
    // Using the LoggerExtension
    logInfo('demonstrateExtensions', 'Starting demonstration');
    
    startTrace('demonstrateExtensions');
    
    // Some processing
    logDebug('demonstrateExtensions', 'Processing step 1');
    logDebug('demonstrateExtensions', 'Processing step 2');
    
    endTrace('demonstrateExtensions', result: 'Demo completed');
  }
}