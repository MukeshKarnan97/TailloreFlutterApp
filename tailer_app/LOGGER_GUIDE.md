# Logger Usage Guide

## 🚀 Comprehensive Logger Utility for Flutter Debugging

The Logger utility provides structured logging with tracing, performance monitoring, and exception handling.

## 📋 Features

### ✨ Log Levels
- **DEBUG**: Detailed debugging information
- **INFO**: General information
- **WARNING**: Potential issues
- **ERROR**: Errors and exceptions

### 🔍 Method Tracing
- Start/End tracing with performance metrics
- Automatic timing measurement
- Call count tracking
- Parameter logging

### 📊 Performance Monitoring
- Performance measurement utilities
- Duration tracking with color coding
- Statistical reporting

### 🛡️ Exception Handling
- Safe execution wrappers
- Automatic exception logging
- Stack trace capture

## 🎯 Usage Examples

### Basic Logging
```dart
Logger.debug('MyClass', 'Debug message');
Logger.info('MyClass', 'Info message');
Logger.warning('MyClass', 'Warning message');
Logger.error('MyClass', 'Error message', error: exception, stackTrace: stackTrace);
```

### Method Tracing
```dart
// Manual tracing
Logger.startTrace('MyClass', 'methodName', parameters: {'param1': value});
// ... method code ...
Logger.endTrace('MyClass', 'methodName', result: result);

// Automatic tracing
Future<String> myMethod() async {
  return Logger.traceAsyncMethod('MyClass', 'myMethod', () async {
    // Your method code here
    return 'result';
  }, parameters: {'param1': 'value'});
}
```

### Performance Measurement
```dart
// Manual measurement
Logger.startPerformanceTrace('database_query');
// ... expensive operation ...
Logger.endPerformanceTrace('database_query');

// Automatic measurement
final result = await Logger.measurePerformanceAsync('api_call', () async {
  return await apiService.fetchData();
});
```

### Safe Execution
```dart
// Safe sync execution
final result = Logger.safeExecute('MyClass', 'riskyOperation', () {
  return riskyOperation();
}, context: 'Processing user data', defaultValue: null);

// Safe async execution
final result = await Logger.safeExecuteAsync('MyClass', 'riskyAsyncOperation', () async {
  return await riskyAsyncOperation();
}, context: 'Fetching remote data', defaultValue: []);
```

### Using Extension Methods
```dart
class MyService {
  void processData() {
    // Quick logging with extensions
    logInfo('processData', 'Starting data processing');
    
    startTrace('processData', parameters: {'userId': userId});
    
    try {
      // Processing logic
      logDebug('processData', 'Step 1 completed');
      
    } catch (e, stackTrace) {
      logError('processData', 'Processing failed', error: e, stackTrace: stackTrace);
    } finally {
      endTrace('processData', result: 'completed');
    }
  }
}
```

### Network Logging
```dart
// Log network request
Logger.logNetworkRequest('POST', 'https://api.example.com/users', 
  headers: headers, body: requestBody);

// Log network response
Logger.logNetworkResponse('https://api.example.com/users', 200, 
  body: responseBody, duration: Duration(milliseconds: 150));
```

### Object and Collection Logging
```dart
// Log object details
Logger.logObject('MyClass', 'userObject', user);

// Log collection contents
Logger.logCollection('MyClass', 'usersList', users);
```

### Utility Methods
```dart
// Add separators for better readability
Logger.separator(title: 'Authentication Process');

// Add headers for log sections
Logger.header('Database Operations');

// Get performance statistics
final stats = Logger.getPerformanceStats();
Logger.info('Stats', 'Performance stats: $stats');

// Clear statistics
Logger.clearStats();
```

## 🎨 Console Output Features

### Color-Coded Logs
- 🔵 DEBUG: Cyan
- 🟢 INFO: Green  
- 🟡 WARNING: Yellow
- 🔴 ERROR: Red
- 🟣 TRACE: Magenta
- 🔵 PERFORMANCE: Blue

### Performance Color Coding
- 🟢 Fast: < 100ms
- 🟡 Medium: 100-500ms
- 🔴 Slow: > 500ms

### Emojis for Better Visibility
- 🚀 Method entry
- 🏁 Method exit
- 💥 Exceptions
- ⏱️ Performance measurements
- 🌐 Network operations
- ✅ Success responses
- ❌ Error responses

