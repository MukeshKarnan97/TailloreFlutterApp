/// Local Token Service
/// Generates and validates JWT-like tokens locally for offline-first authentication
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:tailer_app/core/utils/logger.dart';

class LocalTokenService {
  static final LocalTokenService _instance = LocalTokenService._internal();
  factory LocalTokenService() => _instance;
  LocalTokenService._internal();

  // Secret key for token generation (in production, use a more secure method)
  static const String _secretKey = 'tailor_app_local_secret_key_2025';
  
  /// Generate a local access token
  /// Returns a token string that includes user data and expiry
  String generateAccessToken({
    required String userId,
    required String email,
    Duration duration = const Duration(hours: 1),
  }) {
    try {
      final now = DateTime.now();
      final expiry = now.add(duration);
      
      final payload = {
        'user_id': userId,
        'email': email,
        'exp': expiry.millisecondsSinceEpoch,
        'iat': now.millisecondsSinceEpoch,
        'type': 'access',
      };
      
      final token = _createToken(payload);
      Logger.info('LocalToken', 'Generated access token for: $email');
      return token;
    } catch (e) {
      Logger.error('LocalToken', 'Failed to generate access token', error: e);
      rethrow;
    }
  }

  /// Generate a local refresh token
  /// Returns a longer-lived token for refreshing access tokens
  String generateRefreshToken({
    required String userId,
    required String email,
    Duration duration = const Duration(days: 7),
  }) {
    try {
      final now = DateTime.now();
      final expiry = now.add(duration);
      
      final payload = {
        'user_id': userId,
        'email': email,
        'exp': expiry.millisecondsSinceEpoch,
        'iat': now.millisecondsSinceEpoch,
        'type': 'refresh',
      };
      
      final token = _createToken(payload);
      Logger.info('LocalToken', 'Generated refresh token for: $email');
      return token;
    } catch (e) {
      Logger.error('LocalToken', 'Failed to generate refresh token', error: e);
      rethrow;
    }
  }

  /// Validate a token and return its payload
  /// Returns null if token is invalid or expired
  Map<String, dynamic>? validateToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        Logger.error('LocalToken', 'Invalid token format');
        return null;
      }

      // Decode payload
      final payload = _decodePayload(parts[1]);
      
      // Verify signature
      final expectedSignature = _generateSignature('${parts[0]}.${parts[1]}');
      if (parts[2] != expectedSignature) {
        Logger.error('LocalToken', 'Invalid token signature');
        return null;
      }

      // Check expiry
      final expiry = payload['exp'] as int;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiry);
      
      if (DateTime.now().isAfter(expiryDate)) {
        Logger.info('LocalToken', 'Token expired');
        return null;
      }

      Logger.info('LocalToken', 'Token validated successfully');
      return payload;
    } catch (e) {
      Logger.error('LocalToken', 'Token validation failed', error: e);
      return null;
    }
  }

  /// Check if a token is expired
  bool isTokenExpired(String token) {
    try {
      final payload = validateToken(token);
      return payload == null;
    } catch (e) {
      return true;
    }
  }

  /// Extract user ID from token without full validation
  String? getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = _decodePayload(parts[1]);
      return payload['user_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Create a token from payload
  String _createToken(Map<String, dynamic> payload) {
    // Create header
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    // Encode header and payload
    final headerEncoded = _base64UrlEncode(jsonEncode(header));
    final payloadEncoded = _base64UrlEncode(jsonEncode(payload));

    // Generate signature
    final signature = _generateSignature('$headerEncoded.$payloadEncoded');

    return '$headerEncoded.$payloadEncoded.$signature';
  }

  /// Generate HMAC SHA256 signature
  String _generateSignature(String data) {
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return _base64UrlEncode(digest.bytes);
  }

  /// Base64 URL encode
  String _base64UrlEncode(dynamic data) {
    final bytes = data is String ? utf8.encode(data) : data as List<int>;
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Base64 URL decode and parse JSON
  Map<String, dynamic> _decodePayload(String encoded) {
    // Add padding if needed
    final padding = '=' * ((4 - encoded.length % 4) % 4);
    final normalized = encoded + padding;
    
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }
}
