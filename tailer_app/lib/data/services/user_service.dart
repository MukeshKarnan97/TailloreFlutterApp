import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/auth_storage_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final UserRepository _userRepository = UserRepository();
  final AuthStorageService _authStorage = AuthStorageService();
  
  UserModel? _currentUser;

  // Get current logged in user
  Future<UserModel?> getCurrentUser() async {
    try {
      if (_currentUser != null) {
        return _currentUser;
      }

      // Try to get user ID from auth storage
      final userIdString = await _authStorage.getUserId();
      if (userIdString == null) {
        return null;
      }

      final userId = int.tryParse(userIdString);
      if (userId == null) {
        return null;
      }

      // Fetch user from database
      _currentUser = await _userRepository.getUserById(userId);
      return _currentUser;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Get current user synchronously (returns cached user)
  UserModel? getCurrentUserSync() {
    return _currentUser;
  }

  // Update current user cache
  void setCurrentUser(UserModel? user) {
    _currentUser = user;
  }

  // Clear current user cache (for logout)
  void clearCurrentUser() {
    _currentUser = null;
  }

  // Get user display name
  String getUserDisplayName() {
    final user = getCurrentUserSync();
    if (user?.username.isNotEmpty == true) {
      return user!.username;
    }
    return user?.email.split('@').first ?? 'User';
  }

  // Get user email
  String getUserEmail() {
    final user = getCurrentUserSync();
    return user?.email ?? '';
  }

  // Get user profile picture
  String? getUserProfilePicture() {
    final user = getCurrentUserSync();
    return user?.profilePicture;
  }

  // Initialize user service (call on app start)
  Future<void> initialize() async {
    await getCurrentUser();
  }
}