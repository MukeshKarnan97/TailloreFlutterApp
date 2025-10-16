/// HTTP Client Service using Dio
/// Handles all API requests with interceptors, error handling, and token management
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:tailer_app/core/config/api_config.dart';
import 'package:tailer_app/core/services/token_storage_service.dart';
import 'package:tailer_app/core/utils/logger.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

/// API Client service using Dio
class ApiClient {
  late final Dio _dio;
  final TokenStorageService _tokenStorage;

  ApiClient({TokenStorageService? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorageService() {
    _dio = Dio(_getBaseOptions());
    _setupInterceptors();
  }

  /// Get Dio base options
  BaseOptions _getBaseOptions() {
    return BaseOptions(
      baseUrl: ApiConfig.apiUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': ApiConfig.contentType,
        'Accept': ApiConfig.acceptHeader,
      },
      validateStatus: (status) {
        // Accept all status codes to handle them manually
        return status != null && status < 500;
      },
    );
  }

  /// Setup Dio interceptors
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // Add logging interceptor in debug mode
    if (ApiConfig.environment == 'development') {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (obj) => Logger.api('[DIO] $obj'),
        ),
      );
    }
  }

  /// Request interceptor
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add access token to headers if available
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    Logger.api('🚀 REQUEST: ${options.method} ${options.uri}');
    return handler.next(options);
  }

  /// Response interceptor
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    Logger.api(
      '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}',
    );
    return handler.next(response);
  }

  /// Error interceptor
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    Logger.error(
      'ApiClient',
      '❌ ERROR: ${err.requestOptions.method} ${err.requestOptions.uri}',
      error: err,
    );

    // Handle 401 Unauthorized - try to refresh token
    if (err.response?.statusCode == HttpStatusCode.unauthorized) {
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the original request
          final response = await _retry(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (e) {
        Logger.error('ApiClient', 'Token refresh failed', error: e);
        // Clear tokens and force re-login
        await _tokenStorage.clearTokens();
      }
    }

    return handler.next(err);
  }

  /// Retry a failed request
  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      requestOptions.headers['Authorization'] = 'Bearer $token';
    }

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
      ),
    );
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh': refreshToken},
        options: Options(headers: {'Authorization': ''}), // Remove old token
      );

      if (response.statusCode == HttpStatusCode.ok) {
        final newAccessToken = response.data['access'];
        final newRefreshToken = response.data['refresh'];

        await _tokenStorage.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await _tokenStorage.saveRefreshToken(newRefreshToken);
        }

        Logger.info('ApiClient', '✨ Token refreshed successfully');
        return true;
      }

      return false;
    } catch (e) {
      Logger.error('ApiClient', 'Token refresh error', error: e);
      return false;
    }
  }

  /// Handle Dio errors and convert to ApiException
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: ApiErrorMessages.timeoutError,
          statusCode: null,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _extractErrorMessage(error.response?.data);
        return ApiException(
          message: message ?? ApiErrorMessages.getErrorMessage(statusCode),
          statusCode: statusCode,
          data: error.response?.data,
        );

      case DioExceptionType.cancel:
        return ApiException(message: 'Request cancelled');

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return ApiException(message: ApiErrorMessages.networkError);
        }
        return ApiException(message: ApiErrorMessages.unknownError);

      default:
        return ApiException(message: ApiErrorMessages.unknownError);
    }
  }

  /// Extract error message from response data
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    try {
      if (data is Map<String, dynamic>) {
        // Django REST Framework error format
        if (data.containsKey('detail')) {
          return data['detail'].toString();
        }

        // Field-specific errors
        final errors = <String>[];
        data.forEach((key, value) {
          if (value is List) {
            errors.add('$key: ${value.join(', ')}');
          } else {
            errors.add('$key: $value');
          }
        });

        if (errors.isNotEmpty) {
          return errors.join('\n');
        }
      } else if (data is String) {
        return data;
      }
    } catch (e) {
      Logger.error('ApiClient', 'Error extracting message', error: e);
    }

    return null;
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file with multipart/form-data
  Future<Response> uploadFile(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        ...?additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Download file
  Future<Response> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get Dio instance for advanced usage
  Dio get dio => _dio;
}
