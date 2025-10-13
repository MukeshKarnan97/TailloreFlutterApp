# Flutter API Integration Guide

**Complete guide for integrating Django REST API with Flutter Tailor App**

---

## 📱 Part 1: Project Analysis Summary

### What's Already Done ✅

1. **Local Database** - Complete SQLite implementation
2. **UI/UX** - All screens designed and functional
3. **Business Logic** - Order workflow, payments, measurements
4. **Authentication UI** - Sign in/up screens ready
5. **Data Models** - Customer, Order, Payment, Measurement models

### What's Missing ❌

1. **API Service Layer** - No HTTP client for backend calls
2. **Data Sync** - No sync between local and cloud
3. **Image Upload** - No cloud storage integration
4. **Push Notifications** - No FCM integration
5. **Real-time Updates** - No WebSocket connection

---

## 🚀 Part 2: Flutter API Service Setup

### Step 1: Add Dependencies

**pubspec.yaml:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & API
  http: ^1.1.0
  dio: ^5.4.0  # Alternative to http with interceptors
  
  # State Management (if not using Provider)
  flutter_riverpod: ^2.4.9
  
  # Secure Storage for tokens
  flutter_secure_storage: ^9.0.0
  
  # JSON Serialization
  json_annotation: ^4.8.1
  
  # Connectivity
  connectivity_plus: ^5.0.2
  
  # Image Upload
  image_picker: ^1.0.5
  http_parser: ^4.0.2
  mime: ^1.0.4
  
  # Push Notifications
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  
dev_dependencies:
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
```

Run:
```bash
flutter pub get
```

---

### Step 2: Create API Configuration

**lib/core/config/api_config.dart:**
```dart
class ApiConfig {
  // Base URLs
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',  // Android emulator localhost
  );
  
  static const String apiVersion = 'v1';
  static const String apiPrefix = '/api/$apiVersion';
  
  // Full API URL
  static String get apiUrl => '$baseUrl$apiPrefix';
  
  // Endpoints
  static const String auth = '/auth';
  static const String customers = '/customers';
  static const String orders = '/orders';
  static const String payments = '/payments';
  static const String measurements = '/measurements';
  static const String tailors = '/tailors';
  static const String analytics = '/analytics';
  static const String notifications = '/notifications';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Pagination
  static const int defaultPageSize = 20;
}
```

---

### Step 3: Create Token Manager

**lib/data/services/token_manager.dart:**
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/utils/logger.dart';

class TokenManager {
  static const String _className = 'TokenManager';
  static const _storage = FlutterSecureStorage();
  
  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';
  
  /// Save tokens after login
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
    String? email,
  }) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      if (userId != null) {
        await _storage.write(key: _userIdKey, value: userId);
      }
      if (email != null) {
        await _storage.write(key: _emailKey, value: email);
      }
      Logger.info(_className, 'Tokens saved successfully');
    } catch (e) {
      Logger.error(_className, 'Failed to save tokens', error: e);
      rethrow;
    }
  }
  
  /// Get access token
  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      Logger.error(_className, 'Failed to read access token', error: e);
      return null;
    }
  }
  
  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      Logger.error(_className, 'Failed to read refresh token', error: e);
      return null;
    }
  }
  
  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Clear all tokens (logout)
  static Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _emailKey);
      Logger.info(_className, 'Tokens cleared successfully');
    } catch (e) {
      Logger.error(_className, 'Failed to clear tokens', error: e);
    }
  }
  
  /// Get user email
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _emailKey);
  }
}
```

---

### Step 4: Create HTTP Client with Interceptors

