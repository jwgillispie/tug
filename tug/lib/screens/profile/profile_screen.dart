// lib/screens/profile/profile_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/auth/auth_bloc.dart';
import 'package:tug/blocs/theme/theme_bloc.dart';
import 'package:tug/services/achievement_service.dart';
import 'package:tug/services/app_mode_service.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/utils/quantum_effects.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tug/services/user_service.dart';
import 'package:tug/services/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import '../../widgets/profile/social_statistics.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isDeleting = false;
  bool _loadingAchievements = false;
  int _unlockedAchievements = 0;
  bool _isUploadingProfilePicture = false;
  String? _userBio;
  final AchievementService _achievementService = AchievementService();
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _imagePicker = ImagePicker();
  final AppModeService _appModeService = AppModeService();
  final UserService _userService = UserService();
  
  AppMode _currentMode = AppMode.valuesMode;
  StreamSubscription<AppMode>? _modeSubscription;

  @override
  void initState() {
    super.initState();
    // Load the current theme state
    final themeState = context.read<ThemeBloc>().state;
    _darkModeEnabled = themeState.isDarkMode;

    // Initialize app mode
    _initializeMode();

    // Load achievements count
    _loadAchievementsCount();

    // Load notification preferences
    _loadNotificationPreferences();

    // Load user bio
    _loadUserBio();
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

  Future<void> _loadNotificationPreferences() async {
    final enabled = await _notificationService.getNotificationsEnabled();
    final time = await _notificationService.getNotificationTime();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _notificationTime = time;
      });
    }
  }

  Future<void> _loadUserBio() async {
    try {
      final userData = await _userService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userBio = userData.bio;
        });
      }
    } catch (e) {
      debugPrint('Failed to load user bio: $e');
    }
  }

  Future<void> _loadAchievementsCount() async {
    if (_loadingAchievements) return;

    setState(() {
      _loadingAchievements = true;
    });

    try {
      final achievements = await _achievementService.getAchievements();

      if (mounted) {
        setState(() {
          _unlockedAchievements =
              achievements.where((a) => a.isUnlocked).length;
          _loadingAchievements = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading achievements count: $e');
      if (mounted) {
        setState(() {
          _loadingAchievements = false;
        });
      }
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
      debugPrint('Error picking image: $e');
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
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('profile picture updated successfully')),
          );
        }
      } else {
        throw Exception('no profile picture URL returned from server');
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingProfilePicture = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _modeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isViceMode
                  ? (isDarkMode 
                      ? [TugColors.darkBackground, TugColors.viceGreenDark, TugColors.viceGreen]
                      : [TugColors.lightBackground, TugColors.viceGreen.withAlpha(20)])
                  : (isDarkMode 
                      ? [TugColors.darkBackground, TugColors.primaryPurpleDark, TugColors.primaryPurple]
                      : [TugColors.lightBackground, TugColors.primaryPurple.withAlpha(20)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: QuantumEffects.holographicShimmer(
          child: QuantumEffects.gradientText(
            'profile',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            colors: isViceMode
                ? (isDarkMode ? [TugColors.viceGreen, TugColors.viceGreenLight, TugColors.viceGreenDark] : [TugColors.viceGreen, TugColors.viceGreenLight])
                : (isDarkMode ? [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark] : [TugColors.primaryPurple, TugColors.primaryPurpleLight]),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            _buildProfileHeader(),

            // Settings sections
            _buildSettingsSection(
              title: 'account',
              items: [
                _buildSettingsItem(
                  icon: Icons.person_outline,
                  title: 'edit profile',
                  onTap: () {
                    context.push('/edit-profile');
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.lock_outline,
                  title: 'change password',
                  onTap: () {
                    context.push('/change-password');
                  },
                ),
              ],
            ),

            _buildSettingsSection(
              title: 'preferences',
              items: [
                _buildSwitchSettingsItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'dark mode',
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    // Dispatch theme changed event to update app theme
                    context.read<ThemeBloc>().add(ThemeChanged(value));
                  },
                ),
                _buildSwitchSettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'notifications',
                  subtitle: 'daily reminders at ${_notificationTime.format(context)}',
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    await _notificationService.setNotificationsEnabled(value);
                  },
                ),
                if (_notificationsEnabled) ...[
                  _buildSettingsItem(
                    icon: Icons.schedule,
                    title: 'notification time',
                    subtitle: _notificationTime.format(context),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _notificationTime,
                      );
                      if (picked != null && picked != _notificationTime) {
                        setState(() {
                          _notificationTime = picked;
                        });
                        await _notificationService.setNotificationTime(picked);
                      }
                    },
                  ),
                ],
              ],
            ),

            // Social Statistics Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const SocialStatistics(),
            ),

            _buildSettingsSection(
              title: 'progress',
              items: [
                // Special achievements item with enhanced badge
                InkWell(
                  onTap: () {
                    context.push('/achievements');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _unlockedAchievements > 0
                          ? LinearGradient(
                              colors: [
                                TugColors.success.withValues(alpha: 0.1),
                                TugColors.success.withValues(alpha: 0.05),
                              ],
                            )
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                      child: Row(
                        children: [
                          // Enhanced achievement icon with glow effect
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _unlockedAchievements > 0
                                    ? [TugColors.success.withValues(alpha: 0.2), TugColors.success.withValues(alpha: 0.1)]
                                    : [TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode).withValues(alpha: 0.15), TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode).withValues(alpha: 0.05)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  color: _unlockedAchievements > 0
                                      ? TugColors.success
                                      : TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode),
                                  size: 22,
                                ),
                                if (_unlockedAchievements > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [TugColors.success, Color(0xFF4CAF50)],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1),
                                        boxShadow: [
                                          BoxShadow(
                                            color: TugColors.success.withValues(alpha: 0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        '$_unlockedAchievements',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Enhanced achievement details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'achievements',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? TugColors.darkTextPrimary
                                            : TugColors.lightTextPrimary,
                                      ),
                                    ),
                                    if (_unlockedAchievements > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: TugColors.success,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'NEW',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _loadingAchievements
                                    ? Row(
                                        children: [
                                          SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'loading achievements...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? TugColors.darkTextSecondary
                                                  : TugColors.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _unlockedAchievements > 0
                                            ? 'you\'ve unlocked $_unlockedAchievements ${_unlockedAchievements == 1 ? 'achievement' : 'achievements'}! 🎉'
                                            : 'discover your achievements and unlock rewards',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? TugColors.darkTextSecondary
                                              : TugColors.lightTextSecondary,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          // Enhanced chevron
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
                                  : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.chevron_right,
                              color: _unlockedAchievements > 0
                                  ? TugColors.success
                                  : TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode).withValues(alpha: 0.7),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            _buildSettingsSection(
              title: 'subscription',
              items: [
                _buildSettingsItem(
                  icon: Icons.workspace_premium,
                  title: 'premium subscription',
                  subtitle: 'manage your subscription',
                  onTap: () {
                    context.push('/subscription');
                  },
                ),
              ],
            ),


            _buildSettingsSection(
              title: 'about',
              items: [
                _buildSettingsItem(
                  icon: Icons.info_outline,
                  title: 'about tug',
                  onTap: () {
                    context.push('/about');
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.help_outline,
                  title: 'help & support',
                  onTap: () {
                    context.push('/help');
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.description_outlined,
                  title: 'terms of service',
                  onTap: () {
                    context.push('/terms');
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'privacy policy',
                  onTap: () {
                    context.push('/privacy');
                  },
                ),
              ],
            ),

            // Add the danger zone section
            _buildDangerSection(),

            // Enhanced logout button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade50.withValues(alpha: 0.5),
                      Colors.red.shade100.withValues(alpha: 0.3),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.2),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(
                        Colors.red.withValues(alpha: 0.1),
                      ),
                    ),
                    onPressed: _isDeleting ? null : _showLogoutConfirmationDialog,
                    icon: Icon(
                      Icons.logout_outlined,
                      color: Colors.red.shade700,
                    ),
                    label: Text(
                      'log out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // App version
            const Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Text(
                'tug v3.0.0',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),

            // Add extra space at bottom to ensure logout button is visible
            SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String displayName = 'user';
        String email = '';

        if (state is Authenticated) {
          displayName = state.user.displayName ?? 'user';
          email = state.user.email ?? '';
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isViceMode
                  ? [
                      TugColors.viceGreen.withValues(alpha: 0.12),
                      TugColors.viceGreenLight.withValues(alpha: 0.06),
                      TugColors.viceGreenDark.withValues(alpha: 0.18),
                      TugColors.viceGreen.withValues(alpha: 0.08),
                    ]
                  : [
                      TugColors.primaryPurple.withValues(alpha: 0.12),
                      TugColors.primaryPurpleLight.withValues(alpha: 0.06),
                      TugColors.primaryPurpleDark.withValues(alpha: 0.18),
                      TugColors.primaryPurple.withValues(alpha: 0.08),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).cardColor.withValues(alpha: 0.95),
                  Theme.of(context).cardColor.withValues(alpha: 0.85),
                ],
              ),
              border: Border.all(
                color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Enhanced profile picture with premium glow effect
                Stack(
                  children: [
                    // Outer glow ring
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.4),
                            TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),
                    // Inner glow ring
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
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
                    ),
                    // Main avatar container
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isViceMode
                                ? [
                                    TugColors.viceGreen,
                                    TugColors.viceGreenLight,
                                    TugColors.viceGreenDark,
                                  ]
                                : [
                                    TugColors.primaryPurple,
                                    TugColors.primaryPurpleLight,
                                    TugColors.primaryPurpleDark,
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: TugColors.getPrimaryColor(isViceMode),
                            backgroundImage: state is Authenticated && state.user.photoURL != null 
                                ? NetworkImage(state.user.photoURL!) 
                                : null,
                            child: !(state is Authenticated && state.user.photoURL != null)
                                ? Icon(
                                    Icons.person,
                                    size: 56,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    // Enhanced camera button with premium styling
                    Positioned(
                      bottom: 8,
                      right: 18,
                      child: GestureDetector(
                        onTap: _isUploadingProfilePicture ? null : _showImageSourceDialog,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isViceMode
                                  ? [
                                      TugColors.viceGreen,
                                      TugColors.viceGreenDark,
                                      TugColors.viceGreenLight,
                                    ]
                                  : [
                                      TugColors.primaryPurple,
                                      TugColors.primaryPurpleDark,
                                      TugColors.primaryPurpleLight,
                                    ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isUploadingProfilePicture
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Enhanced name with gradient text
                QuantumEffects.gradientText(
                  displayName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  colors: isViceMode
                      ? [TugColors.viceGreen, TugColors.viceGreenLight, TugColors.viceGreenDark]
                      : [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark],
                ),
                const SizedBox(height: 8),
                
                // Enhanced email with better styling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? TugColors.darkSurfaceVariant.withValues(alpha: 0.5)
                        : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: isDarkMode
                            ? TugColors.darkTextSecondary
                            : TugColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? TugColors.darkTextSecondary
                              : TugColors.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bio section
                if (_userBio != null && _userBio!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
                          : TugColors.lightSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      _userBio!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isDarkMode
                            ? TugColors.darkTextPrimary
                            : TugColors.lightTextPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                
                // Premium edit profile button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: isViceMode
                          ? [TugColors.viceGreen.withValues(alpha: 0.1), TugColors.viceGreenLight.withValues(alpha: 0.05)]
                          : [TugColors.primaryPurple.withValues(alpha: 0.1), TugColors.primaryPurpleLight.withValues(alpha: 0.05)],
                    ),
                  ),
                  child: ElevatedButton.icon(
                    style: TugButtons.secondaryButtonStyle(
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        isViceMode: _currentMode == AppMode.vicesMode).copyWith(
                      backgroundColor: WidgetStateProperty.all(Colors.transparent),
                      elevation: WidgetStateProperty.all(0),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                    onPressed: () {
                      context.push('/edit-profile');
                    },
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: TugColors.getPrimaryColor(isViceMode),
                    ),
                    label: Text(
                      'customize profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: TugColors.getPrimaryColor(isViceMode),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> items,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 16,
            top: 32,
            bottom: 12,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isViceMode
                        ? [TugColors.viceGreen.withValues(alpha: 0.2), TugColors.viceGreenLight.withValues(alpha: 0.1)]
                        : [TugColors.primaryPurple.withValues(alpha: 0.2), TugColors.primaryPurpleLight.withValues(alpha: 0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: TugColors.getPrimaryColor(isViceMode),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(
              color: isDarkMode
                  ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
                  : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: items,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          child: Row(
            children: [
              // Enhanced icon with background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isViceMode
                        ? [TugColors.viceGreen.withValues(alpha: 0.15), TugColors.viceGreenLight.withValues(alpha: 0.05)]
                        : [TugColors.primaryPurple.withValues(alpha: 0.15), TugColors.primaryPurpleLight.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: TugColors.getPrimaryColor(isViceMode),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Enhanced chevron
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
                      : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 16,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.light
                          ? TugColors.lightTextSecondary
                          : TugColors.darkTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: 8,
          ),
          child: Text(
            'danger zone',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: _isDeleting ? null : _showDeleteAccountConfirmation,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'delete account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'permanently delete your account and all data',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  void _showDeleteAccountConfirmation() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? TugColors.darkSurface : Colors.white,
        title: Text(
          'delete account',
          style: TextStyle(
            color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'you deadass want to delete your account? this will permanently delete ALL your data including:\n\n'
          '• your profile information\n'
          '• all your values\n'
          '• all your activities\n'
          '• all your settings\n\n'
          'this action cannot be undone.',
          style: TextStyle(
            height: 1.5,
            color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel',
              style: TextStyle(
                color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _deleteAccount,
            child: const Text('delete everything'),
          ),
        ],
      ),
    );
  }

  Future<AuthCredential?> _promptForCredentials() async {
    AuthCredential? credential;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Controller is created when the dialog builds
        final passwordController = TextEditingController();
        bool isDialogOpen = true;

        // Helper function to safely close the dialog
        void safePop() {
          if (isDialogOpen) {
            isDialogOpen = false;
            Navigator.of(dialogContext).pop();
            // Dispose after the dialog animation completes
            Future.delayed(const Duration(milliseconds: 200), () {
              passwordController.dispose();
            });
          }
        }

        return WillPopScope(
          onWillPop: () async {
            safePop();
            return true;
          },
          child: AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? TugColors.darkSurface : Colors.white,
            title: Text(
              'confirm your password',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'for security reasons, please enter your password to confirm account deletion',
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context).brightness == Brightness.dark ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'password',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null &&
                        user.email != null &&
                        value.isNotEmpty) {
                      credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: value,
                      );
                    }
                    safePop();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: safePop,
                child: Text(
                  'cancel',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null &&
                      user.email != null &&
                      passwordController.text.isNotEmpty) {
                    credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: passwordController.text,
                    );
                  }
                  safePop();
                },
                child: const Text('confirm'),
              ),
            ],
          ),
        );
      },
    );

    return credential;
  }

  void _showLoadingDialog(String message) {
    // Check if any dialog is open and close it first
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Show the new dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async =>
            false, // Prevent accidental back button dismissal
        child: AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? TugColors.darkSurface : Colors.white,
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // Prevent multiple deletion attempts
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    Navigator.pop(context); // Close the confirmation dialog

    // Show loading indicator
    _showLoadingDialog('preparing to delete account...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('no user is currently signed in');
      }

      // 1. Re-authenticate the user before deletion (required by Firebase)
      // We'll need to collect the user's credentials again
      final credentials = await _promptForCredentials();

      if (credentials == null) {
        // User cancelled re-authentication
        // Close any open dialogs
        while (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        setState(() {
          _isDeleting = false;
        });
        return;
      }

      // Update loading message
      _showLoadingDialog('authenticating...');

      try {
        // Re-authenticate with Firebase
        await user.reauthenticateWithCredential(credentials);
      } catch (authError) {
        // Handle authentication errors specifically
        // Close any open dialogs
        while (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        setState(() {
          _isDeleting = false;
        });

        String errorMessage = 'authentication failed';
        if (authError is FirebaseAuthException) {
          switch (authError.code) {
            case 'wrong-password':
              errorMessage = 'incorrect password';
              break;
            case 'user-mismatch':
              errorMessage =
                  'the provided credentials do not match the current user';
              break;
            default:
              errorMessage = 'authentication error: ${authError.message}';
          }
        }

        // Show error dialog after a short delay to ensure UI stability
        Future.delayed(const Duration(milliseconds: 300), () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('authentication failed'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ok'),
                ),
              ],
            ),
          );
        });
        return;
      }

      // Update loading message
      _showLoadingDialog('deleting account data (values, activities, etc.)...');

      // 2. Delete account from your backend
      final userService = UserService();
      final backendDeleteSuccess = await userService.deleteAccount();

      if (!backendDeleteSuccess) {
        throw Exception('failed to delete account data from the server');
      }

      // Update loading message
      _showLoadingDialog('finalizing account deletion...');

      // 3. Delete the Firebase account
      await user.delete();

      // 4. Sign out and trigger auth state change
      await FirebaseAuth.instance.signOut();

      // Make sure all dialogs are closed
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Then trigger auth state change and navigation
      if (mounted) {
        context.read<AuthBloc>().add(LogoutEvent());
        context.go('/login');

        // Show a snackbar after navigation completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('your account has been deleted'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    } catch (e) {
      // Close all dialogs
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Reset state
      setState(() {
        _isDeleting = false;
      });

      // Show error after a short delay to ensure UI stability
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('error'),
              content: Text('error deleting account: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ok'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  void _showLogoutConfirmationDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? TugColors.darkSurface : Colors.white,
        title: Text(
          'log out',
          style: TextStyle(
            color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'are you sure you want to log out?',
          style: TextStyle(
            color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel',
              style: TextStyle(
                color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            child: const Text('log out'),
          ),
        ],
      ),
    );
  }
}
