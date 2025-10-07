import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/core/utils/logger.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with NavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final AuthService _authService = AuthService();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _profileImagePath;
  File? _profileImageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _usernameController.text = currentUser.username;
        _emailController.text = currentUser.email;
        _phoneController.text = currentUser.phone ?? '';
        _profileImagePath = currentUser.profilePicture;
        
        // Set profile image file if exists
        if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
          final file = File(_profileImagePath!);
          if (await file.exists()) {
            _profileImageFile = file;
          }
        }
        
        // For now, we'll use a default shop name since users table doesn't have shop_name
        // You can modify this to fetch from a different source or add shop_name to users table
        _shopNameController.text = '${currentUser.username}\'s Tailor Shop';
      }
    } catch (e) {
      Logger.error('EditProfileScreen', 'Failed to load user data', error: e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final locale = AppLocalizations.of(_localeProvider.languageCode);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Update user in database
      await _dbService.update(
        'users',
        {
          'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'profile_picture': _profileImagePath,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [currentUser.id],
      );

      // Note: Shop name is not stored in users table for now
      // You can create a separate shop_profiles table or add shop_name to users table
      // For now, we'll just save the other fields

      // Refresh auth service user data
      // Note: AuthService doesn't have refreshUserData method yet
      // We can implement it later or just proceed without it

      Logger.info('EditProfileScreen', 'Profile updated successfully');
      
      if (mounted) {
        showNavigationMessage(
          context,
          locale.translate('profileUpdated'),
          customMessage: locale.translate('profileUpdatedSuccessfully'),
          backgroundColor: Colors.green,
        );
        
        // Go back to settings
        context.pop();
      }
    } catch (e) {
      Logger.error('EditProfileScreen', 'Failed to update profile', error: e);
      
      if (mounted) {
        showNavigationMessage(
          context,
          locale.translate('updateFailed'),
          customMessage: locale.translate('profileUpdateFailed'),
          backgroundColor: Colors.red,
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _selectProfileImage() async {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    try {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(locale.translate('chooseFromGallery')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(locale.translate('takePhoto')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              if (_profileImageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(locale.translate('removePhoto')),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      Logger.error('EditProfileScreen', 'Failed to show image picker', error: e);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // For now, we'll simulate image selection
      // In a real app, you would use image_picker package
      // final ImagePicker picker = ImagePicker();
      // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      // if (image != null) {
      //   final file = File(image.path);
      //   setState(() {
      //     _profileImageFile = file;
      //     _profileImagePath = file.path;
      //   });
      // }
      
      // Simulate for now
      Logger.info('EditProfileScreen', 'Gallery selection simulated');
    } catch (e) {
      Logger.error('EditProfileScreen', 'Failed to pick image from gallery', error: e);
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      // For now, we'll simulate camera capture
      // In a real app, you would use image_picker package
      // final ImagePicker picker = ImagePicker();
      // final XFile? image = await picker.pickImage(source: ImageSource.camera);
      // if (image != null) {
      //   final file = File(image.path);
      //   setState(() {
      //     _profileImageFile = file;
      //     _profileImagePath = file.path;
      //   });
      // }
      
      // Simulate for now
      Logger.info('EditProfileScreen', 'Camera capture simulated');
    } catch (e) {
      Logger.error('EditProfileScreen', 'Failed to pick image from camera', error: e);
    }
  }

  void _removeProfileImage() {
    setState(() {
      _profileImageFile = null;
      _profileImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              locale.translate('editProfile'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(AppConstants.primaryTeal),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: AppConstants.spacingL),
                          _buildPersonalInfoSection(),
                          const SizedBox(height: AppConstants.spacingXL),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with image picker
          GestureDetector(
            onTap: _selectProfileImage,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(AppConstants.primaryTeal).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: _profileImageFile != null
                        ? Image.file(
                            _profileImageFile!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(AppConstants.primaryTeal),
                                  const Color(AppConstants.primaryTeal).withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(AppConstants.primaryTeal),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            locale.translate('updatePersonalInformation'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.translate('personalInformation'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          // Username field (read-only)
          _buildInputField(
            controller: _usernameController,
            label: locale.translate('username'),
            icon: Icons.person_outline,
            isReadOnly: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return locale.translate('usernameRequired');
              }
              if (value.trim().length < 3) {
                return locale.translate('usernameMinLength');
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Email field (read-only)
          _buildInputField(
            controller: _emailController,
            label: locale.translate('email'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isReadOnly: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return locale.translate('emailRequired');
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return locale.translate('emailInvalid');
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Shop Name field
          _buildInputField(
            controller: _shopNameController,
            label: locale.translate('shopName'),
            icon: Icons.store_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return locale.translate('pleaseEnterShopName');
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Phone field (optional)
          _buildInputField(
            controller: _phoneController,
            label: '${locale.translate('phone')} (${locale.translate('optional')})',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value.trim())) {
                  return locale.translate('phoneInvalid');
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isReadOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: isReadOnly,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isReadOnly ? Colors.grey[600] : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isReadOnly ? Colors.grey[500] : const Color(AppConstants.primaryTeal),
        ),
        suffixIcon: isReadOnly ? Icon(
          Icons.lock_outline,
          color: Colors.grey[500],
          size: 20,
        ) : null,
        labelStyle: GoogleFonts.inter(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isReadOnly ? Colors.grey[300]! : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(AppConstants.primaryTeal),
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isReadOnly ? Colors.grey[200]! : Colors.grey[300]!),
        ),
        filled: isReadOnly,
        fillColor: isReadOnly ? Colors.grey[50] : null,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConstants.primaryTeal),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                locale.translate('saveChanges'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}