**lib/data/services/api_client.dart:**
```dart
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/logger.dart';
import 'token_manager.dart';

class ApiClient {
  static const String _className = 'ApiClient';
  static final ApiClient _instance = ApiClient._internal();
  late Dio _dio;
  
  factory ApiClient() => _instance;
  
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiUrl,
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: ApiConfig.defaultHeaders,
      ),
    );
    
    _setupInterceptors();
  }
  
  /// Setup interceptors for auth, logging, and error handling
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to headers
          final token = await TokenManager.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          Logger.debug(_className, 'Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        
        onResponse: (response, handler) {
          Logger.debug(_className, 'Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        
        onError: (error, handler) async {
          Logger.error(_className, 'API Error: ${error.message}', error: error);
          
          // Handle 401 Unauthorized - refresh token
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request with new token
              return handler.resolve(await _retry(error.requestOptions));
            } else {
              // Refresh failed, logout user
              await _handleLogout();
            }
          }
          
          return handler.next(error);
        },
      ),
    );
  }
  
  /// Refresh access token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await TokenManager.getRefreshToken();
      if (refreshToken == null) return false;
      
      final response = await _dio.post(
        '${ApiConfig.auth}/refresh/',
        data: {'refresh': refreshToken},
        options: Options(headers: {'Authorization': ''}), // No auth for refresh
      );
      
      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'] as String;
        final newRefreshToken = response.data['refresh'] as String?;
        
        await TokenManager.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? refreshToken,
        );
        
        Logger.info(_className, 'Token refreshed successfully');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error(_className, 'Token refresh failed', error: e);
      return false;
    }
  }
  
  /// Retry failed request
  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await TokenManager.getAccessToken();
    requestOptions.headers['Authorization'] = 'Bearer $token';
    
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
  
  /// Handle logout
  Future<void> _handleLogout() async {
    await TokenManager.clearTokens();
    // TODO: Navigate to login screen
    Logger.info(_className, 'User logged out due to token expiration');
  }
  
  /// Check internet connectivity
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await hasInternetConnection()) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'No internet connection',
        type: DioExceptionType.connectionError,
      );
    }
    
    return await _dio.get(path, queryParameters: queryParameters, options: options);
  }
  
  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await hasInternetConnection()) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'No internet connection',
        type: DioExceptionType.connectionError,
      );
    }
    
    return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }
  
  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }
  
  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
  }
  
  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }
  
  /// Upload file
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
  }) async {
    final fileName = filePath.split('/').last;
    
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath, filename: fileName),
      if (additionalData != null) ...additionalData,
    });
    
    return await _dio.post(path, data: formData);
  }
}
```

---

### Step 5: Create API Service

