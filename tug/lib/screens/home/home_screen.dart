// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/activities/activities_bloc.dart';
import '../../blocs/values/bloc/values_bloc.dart';
import '../../blocs/values/bloc/values_event.dart';
import '../../blocs/values/bloc/values_state.dart';
import '../../blocs/vices/bloc/vices_bloc.dart';
import '../../blocs/vices/bloc/vices_event.dart';
import '../../blocs/vices/bloc/vices_state.dart';
import '../../services/cache_service.dart';
import '../../services/activity_service.dart';
import '../../services/app_mode_service.dart';
import '../../utils/quantum_effects.dart';
import '../../utils/loading_messages.dart';
import '../../widgets/home/activity_chart.dart';
import '../../widgets/home/item_list_section.dart';
import '../../widgets/home/empty_state.dart';
import '../../models/value_model.dart';
import '../../models/vice_model.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../utils/theme/colors.dart';

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
  final AppModeService _appModeService = AppModeService();
  AppMode _currentMode = AppMode.valuesMode;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _initializeCache();
    _initializeAppMode();
    
    // Load bloc data after the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Load values when screen is initialized, but don't force refresh
        // if we already have cached values
        context.read<ValuesBloc>().add(const LoadValues(forceRefresh: false));
        
        // Load activities for the chart
        context.read<ActivitiesBloc>().add(const LoadActivities(forceRefresh: false));
        
        // Load vices for vice mode
        context.read<VicesBloc>().add(const LoadVices());
      }
    });
    
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
      // Silent failure - cache is not critical for app function
    }
  }

  // Initialize app mode service
  Future<void> _initializeAppMode() async {
    try {
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
    } catch (e) {
      // Silent failure - default to values mode
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

  // Navigate to vices edit with return flag
  void _navigateToVicesEdit() {
    // Pass a parameter to indicate we should show a back button
    context.push('/vices-input?fromHome=true');
  }
  
  Future<void> _refreshData() async {
    // Force a fresh load from the server for values, vices, and activities
    context.read<ValuesBloc>().add(const LoadValues(forceRefresh: true));
    context.read<VicesBloc>().add(const LoadVices());
    context.read<ActivitiesBloc>().add(const LoadActivities(forceRefresh: true));
    
    // Add a small delay to ensure the refresh indicator shows
    await Future.delayed(const Duration(milliseconds: 500));
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
              colors: _currentMode == AppMode.vicesMode
                  ? (isDarkMode 
                      ? [TugColors.darkBackground, TugColors.viceRedDark, TugColors.viceRed]
                      : [TugColors.lightBackground, TugColors.viceRed.withAlpha(20)])
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
            greeting,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            colors: _currentMode == AppMode.vicesMode
                ? (isDarkMode ? [TugColors.viceRed, TugColors.viceOrange, TugColors.viceRedDark] : [TugColors.viceRed, TugColors.viceOrange])
                : (isDarkMode ? [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark] : [TugColors.primaryPurple, TugColors.primaryPurpleLight]),
          ),
        ),
        actions: [
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
            colors: _currentMode == AppMode.vicesMode
                ? (isDarkMode 
                    ? [
                        TugColors.darkBackground,
                        Color.lerp(TugColors.darkBackground, TugColors.viceRed, 0.05) ?? TugColors.darkBackground,
                      ] 
                    : [
                        TugColors.lightBackground,
                        Color.lerp(TugColors.lightBackground, TugColors.viceRed, 0.03) ?? TugColors.lightBackground,
                      ])
                : (isDarkMode 
                    ? [
                        TugColors.darkBackground,
                        Color.lerp(TugColors.darkBackground, TugColors.primaryPurple, 0.05) ?? TugColors.darkBackground,
                      ] 
                    : [
                        TugColors.lightBackground,
                        Color.lerp(TugColors.lightBackground, TugColors.primaryPurple, 0.03) ?? TugColors.lightBackground,
                      ]),
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _currentMode == AppMode.valuesMode 
                ? BlocBuilder<ValuesBloc, ValuesState>(
              builder: (context, state) {
              if (state is ValuesLoading && _isFirstLoad) {
                // Only show loading indicator on first load
                _isFirstLoad = false;
                return LoadingState(
                  appMode: _currentMode,
                  message: LoadingMessages.getValues(),
                );
              }
              
              if (state is ValuesError) {
                return ErrorState(
                  appMode: _currentMode,
                  message: state.message,
                  onRetry: _refreshData,
                );
              }
              
              // We're no longer on first load
              _isFirstLoad = false;
              
              if (state is ValuesLoaded) {
                final values = state.values.where((v) => v.active).toList();
                
                if (values.isEmpty) {
                  return EmptyState(
                    appMode: _currentMode,
                    onAddPressed: _navigateToValuesEdit,
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
                        ItemListSection<ValueModel>(
                          title: 'your values',
                          editButtonText: 'edit values',
                          items: values,
                          onEditPressed: _navigateToValuesEdit,
                          onItemTap: _navigateToValuesEdit,
                          appMode: _currentMode,
                          isEmpty: false,
                          emptyStateWidget: const SizedBox.shrink(),
                        ),
                        
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
                child: Text('loading values...'),
              );
              },
            )
                : BlocBuilder<VicesBloc, VicesState>(
              builder: (context, state) {
                if (state is VicesLoading && _isFirstLoad) {
                  _isFirstLoad = false;
                  return LoadingState(
                    appMode: _currentMode,
                    message: 'loading vices...',
                  );
                }
                
                if (state is VicesError) {
                  return ErrorState(
                    appMode: _currentMode,
                    message: state.message,
                    onRetry: _refreshData,
                  );
                }
                
                if (state is VicesLoaded) {
                  final vices = state.vices;
                  
                  if (vices.isEmpty) {
                    return EmptyState(
                      appMode: _currentMode,
                      onAddPressed: _navigateToVicesEdit,
                    );
                  }
                  
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Activity Chart (same as values mode)
                          BlocBuilder<ActivitiesBloc, ActivitiesState>(
                            builder: (context, activityState) {
                              if (activityState is ActivitiesLoaded) {
                                return ActivityChart(
                                  activities: activityState.activities,
                                  values: [], // Empty values for vices mode
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
                          
                          const SizedBox(height: 24),
                          
                          // Vices List
                          ItemListSection<ViceModel>(
                            title: 'your vices',
                            editButtonText: 'edit vices',
                            items: vices,
                            onEditPressed: _navigateToVicesEdit,
                            onItemTap: _navigateToVicesEdit,
                            appMode: _currentMode,
                            isEmpty: false,
                            emptyStateWidget: const SizedBox.shrink(),
                          ),
                          
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
                          
                          // AI Counselor Card
                          GestureDetector(
                            onTap: () {
                              context.push('/ai-counselor');
                            },
                            child: _buildFeatureCard(
                              context,
                              isDarkMode,
                              icon: Icons.psychology,
                              iconColor: TugColors.viceRed,
                              title: 'ai counselor',
                              subtitle: 'talk through your challenges',
                            ),
                          ),
                          
                          // Progress Tracking Card
                          GestureDetector(
                            onTap: () {
                              context.go('/progress');
                            },
                            child: _buildFeatureCard(
                              context,
                              isDarkMode,
                              icon: Icons.insights,
                              iconColor: TugColors.info,
                              title: 'progress',
                              subtitle: 'see how you\'re doing',
                            ),
                          ),
                          
                          // Social Card
                          GestureDetector(
                            onTap: () {
                              context.go('/social');
                            },
                            child: _buildFeatureCard(
                              context,
                              isDarkMode,
                              icon: Icons.groups,
                              iconColor: TugColors.viceOrange,
                              title: 'social',
                              subtitle: 'connect with others on similar journeys',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return LoadingState(
                  appMode: _currentMode,
                  message: 'loading vices...',
                );
              },
            ),
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

  Widget _buildFeatureCard(
    BuildContext context,
    bool isDarkMode, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
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
                color: iconColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: iconColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
                color: iconColor.withOpacity(isDarkMode ? 0.1 : 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.chevron_right,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}