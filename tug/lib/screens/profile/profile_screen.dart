// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/auth/auth_bloc.dart';
import 'package:tug/blocs/theme/theme_bloc.dart';
import 'package:tug/services/achievement_service.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/widgets/profile/strava_import_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tug/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkModeEnabled = false;
  bool _isDeleting = false;
  bool _loadingAchievements = false;
  int _unlockedAchievements = 0;
  final AchievementService _achievementService = AchievementService();

  @override
  void initState() {
    super.initState();
    // Load the current theme state
    final themeState = context.read<ThemeBloc>().state;
    _darkModeEnabled = themeState.isDarkMode;

    // Load achievements count
    _loadAchievementsCount();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            _buildProfileHeader(),

            // Settings sections
            _buildSettingsSection(
              title: 'ACCOUNT',
              items: [
                _buildSettingsItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () {
                    context.push('/edit-profile');
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {
                    context.push('/change-password');
                  },
                ),
              ],
            ),

            _buildSettingsSection(
              title: 'PREFERENCES',
              items: [
                _buildSwitchSettingsItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    // Dispatch theme changed event to update app theme
                    context.read<ThemeBloc>().add(ThemeChanged(value));
                  },
                ),
              ],
            ),

            _buildSettingsSection(
              title: 'PROGRESS',
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
                                'Achievements',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _loadingAchievements
                                  ? const Text(
                                      'Loading...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : Text(
                                      _unlockedAchievements > 0
                                          ? 'You\'ve unlocked $_unlockedAchievements ${_unlockedAchievements == 1 ? 'achievement' : 'achievements'}'
                                          : 'View your progress and unlocked rewards',
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
              title: 'SUBSCRIPTION',
              items: [
                _buildSettingsItem(
                  icon: Icons.workspace_premium,
                  title: 'Premium Subscription',
                  subtitle: 'Manage your subscription',
                  onTap: () {
                    context.push('/subscription');
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.account_circle_outlined,
                  title: 'Account & Purchases',
                  subtitle: 'Manage your account and restore purchases',
                  onTap: () {
                    context.push('/account');
                  },
                ),
              ],
            ),

            // Connected accounts section
            _buildSettingsSection(
              title: 'CONNECTED ACCOUNTS',
              items: [
                _buildSettingsItem(
                  icon: Icons.link_rounded,
                  title: 'Manage Connected Accounts',
                  subtitle: 'Connect to Strava and other services',
                  onTap: () {
                    context.push('/accounts');
                  },
                ),
                // Add Strava import widget for easy connection
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: StravaImportWidget(
                    onConnectionStatusChanged: (isConnected) {
                      // If connected, show a snackbar
                      if (isConnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connected to Strava successfully!'),
                            backgroundColor: TugColors.success,
                          ),
                        );
                      }
                    },
                  ),
                ),
                // Import activities button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Import Strava Activities'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TugColors.primaryPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      context.push('/import-activities');
                    },
                  ),
                ),
              ],
            ),

            _buildSettingsSection(
              title: 'ABOUT',
              items: [
                _buildSettingsItem(
                  icon: Icons.info_outline,
                  title: 'About Tug',
                  onTap: () {
                    context.push('/about');
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    context.push('/help');
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {
                    context.push('/terms');
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
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
                  label: const Text('Log Out'),
                ),
              ),
            ),

            // App version
            const Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Text(
                'Tug v1.0.0',
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
        String displayName = 'User';
        String email = '';

        if (state is Authenticated) {
          displayName = state.user.displayName ?? 'User';
          email = state.user.email ?? '';
        }

        return Container(
          padding: const EdgeInsets.all(24),
          color: isDarkMode
              ? TugColors.primaryPurple.withOpacity(0.15)
              : TugColors.primaryPurple.withOpacity(0.05),
          child: Column(
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
                child: const CircleAvatar(
                  radius: 48,
                  backgroundColor: TugColors.primaryPurple,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
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
                child: const Text('Edit Profile'),
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
            'DANGER ZONE',
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
                          'Delete Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Permanently delete your account and all data',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This will permanently delete ALL your data including:\n\n'
          '• Your profile information\n'
          '• All your values\n'
          '• All your activities\n'
          '• All your settings\n\n'
          'This action cannot be undone.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _deleteAccount,
            child: const Text('Delete Everything'),
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
            title: const Text('Confirm Your Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'For security reasons, please enter your password to confirm account deletion',
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
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
                child: const Text('Cancel'),
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
                child: const Text('Confirm'),
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
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
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
    _showLoadingDialog('Preparing to delete account...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
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
      _showLoadingDialog('Authenticating...');

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

        String errorMessage = 'Authentication failed';
        if (authError is FirebaseAuthException) {
          switch (authError.code) {
            case 'wrong-password':
              errorMessage = 'Incorrect password';
              break;
            case 'user-mismatch':
              errorMessage =
                  'The provided credentials do not match the current user';
              break;
            default:
              errorMessage = 'Authentication error: ${authError.message}';
          }
        }

        // Show error dialog after a short delay to ensure UI stability
        Future.delayed(const Duration(milliseconds: 300), () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Authentication Failed'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
        return;
      }

      // Update loading message
      _showLoadingDialog('Deleting account data (values, activities, etc.)...');

      // 2. Delete account from your backend
      final userService = UserService();
      final backendDeleteSuccess = await userService.deleteAccount();

      if (!backendDeleteSuccess) {
        throw Exception('Failed to delete account data from the server');
      }

      // Update loading message
      _showLoadingDialog('Finalizing account deletion...');

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
                content: Text('Your account has been deleted'),
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
              title: const Text('Error'),
              content: Text('Error deleting account: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