**lib/data/services/api_service.dart:**
```dart
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/logger.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/measurement_model.dart';
import 'api_client.dart';
import 'token_manager.dart';

class ApiService {
  static const String _className = 'ApiService';
  final ApiClient _client = ApiClient();
  
  // ==================== AUTHENTICATION ====================
  
  /// Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      Logger.info(_className, 'Attempting login for: $email');
      
      final response = await _client.post(
        '${ApiConfig.auth}/login/',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Save tokens
        await TokenManager.saveTokens(
          accessToken: data['tokens']['access'],
          refreshToken: data['tokens']['refresh'],
          userId: data['user']['id'].toString(),
          email: data['user']['email'],
        );
        
        Logger.info(_className, 'Login successful');
        return data;
      }
      
      throw Exception('Login failed');
    } catch (e) {
      Logger.error(_className, 'Login failed', error: e);
      rethrow;
    }
  }
  
  /// Register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String passwordConfirm,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      Logger.info(_className, 'Registering new user: $email');
      
      final response = await _client.post(
        '${ApiConfig.auth}/register/',
        data: {
          'email': email,
          'password': password,
          'password_confirm': passwordConfirm,
          'first_name': firstName,
          'last_name': lastName,
          if (phone != null) 'phone': phone,
        },
      );
      
      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        
        // Save tokens
        await TokenManager.saveTokens(
          accessToken: data['tokens']['access'],
          refreshToken: data['tokens']['refresh'],
          userId: data['user']['id'].toString(),
          email: data['user']['email'],
        );
        
        Logger.info(_className, 'Registration successful');
        return data;
      }
      
      throw Exception('Registration failed');
    } catch (e) {
      Logger.error(_className, 'Registration failed', error: e);
      rethrow;
    }
  }
  
  /// Logout
  Future<void> logout() async {
    await TokenManager.clearTokens();
    Logger.info(_className, 'User logged out');
  }
  
  // ==================== CUSTOMERS ====================
  
  /// Get all customers
  Future<List<Customer>> getCustomers({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final response = await _client.get(
        ApiConfig.customers,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      
      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        return results.map((json) => Customer.fromMap(json)).toList();
      }
      
      return [];
    } catch (e) {
      Logger.error(_className, 'Failed to fetch customers', error: e);
      return [];
    }
  }
  
  /// Get customer by ID
  Future<Customer?> getCustomer(String uniqueId) async {
    try {
      final response = await _client.get('${ApiConfig.customers}/$uniqueId/');
      
      if (response.statusCode == 200) {
        return Customer.fromMap(response.data);
      }
      
      return null;
    } catch (e) {
      Logger.error(_className, 'Failed to fetch customer: $uniqueId', error: e);
      return null;
    }
  }
  
  /// Create customer
  Future<Customer?> createCustomer(Customer customer) async {
    try {
      final response = await _client.post(
        ApiConfig.customers,
        data: customer.toMap(),
      );
      
      if (response.statusCode == 201) {
        Logger.info(_className, 'Customer created: ${customer.uniqueId}');
        return Customer.fromMap(response.data);
      }
      
      return null;
    } catch (e) {
      Logger.error(_className, 'Failed to create customer', error: e);
      return null;
    }
  }
  
  /// Update customer
  Future<Customer?> updateCustomer(String uniqueId, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        '${ApiConfig.customers}/$uniqueId/',
        data: data,
      );
      
      if (response.statusCode == 200) {
        Logger.info(_className, 'Customer updated: $uniqueId');
        return Customer.fromMap(response.data);
      }
      
      return null;
    } catch (e) {
      Logger.error(_className, 'Failed to update customer: $uniqueId', error: e);
      return null;
    }
  }
  
  /// Delete customer
  Future<bool> deleteCustomer(String uniqueId) async {
    try {
      final response = await _client.delete('${ApiConfig.customers}/$uniqueId/');
      
      if (response.statusCode == 204) {
        Logger.info(_className, 'Customer deleted: $uniqueId');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error(_className, 'Failed to delete customer: $uniqueId', error: e);
      return false;
    }
  }
  
  // ==================== ORDERS ====================
  
  /// Get all orders
  Future<List<Order>> getOrders({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? paymentStatus,
    DateTime? deliveryDateFrom,
    DateTime? deliveryDateTo,
  }) async {
    try {
      final response = await _client.get(
        ApiConfig.orders,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (status != null) 'status': status,
          if (paymentStatus != null) 'payment_status': paymentStatus,
          if (deliveryDateFrom != null) 'delivery_date_from': deliveryDateFrom.toIso8601String(),
          if (deliveryDateTo != null) 'delivery_date_to': deliveryDateTo.toIso8601String(),
        },
      );
      
      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        return results.map((json) => Order.fromMap(json)).toList();
      }
      
      return [];
    } catch (e) {
      Logger.error(_className, 'Failed to fetch orders', error: e);
      return [];
    }
  }
  
  /// Create order
  Future<Order?> createOrder(Order order) async {
    try {
      final response = await _client.post(
        ApiConfig.orders,
        data: order.toMap(),
      );
      
      if (response.statusCode == 201) {
        Logger.info(_className, 'Order created: ${order.uniqueId}');
        return Order.fromMap(response.data);
      }
      
      return null;
    } catch (e) {
      Logger.error(_className, 'Failed to create order', error: e);
      return null;
    }
  }
  
  /// Update order status
  Future<bool> updateOrderStatus(String uniqueId, String status) async {
    try {
      final response = await _client.patch(
        '${ApiConfig.orders}/$uniqueId/status/',
        data: {'status': status},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      Logger.error(_className, 'Failed to update order status', error: e);
      return false;
    }
  }
  
  /// Upload order images
  Future<bool> uploadOrderImages(String uniqueId, List<String> imagePaths) async {
    try {
      final formData = FormData();
      
      for (int i = 0; i < imagePaths.length && i < 2; i++) {
        final file = await MultipartFile.fromFile(imagePaths[i]);
        formData.files.add(MapEntry('image_${i + 1}', file));
      }
      
      final response = await _client.post(
        '${ApiConfig.orders}/$uniqueId/images/',
        data: formData,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      Logger.error(_className, 'Failed to upload order images', error: e);
      return false;
    }
  }
  
  // ==================== PAYMENTS ====================
  
  /// Create payment
  Future<Payment?> createPayment(Payment payment) async {
    try {
      final response = await _client.post(
        ApiConfig.payments,
        data: payment.toMap(),
      );
      
      if (response.statusCode == 201) {
        Logger.info(_className, 'Payment created: ${payment.uniqueId}');
        return Payment.fromMap(response.data);
      }
      
      return null;
    } catch (e) {
      Logger.error(_className, 'Failed to create payment', error: e);
      return null;
    }
  }
  
  /// Get payment history for order
  Future<List<Payment>> getPaymentHistory(String orderId) async {
    try {
      final response = await _client.get(
        ApiConfig.payments,
        queryParameters: {'order_id': orderId},
      );
      
      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        return results.map((json) => Payment.fromMap(json)).toList();
      }
      
      return [];
    } catch (e) {
      Logger.error(_className, 'Failed to fetch payment history', error: e);
      return [];
    }
  }
  
  // ==================== ANALYTICS ====================
  
  /// Get dashboard analytics
  Future<Map<String, dynamic>?> getDashboardAnalytics({
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _client.get(
        '${ApiConfig.analytics}/dashboard/',
        queryParameters: {
          'period': period,
          if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
        },
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      Logger.error(_className, 'Failed to fetch analytics', error: e);
      return null;
    }
  }
}
```

