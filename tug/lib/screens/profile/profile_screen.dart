// lib/screens/profile/profile_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/auth/auth_bloc.dart';
import 'package:tug/blocs/theme/theme_bloc.dart';
import 'package:tug/services/achievement_service.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/utils/quantum_effects.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tug/services/user_service.dart';
import 'package:tug/services/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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
  final AchievementService _achievementService = AchievementService();
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load the current theme state
    final themeState = context.read<ThemeBloc>().state;
    _darkModeEnabled = themeState.isDarkMode;

    // Load achievements count
    _loadAchievementsCount();

    // Load notification preferences
    _loadNotificationPreferences();
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

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firebase Auth profile
      await user.updatePhotoURL(downloadUrl);
      await user.reload();

      // Sync with backend
      final userService = UserService();
      await userService.syncProfilePictureUrl(downloadUrl);

      // Trigger auth state change to update UI
      context.read<AuthBloc>().add(CheckAuthStatusEvent());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('profile picture updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error uploading picture: $e')),
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
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode 
                  ? [TugColors.darkBackground, TugColors.primaryPurpleDark, TugColors.primaryPurple]
                  : [TugColors.lightBackground, TugColors.primaryPurple.withAlpha(20)],
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
            colors: isDarkMode 
                ? [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark] 
                : [TugColors.primaryPurple, TugColors.primaryPurpleLight],
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
                // Add debug section in development mode
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  _buildSettingsItem(
                    icon: Icons.bug_report_outlined,
                    title: 'test notification (1 min)',
                    subtitle: 'schedule a test notification for 1 minute from now',
                    onTap: () async {
                      await _notificationService.scheduleOneTimeNotification(const Duration(minutes: 1));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test notification scheduled for 1 minute from now')),
                        );
                      }
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.timer_outlined,
                    title: 'test notification (2 min)',
                    subtitle: 'schedule a test notification for 2 minutes from now',
                    onTap: () async {
                      await _notificationService.scheduleOneTimeNotification(const Duration(minutes: 2));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test notification scheduled for 2 minutes from now')),
                        );
                      }
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.schedule_outlined,
                    title: 'test notification for set time',
                    subtitle: 'schedule a test notification for the time you set above',
                    onTap: () async {
                      await _notificationService.scheduleNotificationForTime(_notificationTime);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Test notification scheduled for ${_notificationTime.format(context)}')),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),

            _buildSettingsSection(
              title: 'progress',
              items: [
                // Special achievements item with badge
                InkWell(
                  onTap: () {
                    context.push('/achievements');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        // Achievement icon
                        Stack(
                          children: [
                            const Icon(
                              Icons.emoji_events_outlined,
                              color: TugColors.primaryPurple,
                            ),
                            if (_unlockedAchievements > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: TugColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
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
                        const SizedBox(width: 16),

                        // Achievement details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'achievements',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _loadingAchievements
                                  ? const Text(
                                      'loading...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : Text(
                                      _unlockedAchievements > 0
                                          ? 'you\'ve unlocked $_unlockedAchievements ${_unlockedAchievements == 1 ? 'achievement' : 'achievements'}'
                                          : 'view your progress and unlocked rewards',
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

            // Logout button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isDeleting ? null : _showLogoutConfirmationDialog,
                  icon: const Icon(Icons.logout),
                  label: const Text('log out'),
                ),
              ),
            ),

            // App version
            const Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Text(
                'tug v2.0.0',
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

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String displayName = 'user';
        String email = '';

        if (state is Authenticated) {
          displayName = state.user.displayName ?? 'user';
          email = state.user.email ?? '';
        }

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TugColors.primaryPurple.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: TugColors.primaryPurple,
                      backgroundImage: state is Authenticated && state.user.photoURL != null 
                          ? NetworkImage(state.user.photoURL!) 
                          : null,
                      child: !(state is Authenticated && state.user.photoURL != null)
                          ? const Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingProfilePicture ? null : _showImageSourceDialog,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: TugColors.primaryPurple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _isUploadingProfilePicture
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode
                      ? TugColors.darkTextSecondary
                      : TugColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: TugButtons.secondaryButtonStyle(
                    isDark: Theme.of(context).brightness == Brightness.dark),
                onPressed: () {
                  context.push('/edit-profile');
                },
                child: const Text('edit profile'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> items,
  }) {
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
            title,
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
          child: Column(
            children: items,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: TugColors.primaryPurple,
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
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
            color: TugColors.primaryPurple,
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
            activeColor: TugColors.primaryPurple,
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
