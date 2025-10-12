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
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  final ImagePicker _imagePicker = ImagePicker();
  
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
        _usernameController.text = currentUser.name;
        _emailController.text = currentUser.email;
        _phoneController.text = currentUser.phone;
        _shopNameController.text = currentUser.shopName;
        
        // Load profile image if exists
        _profileImagePath = currentUser.profileImagePath;
        if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
          _profileImageFile = File(_profileImagePath!);
        }
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

      // Save image to permanent location if a new image was selected
      String? savedImagePath = _profileImagePath;
      if (_profileImageFile != null && _profileImagePath != null) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final imagesDir = Directory('${appDir.path}/profile_images');
          if (!await imagesDir.exists()) {
            await imagesDir.create(recursive: true);
          }
          
          final fileName = 'profile_${currentUser.uniqueId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(_profileImagePath!)}';
          final savedImage = File('${imagesDir.path}/$fileName');
          await _profileImageFile!.copy(savedImage.path);
          savedImagePath = savedImage.path;
          
          Logger.info('EditProfileScreen', 'Profile image saved to: $savedImagePath');
        } catch (e) {
          Logger.error('EditProfileScreen', 'Failed to save profile image', error: e);
          // Continue with update even if image save fails
        }
      }

      // Update tailor in database using uniqueId
      await _dbService.updateTailor(currentUser.uniqueId, {
        'name': _usernameController.text.trim(),
        'shop_name': _shopNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profile_image_path': savedImagePath,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Refresh auth service to reload user data
      await _authService.initialize();
      
      // Reload profile data to refresh UI
      await _loadUserData();

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
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    try {
      // Request permission
      PermissionStatus permissionStatus;
      if (Platform.isAndroid) {
        // Android 13+ uses READ_MEDIA_IMAGES, older uses READ_EXTERNAL_STORAGE
        if (await Permission.photos.isGranted || await Permission.storage.isGranted) {
          permissionStatus = PermissionStatus.granted;
        } else {
          permissionStatus = await Permission.photos.request();
          if (permissionStatus.isDenied) {
            permissionStatus = await Permission.storage.request();
          }
        }
      } else {
        // iOS
        permissionStatus = await Permission.photos.request();
      }
      
      // Check if permission was denied
      if (permissionStatus.isDenied) {
        if (mounted) {
          showNavigationMessage(
            context,
            'Permission Denied',
            customMessage: 'Please grant storage permission to select photos',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }
      
      if (permissionStatus.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text('Storage permission is required to select photos. Please enable it in app settings.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // Permission granted, pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImageFile = File(pickedFile.path);
          _profileImagePath = pickedFile.path;
        });
        Logger.info('EditProfileScreen', 'Image selected from gallery: ${pickedFile.path}');
      }
    } catch (e) {
      Logger.error('EditProfileScreen', 'Failed to pick image from gallery', error: e);
      if (mounted) {
        showNavigationMessage(
          context,
          locale.translate('error'),
          customMessage: 'Failed to select image',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    try {
      // Request camera permission
      PermissionStatus permissionStatus = await Permission.camera.request();
      
      // Check if permission was denied
      if (permissionStatus.isDenied) {
        if (mounted) {
          showNavigationMessage(
            context,
            'Permission Denied',
            customMessage: 'Please grant camera permission to take photos',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }
      
      if (permissionStatus.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text('Camera permission is required to take photos. Please enable it in app settings.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // Permission granted, take photo
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImageFile = File(pickedFile.path);
          _profileImagePath = pickedFile.path;
        });
        Logger.info('EditProfileScreen', 'Photo captured from camera: ${pickedFile.path}');
      }
    } catch (e) {
      Logger.error('EditProfileScreen', 'Failed to pick image from camera', error: e);
      if (mounted) {
        showNavigationMessage(
          context,
          locale.translate('error'),
          customMessage: 'Failed to capture photo',
          backgroundColor: Colors.red,
        );
      }
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