## 🔧 Configuration

### Set Log Level
```dart
// Only show INFO and above (hide DEBUG)
Logger.setLogLevel(1);

// Show all logs (default)
Logger.setLogLevel(0);
```

### Production Configuration
```dart
void main() {
  // In production, set higher log level
  if (kReleaseMode) {
    Logger.setLogLevel(2); // Only WARNING and ERROR
  }
  
  runApp(MyApp());
}
```

## 🏗️ Integration in Services

### Database Service Example
```dart
class DatabaseService {
  Future<int> insertUser(User user) async {
    return Logger.traceAsyncMethod('DatabaseService', 'insertUser', () async {
      Logger.info('DatabaseService', 'Inserting user: ${user.name}');
      
      try {
        final result = await database.insert('users', user.toMap());
        Logger.info('DatabaseService', 'User inserted successfully with ID: $result');
        return result;
      } catch (e, stackTrace) {
        Logger.error('DatabaseService', 'Failed to insert user', 
          error: e, stackTrace: stackTrace);
        rethrow;
      }
    }, parameters: {'userId': user.id, 'userName': user.name});
  }
}
```

### API Service Example
```dart
class ApiService {
  Future<List<User>> fetchUsers() async {
    return Logger.measurePerformanceAsync('api_fetch_users', () async {
      Logger.logNetworkRequest('GET', '$baseUrl/users');
      
      final stopwatch = Stopwatch()..start();
      
      try {
        final response = await http.get(Uri.parse('$baseUrl/users'));
        stopwatch.stop();
        
        Logger.logNetworkResponse('$baseUrl/users', response.statusCode,
          duration: stopwatch.elapsed);
        
        if (response.statusCode == 200) {
          final users = (jsonDecode(response.body) as List)
              .map((json) => User.fromJson(json))
              .toList();
          
          Logger.info('ApiService', 'Fetched ${users.length} users successfully');
          return users;
        } else {
          throw ApiException('Failed to fetch users: ${response.statusCode}');
        }
      } catch (e, stackTrace) {
        Logger.error('ApiService', 'API call failed', error: e, stackTrace: stackTrace);
        rethrow;
      }
    });
  }
}
```

## 💡 Best Practices

1. **Use appropriate log levels**: DEBUG for detailed info, INFO for general flow, WARNING for potential issues, ERROR for exceptions

2. **Include context**: Always provide meaningful messages with relevant data

3. **Use tracing for important methods**: Especially for async operations and database calls

4. **Measure performance of critical operations**: API calls, database queries, heavy computations

5. **Use safe execution for risky operations**: Network calls, file operations, parsing

6. **Log method parameters**: Include relevant parameters in trace methods

7. **Don't log sensitive data**: Avoid logging passwords, tokens, personal information

8. **Use separators and headers**: Group related log entries for better readability

9. **Clear statistics periodically**: Prevent memory buildup in long-running apps

10. **Configure log levels for different environments**: Verbose in development, minimal in production

## 🚨 Important Notes

- Logger only outputs in DEBUG mode (`kDebugMode`)
- All logs are automatically sent to Flutter's logging system
- Performance statistics are kept in memory - clear them periodically
- Stack traces are captured automatically for exceptions
- Method call counts help identify performance bottlenecks

## 📱 Example Log Output

```
[14:23:15.123] [TRACE] [DatabaseService] 🚀 ENTER: insertUser() | Parameters: {userId: 123, userName: John} | Call #1
[14:23:15.124] [INFO] [DatabaseService] Inserting user: John
[14:23:15.156] [INFO] [DatabaseService] User inserted successfully with ID: 456
[14:23:15.157] [TRACE] [DatabaseService] 🏁 EXIT: insertUser() | Duration: 34ms | Result: 456

[14:23:16.200] [PERF] [PERFORMANCE] ⏱️ Performance: api_fetch_users took 245ms

[14:23:16.201] [NETWORK] [NETWORK] 🌐 GET https://api.example.com/users
[14:23:16.445] [NETWORK] [NETWORK] ✅ Response: 200 for https://api.example.com/users (245ms)
```

This logger system will help you debug effectively and monitor your app's performance! 🎯