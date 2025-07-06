// lib/screens/user_profile/user_profile_screen.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/app_mode_service.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/decorations.dart';
import '../../utils/quantum_effects.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final AppModeService _appModeService = AppModeService();
  
  UserModel? _user;
  bool _isLoading = true;
  String? _error;
  AppMode _currentMode = AppMode.valuesMode;
  int _totalActivityHours = 0;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    _initializeMode();
    _loadUserProfile();
  }

  void _initializeMode() async {
    await _appModeService.initialize();
    _appModeService.modeStream.listen((mode) {
      if (mounted) {
        setState(() {
          _currentMode = mode;
        });
      }
    });
    setState(() {
      _currentMode = _appModeService.currentMode;
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint('Loading user profile for userId: ${widget.userId}');
      final user = await _userService.getUserProfile(widget.userId);
      debugPrint('Successfully loaded user profile: ${user.displayName}');
      setState(() {
        _user = user;
        _isLoading = false;
      });
      
      // Load user statistics
      _loadUserStatistics();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserStatistics() async {
    if (_loadingStats) return;
    
    setState(() {
      _loadingStats = true;
    });

    try {
      final stats = await _userService.getUserStatistics(widget.userId);
      final totalMinutes = stats['total_activity_minutes'] ?? 0;
      final totalHours = (totalMinutes / 60).round();
      
      setState(() {
        _totalActivityHours = totalHours;
        _loadingStats = false;
      });
    } catch (e) {
      debugPrint('Error loading user statistics: $e');
      setState(() {
        _totalActivityHours = 0;
        _loadingStats = false;
      });
    }
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
                      : [TugColors.lightBackground, TugColors.viceGreen.withValues(alpha: 0.2)])
                  : (isDarkMode
                      ? [TugColors.darkBackground, TugColors.primaryPurpleDark, TugColors.primaryPurple]
                      : [TugColors.lightBackground, TugColors.primaryPurple.withValues(alpha: 0.2)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: QuantumEffects.holographicShimmer(
          child: QuantumEffects.gradientText(
            _user?.displayName ?? 'Profile',
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              TugColors.getBackgroundColor(isDarkMode, isViceMode),
              TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.02),
              TugColors.getBackgroundColor(isDarkMode, isViceMode),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: _buildBody(isDarkMode, isViceMode),
      ),
    );
  }

  Widget _buildBody(bool isDarkMode, bool isViceMode) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TugColors.getTextColor(isDarkMode, isViceMode),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: TugColors.getPrimaryColor(isViceMode),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_user == null) {
      return const Center(
        child: Text('User not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileHeader(isDarkMode, isViceMode),
          const SizedBox(height: 32),
          _buildBioSection(isDarkMode, isViceMode),
          const SizedBox(height: 32),
          _buildStatsSection(isDarkMode, isViceMode),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDarkMode, bool isViceMode) {
    return QuantumEffects.floating(
      offset: 8,
      child: QuantumEffects.quantumBorder(
        glowColor: TugColors.getPrimaryColor(isViceMode),
        intensity: 0.6,
        child: Container(
          width: double.infinity,
          decoration: TugDecorations.premiumCard(
            isDark: isDarkMode,
            isViceMode: isViceMode,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Picture
              QuantumEffects.cosmicBreath(
                intensity: 0.1,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        TugColors.getPrimaryColor(isViceMode),
                        TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.7),
                      ],
                    ),
                    boxShadow: TugColors.getNeonGlow(
                      TugColors.getPrimaryColor(isViceMode),
                      intensity: 0.4,
                    ),
                  ),
                  child: _user!.profilePictureUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _user!.profilePictureUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildAvatarFallback();
                            },
                          ),
                        )
                      : _buildAvatarFallback(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Display Name
              QuantumEffects.gradientText(
                _user!.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                colors: [
                  TugColors.getTextColor(isDarkMode, isViceMode),
                  TugColors.getPrimaryColor(isViceMode),
                ],
              ),
              
              // Username
              if (_user!.username != null) ...[
                const SizedBox(height: 4),
                Text(
                  '@${_user!.username}',
                  style: TextStyle(
                    fontSize: 16,
                    color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Center(
      child: Text(
        _user!.displayName.isNotEmpty ? _user!.displayName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBioSection(bool isDarkMode, bool isViceMode) {
    if (_user!.bio == null || _user!.bio!.isEmpty) {
      return Container();
    }

    return QuantumEffects.floating(
      offset: 6,
      child: Container(
        width: double.infinity,
        decoration: TugDecorations.premiumCard(
          isDark: isDarkMode,
          isViceMode: isViceMode,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: TugColors.getPrimaryColor(isViceMode),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: TugColors.getTextColor(isDarkMode, isViceMode),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _user!.bio!,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: TugColors.getTextColor(isDarkMode, isViceMode),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isDarkMode, bool isViceMode) {
    return QuantumEffects.floating(
      offset: 4,
      child: Container(
        width: double.infinity,
        decoration: TugDecorations.premiumCard(
          isDark: isDarkMode,
          isViceMode: isViceMode,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: TugColors.getPrimaryColor(isViceMode),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: TugColors.getTextColor(isDarkMode, isViceMode),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: _buildStatItem(
                'Total Activity Hours',
                _loadingStats ? '...' : '$_totalActivityHours',
                Icons.schedule,
                isDarkMode,
                isViceMode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isDarkMode, bool isViceMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TugColors.getSurfaceColor(isDarkMode, isViceMode).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: TugColors.getPrimaryColor(isViceMode),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: TugColors.getTextColor(isDarkMode, isViceMode),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}