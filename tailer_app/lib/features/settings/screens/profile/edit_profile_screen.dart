import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/core/utils/logger.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:tailer_app/widgets/custom_header.dart';
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
          backgroundColor: AppColors.background,
          appBar: DashboardHeader(
            title: locale.translate('editProfile'),
            backgroundColor: AppColors.primary,
            notificationCount: 0,
            onBackPressed: () => context.pop(),
            onNotificationTap: () {
              showNavigationMessage(context, locale.translate('notifications'));
            },
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.03),
                  AppColors.background,
                ],
              ),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileImageSection(locale),
                            const SizedBox(height: 30),
                            _buildPersonalInfoSection(locale),
                            const SizedBox(height: 20),
                            _buildContactSection(locale),
                            const SizedBox(height: 20),
                            _buildBusinessSection(locale),
                            const SizedBox(height: 30),
                            _buildSaveButton(locale),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildProfileImageSection(AppLocalizations locale) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 2),
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

  Widget _buildPersonalInfoSection(AppLocalizations locale) {
    return _buildSection(
      title: locale.translate('personalInformation'),
      icon: Icons.person_outline_rounded,
      color: AppColors.primary,
      child: Column(
        children: [
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
        ],
      ),
    );
  }

  Widget _buildContactSection(AppLocalizations locale) {
    return _buildSection(
      title: locale.translate('contactInformation'),
      icon: Icons.contact_mail_rounded,
      color: AppColors.secondary,
      child: Column(
        children: [
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
          const SizedBox(height: 16),
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

  Widget _buildBusinessSection(AppLocalizations locale) {
    return _buildSection(
      title: locale.translate('businessInformation'),
      icon: Icons.business_rounded,
      color: AppColors.accent,
      child: _buildInputField(
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
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.08),
                  color.withOpacity(0.03),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.background,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Section content
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations locale) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSaving ? null : _saveProfile,
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    locale.translate('saveChanges'),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.background,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isReadOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: isReadOnly,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: isReadOnly ? AppColors.textSecondary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
        filled: true,
        fillColor: isReadOnly ? AppColors.panel.withOpacity(0.5) : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
