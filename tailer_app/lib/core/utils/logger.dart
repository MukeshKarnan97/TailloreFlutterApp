import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Logger - A comprehensive debugging and logging utility
/// 
/// This utility provides structured logging with different levels,
/// method tracing, performance monitoring, and exception handling.
/// 
/// Features:
/// - Multiple log levels (DEBUG, INFO, WARNING, ERROR)
/// - Method entry/exit tracing with performance metrics
/// - Stack trace capture for errors
/// - Conditional logging (only in debug mode)
/// - Color-coded console output
/// - Exception tracking with context
/// - Performance measurement utilities
class Logger {
  // Singleton pattern for consistent logging
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  // Log levels
  static const int _debugLevel = 0;
  static const int _infoLevel = 1;
  static const int _warningLevel = 2;
  static const int _errorLevel = 3;

  // Current log level (can be adjusted for production)
  static int _currentLogLevel = _debugLevel;

  // ANSI color codes for console output
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _white = '\x1B[37m';
  static const String _bold = '\x1B[1m';

  // Performance tracking
  final Map<String, DateTime> _methodStartTimes = {};
  final Map<String, int> _methodCallCounts = {};

  /// Set the minimum log level
  static void setLogLevel(int level) {
    _currentLogLevel = level;
  }

  /// Get current timestamp in readable format
  String get _timestamp {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
           '${now.minute.toString().padLeft(2, '0')}:'
           '${now.second.toString().padLeft(2, '0')}.'
           '${now.millisecond.toString().padLeft(3, '0')}';
  }

  /// Format log message with timestamp and level
  String _formatMessage(String level, String tag, String message, {String color = _white}) {
    return '$color$_bold[$_timestamp] [$level] [$tag] $message$_reset';
  }

