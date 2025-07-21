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
import '../../services/vice_service.dart';
import '../../services/app_mode_service.dart';
import '../../utils/quantum_effects.dart';
import '../../utils/loading_messages.dart';
import '../../widgets/home/swipeable_charts.dart';
import '../../services/mood_service.dart';
import '../../models/mood_model.dart';
import '../../widgets/home/item_list_section.dart';
import '../../widgets/home/empty_state.dart';
import '../../models/value_model.dart';
import '../../models/vice_model.dart';
import '../../models/indulgence_model.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../utils/theme/colors.dart';
import '../../widgets/vices/weekly_vices_chart.dart';

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
  final ViceService _viceService = ViceService();
  final AppModeService _appModeService = AppModeService();
  final MoodService _moodService = MoodService();
  AppMode _currentMode = AppMode.valuesMode;
  List<MoodEntry> _moodEntries = [];
  List<IndulgenceModel> _weeklyIndulgences = [];
  
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
        
        // Load vices for vice mode with enhanced caching
        context.read<VicesBloc>().add(const LoadVices());
        
        // Load mood entries for mood chart
        _loadMoodEntries();
        
        // Load weekly indulgences for vices chart
        _loadWeeklyIndulgences();
      }
    });
    
    // Preload progress screen data in background for faster navigation
    _preloadProgressData();
    
    // Preload vices data for faster mode switching
    _preloadVicesData();
    
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
      // Silent failure for preload optimization
    }
  }

  // Preload vices data for faster mode switching
  Future<void> _preloadVicesData() async {
    try {
      // Preload vices in background for smoother experience
      await _viceService.preloadVicesData();
      
      // Also preload vice-related statistics if in vices mode
      if (_currentMode == AppMode.vicesMode) {
        await _cacheService.set(
          'vice_statistics_preloaded', 
          true, 
          memoryCacheDuration: const Duration(minutes: 5),
        );
      }
      
    } catch (e) {
      // Silent failure for preload optimization
    }
  }

  // Load mood entries for chart
  Future<void> _loadMoodEntries() async {
    print('DEBUG: Starting _loadMoodEntries()');
    try {
      final moodEntries = await _moodService.getMoodEntries();
      print('DEBUG: Received ${moodEntries.length} mood entries from service');
      if (mounted) {
        setState(() {
          _moodEntries = moodEntries;
        });
        print('DEBUG: Updated state with ${moodEntries.length} mood entries');
        if (moodEntries.isNotEmpty) {
          final recent = moodEntries.take(3);
          for (final entry in recent) {
            print('  - ${entry.moodType.name}: ${entry.positivityScore} (activityId: ${entry.activityId}, recorded: ${entry.recordedAt})');
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error loading mood entries: $e');
      // Silent failure - mood chart will show empty state
    }
  }

  // Quick helper to add sample mood entries for existing activities
  Future<void> _addSampleMoodEntries() async {
    print('DEBUG: Adding sample mood entries for existing activities');
    
    // Get recent activities from the bloc
    final activitiesState = context.read<ActivitiesBloc>().state;
    if (activitiesState is ActivitiesLoaded) {
      final recentActivities = activitiesState.activities.take(5).toList();
      
      final sampleMoods = [
        MoodType.confident,
        MoodType.joyful,
        MoodType.content,
        MoodType.frustrated,
        MoodType.focused,
      ];
      
      final moodPairs = <Map<String, dynamic>>[];
      
      for (int i = 0; i < recentActivities.length && i < sampleMoods.length; i++) {
        final activity = recentActivities[i];
        if (activity.id != null) {
          moodPairs.add({
            'activityId': activity.id!,
            'moodType': sampleMoods[i],
            'recordedAt': activity.date,
          });
        }
      }
      
      if (moodPairs.isNotEmpty) {
        await _moodService.createRetroactiveMoodEntries(moodPairs);
        // Refresh mood entries after adding
        _loadMoodEntries();
      }
    }
  }

  // Load weekly indulgences for vices chart
  Future<void> _loadWeeklyIndulgences() async {
    try {
      final weeklyIndulgences = await _viceService.getWeeklyIndulgences();
      if (mounted) {
        setState(() {
          _weeklyIndulgences = weeklyIndulgences;
        });
      }
    } catch (e) {
      // Silent failure - chart will show empty state
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
    // Clear all caches before refreshing
    try {
      await _cacheService.clearByPrefix('activities');
      await _cacheService.clearByPrefix('values');
      await _viceService.clearAllCache();
    } catch (e) {
      // Cache clear failed - not critical, continue with refresh
    }
    
    // Force a fresh load from the server for values, vices, and activities
    context.read<ValuesBloc>().add(const LoadValues(forceRefresh: true));
    context.read<VicesBloc>().add(const LoadVices(forceRefresh: true));
    context.read<ActivitiesBloc>().add(const LoadActivities(forceRefresh: true));
    
    // Refresh mood entries for mood chart
    _loadMoodEntries();
    
    // Refresh weekly indulgences for vices chart
    _loadWeeklyIndulgences();
    
    // Add a small delay to ensure the refresh indicator shows
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    // Call super for AutomaticKeepAliveClientMixin
    super.build(context);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Get current user from AuthBloc for personalized greeting
    final authState = context.watch<AuthBloc>().state;
    String greeting = 'hello';
    
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
                      ? [TugColors.darkBackground, TugColors.viceGreenDark, TugColors.viceGreen]
                      : [TugColors.lightBackground, TugColors.viceGreen.withValues(alpha: 0.08)])
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
                ? (isDarkMode ? [TugColors.viceGreen, TugColors.viceEmerald, TugColors.viceGreenDark] : [TugColors.viceGreen, TugColors.viceEmerald])
                : (isDarkMode ? [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark] : [TugColors.primaryPurple, TugColors.primaryPurpleLight]),
          ),
        ),
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
                        Color.lerp(TugColors.darkBackground, TugColors.viceGreen, 0.05) ?? TugColors.darkBackground,
                      ] 
                    : [
                        TugColors.lightBackground,
                        Color.lerp(TugColors.lightBackground, TugColors.viceGreen, 0.03) ?? TugColors.lightBackground,
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
                        // Swipeable Charts (Activity & Mood)
                        BlocListener<ActivitiesBloc, ActivitiesState>(
                          listener: (context, state) {
                            print('DEBUG: BlocListener received state: ${state.runtimeType}');
                            // Refresh mood entries when activities are updated
                            if (state is ActivityOperationSuccess) {
                              print('DEBUG: ActivityOperationSuccess - refreshing mood entries');
                              _loadMoodEntries();
                            }
                          },
                          child: BlocBuilder<ActivitiesBloc, ActivitiesState>(
                            builder: (context, activityState) {
                              if (activityState is ActivitiesLoaded) {
                                return SwipeableCharts(
                                  activities: activityState.activities,
                                  values: values,
                                  moodEntries: _moodEntries,
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
                        
                        // Feature Cards Section with Premium Styling
                        _buildSettingsSection(
                          title: 'features',
                          items: [
                            _buildFeatureSettingsItem(
                              icon: Icons.history,
                              title: 'activity tracking',
                              subtitle: 'time spent on your values, don\'t be lying',
                              onTap: () {
                                context.go('/activities');
                              },
                            ),
                            _buildFeatureSettingsItem(
                              icon: Icons.insights,
                              title: 'progress',
                              subtitle: 'see how you\'re doing',
                              onTap: () {
                                context.go('/progress');
                              },
                            ),
                            _buildFeatureSettingsItem(
                              icon: Icons.leaderboard,
                              title: 'leaderboard',
                              subtitle: 'see who\'s most active',
                              onTap: () {
                                context.push('/rankings');
                              },
                            ),
                          ],
                        ),
                        
                        // Debug: Temporary button to add sample moods to existing activities
                        if (_moodEntries.isEmpty) ...[
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _addSampleMoodEntries,
                              icon: const Icon(Icons.psychology),
                              label: const Text('Add Sample Moods to Recent Activities'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This will add sample moods to your last 5 activities for testing',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        
                        // Extra spacing for tab bar
                        const SizedBox(height: 80),
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
                          // Weekly Vices Bar Chart
                          WeeklyVicesChart(
                            vices: vices,
                            weeklyIndulgences: _weeklyIndulgences,
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
                          
                          // Feature Cards Section with Premium Styling
                          _buildSettingsSection(
                            title: 'features',
                            items: [
                              _buildFeatureSettingsItem(
                                icon: Icons.spa_rounded,
                                title: 'indulgences',
                                subtitle: 'track your vices and monitor clean streaks',
                                onTap: () {
                                  context.go('/indulgence-tracking');
                                },
                              ),
                              _buildFeatureSettingsItem(
                                icon: Icons.insights,
                                title: 'progress',
                                subtitle: 'see how you\'re doing',
                                onTap: () {
                                  context.go('/progress');
                                },
                              ),
                              _buildFeatureSettingsItem(
                                icon: Icons.groups,
                                title: 'social',
                                subtitle: 'connect with others on similar journeys',
                                onTap: () {
                                  context.go('/social');
                                },
                              ),
                            ],
                          ),
                          
                          // Extra spacing for tab bar
                          const SizedBox(height: 80),
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

  // Helper methods for premium styling from profile screen
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

  Widget _buildFeatureSettingsItem({
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

}