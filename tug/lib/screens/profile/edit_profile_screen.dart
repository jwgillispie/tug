// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tug/blocs/auth/auth_bloc.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/services/app_mode_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tug/services/user_service.dart';
import 'package:tug/widgets/common/tug_text_field.dart';
import 'package:tug/utils/quantum_effects.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final AppModeService _appModeService = AppModeService();

  bool _isLoading = false;
  bool _isUploadingProfilePicture = false;
  String? _errorMessage;
  String? _successMessage;
  final ImagePicker _imagePicker = ImagePicker();
  
  AppMode _currentMode = AppMode.valuesMode;
  StreamSubscription<AppMode>? _modeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeMode();
    _loadUserData();
  }

  void _initializeMode() async {
    await _appModeService.initialize();
    _modeSubscription = _appModeService.modeStream.listen((mode) {
      if (mounted) {
        setState(() {
          _currentMode = mode;
        });
      }
    });
    if (mounted) {
      setState(() {
        _currentMode = _appModeService.currentMode;
      });
    }
  }

  @override
  void dispose() {
    _modeSubscription?.cancel();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _displayNameController.text = user.displayName ?? '';
      });
      
      // Load additional user data from backend
      try {
        final userService = UserService();
        final userData = await userService.getCurrentUserProfile();
        if (mounted) {
          setState(() {
            _bioController.text = userData.bio ?? '';
          });
        }
      } catch (e) {
        // If we can't load the backend data, just continue with Firebase data
      }
    }
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Update Firebase display name
        await user.updateDisplayName(_displayNameController.text.trim());

        // Update user profile in MongoDB
        final userService = UserService();
        await userService.updateUserProfile({
          'display_name': _displayNameController.text.trim(),
          'bio': _bioController.text.trim(),
        });

        if (mounted) {
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            // Force reload to get the latest Firebase user data
            await user.reload();
            // Only update the state, don't check full auth status
            if (mounted) {
              context
                  .read<AuthBloc>()
                  .add(AuthStateChangedEvent(FirebaseAuth.instance.currentUser));
            }
          }
        }

        setState(() {
          _successMessage = 'Profile updated successfully';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('choose profile picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadProfilePicture(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error selecting image: $e')),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    if (_isUploadingProfilePicture) return;

    setState(() {
      _isUploadingProfilePicture = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('no user found');
      }

      // Read image file as bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Convert to base64
      final String base64Image = base64Encode(imageBytes);
      
      // Upload to backend
      final userService = UserService();
      final response = await userService.uploadProfilePicture(base64Image);
      
      if (response['profile_picture_url'] != null) {
        final profilePictureUrl = response['profile_picture_url'] as String;
        
        // Update Firebase Auth profile with the URL from backend
        await user.updatePhotoURL(profilePictureUrl);
        await user.reload();

        // Trigger auth state change to update UI
        if (mounted) {
          context.read<AuthBloc>().add(CheckAuthStatusEvent());
          
          setState(() {
            _successMessage = 'profile picture updated successfully';
            _isUploadingProfilePicture = false;
          });
        }
      } else {
        throw Exception('no profile picture URL returned from server');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'error uploading picture';
        if (e.toString().contains('413')) {
          errorMessage = 'image too large. please choose a smaller image.';
        } else if (e.toString().contains('401')) {
          errorMessage = 'please sign in again to upload';
        } else if (e.toString().contains('500')) {
          errorMessage = 'server error. please try again later.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'network error. check your connection.';
        }
        
        setState(() {
          _errorMessage = errorMessage;
          _isUploadingProfilePicture = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isViceMode = _currentMode == AppMode.vicesMode;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isViceMode
                  ? [TugColors.viceGreen.withValues(alpha: 0.1), TugColors.viceGreenLight.withValues(alpha: 0.05)]
                  : [TugColors.primaryPurple.withValues(alpha: 0.1), TugColors.primaryPurpleLight.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: QuantumEffects.gradientText(
          'edit profile',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          colors: isViceMode
              ? [TugColors.viceGreen, TugColors.viceGreenLight]
              : [TugColors.primaryPurple, TugColors.primaryPurpleLight],
        ),
        iconTheme: IconThemeData(
          color: TugColors.getPrimaryColor(isViceMode),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.02),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message display
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TugColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: TugColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: TugColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Success message display
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TugColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: TugColors.success,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: TugColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Enhanced profile picture with upload functionality
              Center(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.05),
                            TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.02),
                          ],
                        ),
                        border: Border.all(
                          color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              // Glow effect
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              // Main avatar
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isViceMode
                                        ? [TugColors.viceGreen, TugColors.viceGreenLight]
                                        : [TugColors.primaryPurple, TugColors.primaryPurpleLight],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(3),
                                child: CircleAvatar(
                                  radius: 57,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 55,
                                    backgroundColor: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
                                    backgroundImage: state is Authenticated && state.user.photoURL != null 
                                        ? NetworkImage(state.user.photoURL!) 
                                        : null,
                                    child: !(state is Authenticated && state.user.photoURL != null)
                                        ? Icon(
                                            Icons.person,
                                            size: 50,
                                            color: TugColors.getPrimaryColor(isViceMode),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              if (_isUploadingProfilePicture)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'uploading...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.1),
                                  TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                            child: TextButton.icon(
                              onPressed: _isUploadingProfilePicture ? null : _showImageSourceDialog,
                              icon: Icon(
                                Icons.camera_alt_outlined,
                                color: TugColors.getPrimaryColor(isViceMode),
                                size: 20,
                              ),
                              label: Text(
                                _isUploadingProfilePicture ? 'uploading...' : 'change profile picture',
                                style: TextStyle(
                                  color: TugColors.getPrimaryColor(isViceMode),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Display Name Field
              TugTextField(
                label: 'Display Name',
                hint: 'Enter your display name',
                controller: _displayNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a display name';
                  }
                  if (value.length < 2) {
                    return 'Display name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Bio Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TugTextField(
                    label: 'Bio',
                    hint: 'Tell us about yourself (optional)',
                    controller: _bioController,
                    maxLines: 3,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(300),
                    ],
                    validator: (value) {
                      if (value != null && value.length > 300) {
                        return 'Bio must be 300 characters or less';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {}); // Refresh to update character count
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_bioController.text.length}/300',
                    style: TextStyle(
                      fontSize: 12,
                      color: _bioController.text.length > 280 
                          ? Colors.orange
                          : Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Email Field (Read-only)
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  String email = '';
                  if (state is Authenticated) {
                    email = state.user.email ?? '';
                  }

                  return TugTextField(
                    label: 'email',
                    hint: 'your email address',
                    controller: TextEditingController(text: email),
                    keyboardType: TextInputType.emailAddress,
                    validator: null,
                  );
                },
              ),

              const SizedBox(height: 32),

              // Enhanced Save Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: isViceMode
                        ? [TugColors.viceGreen, TugColors.viceGreenDark]
                        : [TugColors.primaryPurple, TugColors.primaryPurpleDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleSave,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isLoading ? 'saving...' : 'save changes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