---

### Step 6: Create Sync Service

**lib/data/services/sync_service.dart:**
```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/utils/logger.dart';
import 'api_service.dart';
import 'local_db_service.dart';

class SyncService {
  static const String _className = 'SyncService';
  
  final ApiService _apiService = ApiService();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  
  /// Full sync - push local changes and pull server changes
  Future<bool> fullSync() async {
    if (_isSyncing) {
      Logger.warning(_className, 'Sync already in progress');
      return false;
    }
    
    _isSyncing = true;
    
    try {
      Logger.info(_className, 'Starting full sync');
      
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        Logger.warning(_className, 'No internet connection, skipping sync');
        return false;
      }
      
      // 1. Push local changes to server
      await _pushLocalChanges();
      
      // 2. Pull server changes to local
      await _pullServerChanges();
      
      _lastSyncTime = DateTime.now();
      Logger.info(_className, 'Full sync completed successfully');
      
      return true;
    } catch (e, stackTrace) {
      Logger.error(_className, 'Sync failed', error: e, stackTrace: stackTrace);
      return false;
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Push local changes to server
  Future<void> _pushLocalChanges() async {
    Logger.info(_className, 'Pushing local changes to server');
    
    // TODO: Implement push logic
    // - Get modified records since last sync
    // - Upload to server
    // - Mark as synced in local DB
  }
  
  /// Pull server changes to local
  Future<void> _pullServerChanges() async {
    Logger.info(_className, 'Pulling server changes to local');
    
    // TODO: Implement pull logic
    // - Fetch updated records from server
    // - Update local database
    // - Handle conflicts
  }
  
  /// Auto sync on app start
  Future<void> syncOnStart() async {
    await Future.delayed(const Duration(seconds: 2));
    await fullSync();
  }
  
  /// Background sync every 5 minutes
  void startBackgroundSync() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      fullSync();
    });
  }
}
```

---

## ✅ Part 3: Integration Checklist

### Phase 1: Setup (Week 1)
- [x] Add dependencies to pubspec.yaml
- [ ] Create API configuration
- [ ] Setup token manager
- [ ] Create HTTP client with interceptors
- [ ] Test authentication endpoints

### Phase 2: Core Integration (Week 2-3)
- [ ] Create API service layer
- [ ] Integrate customer CRUD operations
- [ ] Integrate order management
- [ ] Integrate payment system
- [ ] Test all endpoints

### Phase 3: Sync & Offline (Week 4)
- [ ] Implement data sync logic
- [ ] Handle offline mode
- [ ] Implement conflict resolution
- [ ] Add background sync

### Phase 4: Advanced Features (Week 5-6)
- [ ] Image upload to S3
- [ ] Push notifications with FCM
- [ ] Real-time updates
- [ ] Analytics integration

---

## 📝 Testing API Integration

```dart
// Example usage in a screen
class CustomersScreen extends StatefulWidget {
  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final ApiService _apiService = ApiService();
  List<Customer> _customers = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }
  
  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    
    try {
      final customers = await _apiService.getCustomers();
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('CustomersScreen', 'Failed to load customers', error: e);
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      itemCount: _customers.length,
      itemBuilder: (context, index) {
        final customer = _customers[index];
        return ListTile(
          title: Text(customer.name),
          subtitle: Text(customer.phone),
        );
      },
    );
  }
}
```

---

**Status:** ✅ Complete Flutter API integration guide ready  
**Next Steps:** Implement Django backend following DJANGO_API_STEP_BY_STEP_GUIDE.md