  /// Internal logging method
  void _log(int level, String levelName, String tag, String message, {String color = _white, Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode || level < _currentLogLevel) return;

    final formattedMessage = _formatMessage(levelName, tag, message, color: color);
    
    // Print to console
    print(formattedMessage);
    
    // Print error details if provided
    if (error != null) {
      print('$color${_bold}Error: $error$_reset');
    }
    
    // Print stack trace if provided
    if (stackTrace != null) {
      print('$color${_bold}Stack Trace:$_reset');
      print('$color$stackTrace$_reset');
    }
    
    // Also log to Flutter's logging system
    developer.log(
      message,
      name: tag,
      level: level * 300, // Convert to Flutter log levels
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ==================== LOG LEVEL METHODS ====================

  /// Debug level logging - for detailed debugging information
  static void debug(String tag, String message) {
    _instance._log(_debugLevel, 'DEBUG', tag, message, color: _cyan);
  }

  /// Info level logging - for general information
  static void info(String tag, String message) {
    _instance._log(_infoLevel, 'INFO', tag, message, color: _green);
  }

  /// Warning level logging - for potential issues
  static void warning(String tag, String message) {
    _instance._log(_warningLevel, 'WARN', tag, message, color: _yellow);
  }

  /// Error level logging - for errors and exceptions
  static void error(String tag, String message, {Object? error, StackTrace? stackTrace}) {
    _instance._log(_errorLevel, 'ERROR', tag, message, color: _red, error: error, stackTrace: stackTrace);
  }

  // ==================== METHOD TRACING ====================

  /// Start method tracing - call at the beginning of a method
  static void startTrace(String className, String methodName, {Map<String, dynamic>? parameters}) {
    final tag = '$className.$methodName';
    final key = '$className-$methodName-${DateTime.now().millisecondsSinceEpoch}';
    
    _instance._methodStartTimes[key] = DateTime.now();
    _instance._methodCallCounts[tag] = (_instance._methodCallCounts[tag] ?? 0) + 1;
    
    String message = '🚀 ENTER: $methodName()';
    if (parameters != null && parameters.isNotEmpty) {
      message += ' | Parameters: $parameters';
    }
    message += ' | Call #${_instance._methodCallCounts[tag]}';
    
    _instance._log(_debugLevel, 'TRACE', className, message, color: _magenta);
  }

  /// End method tracing - call at the end of a method
  static void endTrace(String className, String methodName, {dynamic result, String? additionalInfo}) {
    // Find the most recent start time for this method
    final startKey = _instance._methodStartTimes.keys
        .where((key) => key.startsWith('$className-$methodName-'))
        .lastOrNull;
    
    Duration? duration;
    if (startKey != null) {
      final startTime = _instance._methodStartTimes[startKey];
      if (startTime != null) {
        duration = DateTime.now().difference(startTime);
        _instance._methodStartTimes.remove(startKey);
      }
    }
    
    String message = '🏁 EXIT: $methodName()';
    if (duration != null) {
      message += ' | Duration: ${duration.inMilliseconds}ms';
    }
    if (result != null) {
      message += ' | Result: ${result.toString().length > 100 ? '${result.toString().substring(0, 100)}...' : result}';
    }
    if (additionalInfo != null) {
      message += ' | Info: $additionalInfo';
    }
    
    _instance._log(_debugLevel, 'TRACE', className, message, color: _magenta);
  }

  /// Trace a method execution with automatic timing
  static T traceMethod<T>(
    String className,
    String methodName,
    T Function() method, {
    Map<String, dynamic>? parameters,
  }) {
    startTrace(className, methodName, parameters: parameters);
    try {
      final result = method();
      endTrace(className, methodName, result: result);
      return result;
    } catch (e, stackTrace) {
      error(className, 'Exception in $methodName: $e', error: e, stackTrace: stackTrace);
      endTrace(className, methodName, additionalInfo: 'FAILED with exception');
      rethrow;
    }
  }

  /// Trace an async method execution with automatic timing
  static Future<T> traceAsyncMethod<T>(
    String className,
    String methodName,
    Future<T> Function() method, {
    Map<String, dynamic>? parameters,
  }) async {
    startTrace(className, methodName, parameters: parameters);
    try {
      final result = await method();
      endTrace(className, methodName, result: result);
      return result;
    } catch (e, stackTrace) {
      error(className, 'Exception in $methodName: $e', error: e, stackTrace: stackTrace);
      endTrace(className, methodName, additionalInfo: 'FAILED with exception');
      rethrow;
    }
  }

  // ==================== EXCEPTION HANDLING ====================

  /// Log exception with context
  static void exception(String className, String methodName, Object exception, StackTrace stackTrace, {String? context}) {
    String message = '💥 EXCEPTION in $methodName';
    if (context != null) {
      message += ' | Context: $context';
    }
    
    error(className, message, error: exception, stackTrace: stackTrace);
  }

  /// Safely execute a function and log any exceptions
  static T? safeExecute<T>(
    String className,
    String methodName,
    T Function() function, {
    String? context,
    T? defaultValue,
  }) {
    try {
      return function();
    } catch (e, stackTrace) {
      exception(className, methodName, e, stackTrace, context: context);
      return defaultValue;
    }
  }

  /// Safely execute an async function and log any exceptions
  static Future<T?> safeExecuteAsync<T>(
    String className,
    String methodName,
    Future<T> Function() function, {
    String? context,
    T? defaultValue,
  }) async {
    try {
      return await function();
    } catch (e, stackTrace) {
      exception(className, methodName, e, stackTrace, context: context);
      return defaultValue;
    }
  }

  // ==================== PERFORMANCE MONITORING ====================

  /// Start performance measurement
  static void startPerformanceTrace(String tag) {
    _instance._methodStartTimes[tag] = DateTime.now();
    debug('PERFORMANCE', '⏱️  Started measuring: $tag');
  }

  /// End performance measurement and log duration
  static void endPerformanceTrace(String tag, {String? additionalInfo}) {
    final startTime = _instance._methodStartTimes[tag];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      String message = '⏱️  Performance: $tag took ${duration.inMilliseconds}ms';
      if (additionalInfo != null) {
        message += ' | $additionalInfo';
      }
      
      // Color code based on duration
      String color = _green; // Fast
      if (duration.inMilliseconds > 100) color = _yellow; // Medium
      if (duration.inMilliseconds > 500) color = _red; // Slow
      
      _instance._log(_infoLevel, 'PERF', 'PERFORMANCE', message, color: color);
      _instance._methodStartTimes.remove(tag);
    } else {
      warning('PERFORMANCE', 'No start time found for performance trace: $tag');
    }
  }

  /// Measure performance of a function
  static T measurePerformance<T>(String tag, T Function() function) {
    startPerformanceTrace(tag);
    try {
      final result = function();
      endPerformanceTrace(tag);
      return result;
    } catch (e) {
      endPerformanceTrace(tag, additionalInfo: 'FAILED');
      rethrow;
    }
  }

  /// Measure performance of an async function
  static Future<T> measurePerformanceAsync<T>(String tag, Future<T> Function() function) async {
    startPerformanceTrace(tag);
    try {
      final result = await function();
      endPerformanceTrace(tag);
      return result;
    } catch (e) {
      endPerformanceTrace(tag, additionalInfo: 'FAILED');
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Log object properties for debugging
  static void logObject(String tag, String objectName, Object? object) {
    if (object == null) {
      debug(tag, '$objectName: null');
      return;
    }

    debug(tag, '$objectName: ${object.runtimeType}');
    debug(tag, '$objectName.toString(): $object');
  }

  /// Log list/collection contents
  static void logCollection(String tag, String collectionName, Iterable? collection) {
    if (collection == null) {
      debug(tag, '$collectionName: null');
      return;
    }

    debug(tag, '$collectionName: ${collection.runtimeType} (length: ${collection.length})');
    
    if (collection.isEmpty) {
      debug(tag, '$collectionName: EMPTY');
      return;
    }

    for (int i = 0; i < collection.length && i < 10; i++) { // Limit to first 10 items
      debug(tag, '$collectionName[$i]: ${collection.elementAt(i)}');
    }
    
    if (collection.length > 10) {
      debug(tag, '$collectionName: ... and ${collection.length - 10} more items');
    }
  }

  /// Log network request/response
  static void logNetworkRequest(String method, String url, {Map<String, String>? headers, Object? body}) {
    info('NETWORK', '🌐 $method $url');
    if (headers != null && headers.isNotEmpty) {
      debug('NETWORK', 'Headers: $headers');
    }
    if (body != null) {
      debug('NETWORK', 'Body: $body');
    }
  }

  static void logNetworkResponse(String url, int statusCode, {Object? body, Duration? duration}) {
    String emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
    String message = '$emoji Response: $statusCode for $url';
    if (duration != null) {
      message += ' (${duration.inMilliseconds}ms)';
    }
    
    if (statusCode >= 200 && statusCode < 300) {
      info('NETWORK', message);
    } else {
      warning('NETWORK', message);
    }
    
    if (body != null) {
      debug('NETWORK', 'Response Body: $body');
    }
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'methodCallCounts': Map.from(_instance._methodCallCounts),
      'activeTraces': _instance._methodStartTimes.length,
      'logLevel': _currentLogLevel,
    };
  }

  /// Clear performance statistics
  static void clearStats() {
    _instance._methodCallCounts.clear();
    _instance._methodStartTimes.clear();
    info('LOGGER', 'Performance statistics cleared');
  }

  /// Print separator line for better log readability
  static void separator({String? title}) {
    String line = '=' * 60;
    if (title != null) {
      int padding = (60 - title.length - 2) ~/ 2;
      line = '=' * padding + ' $title ' + '=' * padding;
    }
    _instance._log(_infoLevel, 'SEP', 'LOGGER', line, color: _blue);
  }

  /// Print header for log sections
  static void header(String title) {
    separator();
    info('LOGGER', '📋 $title');
    separator();
  }
}

/// Extension for easier logging on any class
extension LoggerExtension on Object {
  /// Get class name for logging
  String get _className => runtimeType.toString();

  /// Quick debug log for this object
  void logDebug(String methodName, String message) {
    Logger.debug(_className, '[$methodName] $message');
  }

  /// Quick info log for this object
  void logInfo(String methodName, String message) {
    Logger.info(_className, '[$methodName] $message');
  }

  /// Quick warning log for this object
  void logWarning(String methodName, String message) {
    Logger.warning(_className, '[$methodName] $message');
  }

  /// Quick error log for this object
  void logError(String methodName, String message, {Object? error, StackTrace? stackTrace}) {
    Logger.error(_className, '[$methodName] $message', error: error, stackTrace: stackTrace);
  }

  /// Start tracing for this object's method
  void startTrace(String methodName, {Map<String, dynamic>? parameters}) {
    Logger.startTrace(_className, methodName, parameters: parameters);
  }

  /// End tracing for this object's method
  void endTrace(String methodName, {dynamic result, String? additionalInfo}) {
    Logger.endTrace(_className, methodName, result: result, additionalInfo: additionalInfo);
  }
}