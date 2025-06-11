// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/activities/activities_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/services/cache_service.dart';
import 'package:tug/services/activity_service.dart';
import 'package:tug/utils/quantum_effects.dart';
import 'package:tug/utils/loading_messages.dart';
import 'package:tug/widgets/home/activity_chart.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/buttons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isFirstLoad = true;
  final CacheService _cacheService = CacheService();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize cache service first
    _initializeCache();
    
    // Load values when screen is initialized, but don't force refresh
    // if we already have cached values
    context.read<ValuesBloc>().add(const LoadValues(forceRefresh: false));
    
    // Load activities for the chart
    context.read<ActivitiesBloc>().add(const LoadActivities(forceRefresh: false));
    
    // Preload progress screen data in background for faster navigation
    _preloadProgressData();
    
    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Start animation
    _animationController.forward();
  }

  Future<void> _initializeCache() async {
    try {
      await _cacheService.initialize();
    } catch (e) {
    }
  }

  // Preload progress screen data in the background to improve navigation performance
  Future<void> _preloadProgressData() async {
    try {
      // Wait a bit to let the home screen load first
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Import activity service for preloading
      final activityService = ActivityService();
      final now = DateTime.now();
      
      // Preload daily data (most commonly accessed)
      final startDate = DateTime(now.year, now.month, now.day);
      
      // These calls will cache the data, making progress screen load faster
      await Future.wait([
        activityService.getActivityStatistics(
          startDate: startDate,
          endDate: now,
          forceRefresh: false,
        ).catchError((e) {
          return <String, dynamic>{};
        }),
        activityService.getActivitySummary(
          startDate: startDate,
          endDate: now,
          forceRefresh: false,
        ).catchError((e) {
          return <String, dynamic>{};
        }),
      ]);
      
    } catch (e) {
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // For AutomaticKeepAliveClientMixin - prevents the state from being disposed
  // when the tab is not visible, which helps maintain our cache
  @override
  bool get wantKeepAlive => true;

  // Navigate to values edit with return flag
  void _navigateToValuesEdit() {
    // Pass a parameter to indicate we should show a back button
    context.push('/values-input?fromHome=true');
  }
  
  void _refreshValues() {
    // Force a fresh load from the server
    context.read<ValuesBloc>().add(const LoadValues(forceRefresh: true));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('refreshing...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Call super for AutomaticKeepAliveClientMixin
    super.build(context);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Get current user from AuthBloc
    final authState = context.watch<AuthBloc>().state;
    String greeting = 'welcome';
    
    if (authState is Authenticated) {
      final displayName = authState.user.displayName;
      final email = authState.user.email;
      
      if (displayName != null && displayName.isNotEmpty) {
        greeting = 'hello, ${displayName.split(' ')[0]}';
      } else if (email != null && email.isNotEmpty) {
        // Use the part before @ in the email if no display name
        greeting = 'hello, ${email.split('@')[0]}';
      }
    }
    
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
            greeting,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            colors: isDarkMode ? [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark] : [TugColors.primaryPurple, TugColors.primaryPurpleLight],
          ),
        ),
        actions: [
          QuantumEffects.floating(
            offset: 3,
            child: QuantumEffects.quantumBorder(
              glowColor: TugColors.info,
              intensity: 0.6,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      TugColors.info.withAlpha(40),
                      TugColors.info.withAlpha(10),
                    ],
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.refresh, color: TugColors.info),
                  onPressed: _refreshValues,
                  tooltip: 'refresh values',
                ),
              ),
            ),
          ),
          QuantumEffects.floating(
            offset: 5,
            child: QuantumEffects.quantumBorder(
              glowColor: TugColors.error,
              intensity: 0.8,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      TugColors.error.withAlpha(40),
                      TugColors.error.withAlpha(10),
                    ],
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.logout, color: TugColors.error),
                  onPressed: _showLogoutConfirmation,
                  tooltip: 'logout',
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
                ? [
                    TugColors.darkBackground,
                    Color.lerp(TugColors.darkBackground, TugColors.primaryPurple, 0.05) ?? TugColors.darkBackground,
                  ] 
                : [
                    TugColors.lightBackground,
                    Color.lerp(TugColors.lightBackground, TugColors.primaryPurple, 0.03) ?? TugColors.lightBackground,
                  ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: BlocBuilder<ValuesBloc, ValuesState>(
            builder: (context, state) {
              if (state is ValuesLoading && _isFirstLoad) {
                // Only show loading indicator on first load
                _isFirstLoad = false;
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        LoadingMessages.getValues(),
                        style: TextStyle(
                          color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              if (state is ValuesError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshValues,
                        child: const Text('retry'),
                      ),
                    ],
                  ),
                );
              }
              
              // We're no longer on first load
              _isFirstLoad = false;
              
              if (state is ValuesLoaded) {
                final values = state.values.where((v) => v.active).toList();
                
                if (values.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_border_rounded,
                          size: 64,
                          color: TugColors.primaryPurple.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'no values defined yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'needa add some values',
                          style: TextStyle(
                            color: isDarkMode 
                                ? TugColors.darkTextSecondary 
                                : TugColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: TugButtons.primaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                          onPressed: _navigateToValuesEdit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('add values'),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Use SingleChildScrollView to make the entire screen scrollable
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(), 
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Activity Chart
                        BlocBuilder<ActivitiesBloc, ActivitiesState>(
                          builder: (context, activityState) {
                            if (activityState is ActivitiesLoaded) {
                              return ActivityChart(
                                activities: activityState.activities,
                                values: values, // Pass the current values
                              );
                            } else if (activityState is ActivitiesLoading) {
                              return _buildLoadingChart(context);
                            } else if (activityState is ActivitiesError) {
                              return _buildErrorChart(context, activityState.message);
                            } else {
                              return _buildEmptyChart(context);
                            }
                          },
                        ),
                        
                        // Values List
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'your values',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _navigateToValuesEdit,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: TugColors.primaryPurple,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('edit values'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...values.map((value) {
                          final Color valueColor = Color(
                            int.parse(value.color.substring(1), radix: 16) + 0xFF000000,
                          );
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? TugColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode 
                                      ? Colors.black.withOpacity(0.2) 
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: isDarkMode 
                                    ? Colors.white.withOpacity(0.05) 
                                    : Colors.black.withOpacity(0.03),
                                width: 0.5,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: valueColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: valueColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: valueColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                value.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'importance: ${value.importance}',
                                style: TextStyle(
                                  color: isDarkMode 
                                      ? TugColors.darkTextSecondary 
                                      : TugColors.lightTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Star Icons based on importance
                                  ...List.generate(
                                    value.importance,
                                    (index) => Icon(
                                      Icons.star,
                                      size: 16,
                                      color: valueColor,
                                    ),
                                  ),
                                  ...List.generate(
                                    5 - value.importance,
                                    (index) => Icon(
                                      Icons.star_border,
                                      size: 16,
                                      color: valueColor.withOpacity(0.3),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: _navigateToValuesEdit,
                            ),
                          );
                        }),
                        
                        const SizedBox(height: 24),
                        
                        // Feature Cards Section
                        const Text(
                          'features',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Activity Tracking Card
                        GestureDetector(
                          onTap: () {
                            context.go('/activities');
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDarkMode ? TugColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode 
                                      ? Colors.black.withOpacity(0.2) 
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: isDarkMode 
                                    ? Colors.white.withOpacity(0.05) 
                                    : Colors.black.withOpacity(0.03),
                                width: 0.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.2 : 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.3 : 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.history,
                                      color: TugColors.primaryPurple,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'activity tracking',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'time spent on your values, don\'t be lying',
                                          style: TextStyle(
                                            color: isDarkMode 
                                                ? TugColors.darkTextSecondary 
                                                : TugColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.1 : 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.chevron_right,
                                        color: TugColors.primaryPurple,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Progress Tracking Card
                        GestureDetector(
                          onTap: () {
                            context.go('/progress');
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDarkMode ? TugColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode 
                                      ? Colors.black.withOpacity(0.2) 
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: isDarkMode 
                                    ? Colors.white.withOpacity(0.05) 
                                    : Colors.black.withOpacity(0.03),
                                width: 0.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: TugColors.info.withOpacity(isDarkMode ? 0.2 : 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: TugColors.info.withOpacity(isDarkMode ? 0.3 : 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.insights,
                                      color: TugColors.info,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'progress',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'see how you\'re doing',
                                          style: TextStyle(
                                            color: isDarkMode 
                                                ? TugColors.darkTextSecondary 
                                                : TugColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: TugColors.info.withOpacity(isDarkMode ? 0.1 : 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.chevron_right,
                                        color: TugColors.info,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Leaderboard Card
                        GestureDetector(
                          onTap: () {
                            context.push('/rankings');
                          },
                          child: Container(
                            key: const Key('leaderboardCard'),
                            // Add large bottom margin to ensure visibility
                            margin: const EdgeInsets.only(bottom: 80),
                            decoration: BoxDecoration(
                              color: isDarkMode ? TugColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode 
                                      ? Colors.black.withOpacity(0.2) 
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: isDarkMode 
                                    ? Colors.white.withOpacity(0.05) 
                                    : Colors.black.withOpacity(0.03),
                                width: 0.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.2 : 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.3 : 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.leaderboard,
                                      color: TugColors.primaryPurple,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'leaderboard',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'see who\'s most active',
                                          style: TextStyle(
                                            color: isDarkMode 
                                                ? TugColors.darkTextSecondary 
                                                : TugColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.1 : 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.chevron_right,
                                        color: TugColors.primaryPurple,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return const Center(
                child: Text('Loading values...'),
              );
            },
          ),
        ),
      ),
    );
  }
  
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('logout'),
        content: const Text('deadass?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: TugColors.error),
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
  
  // Helper methods for the activity chart states
  Widget _buildLoadingChart(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TugColors.primaryPurple.withOpacity(isDarkMode ? 0.9 : 0.8),
            TugColors.primaryPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.4 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              LoadingMessages.getActivities(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorChart(BuildContext context, String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TugColors.primaryPurple.withOpacity(isDarkMode ? 0.9 : 0.8),
            TugColors.primaryPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.4 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              'error loading activities',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                context.read<ActivitiesBloc>().add(const LoadActivities(forceRefresh: true));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: TugColors.primaryPurple,
              ),
              child: const Text('retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyChart(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // We don't need to create an empty values list as the chart is handled by the container
    
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TugColors.primaryPurple.withOpacity(isDarkMode ? 0.9 : 0.8),
            TugColors.primaryPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.4 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 16),
            const Text(
              'no activities yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'log your first activity to see your progress chart',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.go('/activities/new');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: TugColors.primaryPurple,
              ),
              child: const Text('log activity'),
            ),
          ],
        ),
      ),
    );
  }
}