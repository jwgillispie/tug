// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tug/blocs/auth/auth_bloc.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/services/app_mode_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tug/services/user_service.dart';
import 'package:tug/widgets/common/tug_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
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
    super.dispose();
  }

  Future<void> _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _displayNameController.text = user.displayName ?? '';
      });
    }
    return Future.value();
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
        });

        if (mounted) {
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            // Force reload to get the latest Firebase user data
            await user.reload();
            // Only update the state, don't check full auth status
            context
                .read<AuthBloc>()
                .add(AuthStateChangedEvent(FirebaseAuth.instance.currentUser));
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
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
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
                    color: TugColors.error.withOpacity(0.1),
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
                    color: TugColors.success.withOpacity(0.1),
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

              // Profile picture with upload functionality
              Center(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: TugColors.getPrimaryColor(isViceMode),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 48,
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
                            if (_isUploadingProfilePicture)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isUploadingProfilePicture ? null : _showImageSourceDialog,
                          child: Text(_isUploadingProfilePicture ? 'uploading...' : 'change profile picture'),
                        ),
                      ],
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

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: TugButtons.primaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                  onPressed: _isLoading ? null : _handleSave,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
