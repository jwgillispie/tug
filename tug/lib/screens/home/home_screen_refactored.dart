// lib/screens/home/home_screen_refactored.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

// Bloc imports
import '../../blocs/activities/activities_bloc.dart';
import '../../blocs/values/bloc/values_bloc.dart';
import '../../blocs/values/bloc/values_event.dart';
import '../../blocs/values/bloc/values_state.dart';
import '../../blocs/vices/bloc/vices_bloc.dart';
import '../../blocs/vices/bloc/vices_event.dart';
import '../../blocs/vices/bloc/vices_state.dart';
// Service imports
import '../../services/cache_service.dart';
import '../../services/activity_service.dart';
import '../../services/vice_service.dart';
import '../../services/app_mode_service.dart';
import '../../services/mood_service.dart';

// Model imports
import '../../models/mood_model.dart';
import '../../models/vice_model.dart';
import '../../models/indulgence_model.dart';
import '../../models/value_model.dart';
import '../../models/activity_model.dart';

// Widget imports - existing
import '../../widgets/home/swipeable_charts.dart';
import '../../widgets/vices/weekly_vices_chart.dart';

// New component imports
import '../../widgets/home/components/home_app_bar.dart';
import '../../widgets/home/components/home_loading_states.dart';
import '../../widgets/home/components/home_feature_card.dart';
import '../../widgets/home/components/home_settings_section.dart';
import '../../widgets/battle/epic_balance_battle.dart';
import '../../widgets/battle/ai_battle_coach.dart';
import '../../widgets/battle/battle_leaderboards.dart';
import '../../services/balance_insights_service.dart';

// Utils
import '../../utils/theme/colors.dart';

class HomeScreenRefactored extends StatefulWidget {
  const HomeScreenRefactored({super.key});

  @override
  State<HomeScreenRefactored> createState() => _HomeScreenRefactoredState();
}

class _HomeScreenRefactoredState extends State<HomeScreenRefactored>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // Animation controller for screen transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Services
  final CacheService _cacheService = CacheService();
  final ViceService _viceService = ViceService();
  final AppModeService _appModeService = AppModeService();
  final MoodService _moodService = MoodService();
  
  // State variables
  AppMode _currentMode = AppMode.valuesMode;
  List<MoodEntry> _moodEntries = [];
  List<IndulgenceModel> _weeklyIndulgences = [];
  final List<ActivityModel> _activities = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimation();
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize all required services
  Future<void> _initializeServices() async {
    await _initializeCache();
    await _initializeAppMode();
  }

  /// Setup fade animation for smooth transitions
  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
  }

  /// Load initial data after widget is mounted
  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBlocData();
        _loadMoodEntries();
        _loadWeeklyIndulgences();
        _preloadProgressData();
        _preloadVicesData();
      }
    });
  }

  /// Load data for all blocs
  void _loadBlocData() {
    context.read<ValuesBloc>().add(const LoadValues(forceRefresh: false));
    context.read<ActivitiesBloc>().add(const LoadActivities(forceRefresh: false));
    context.read<VicesBloc>().add(const LoadVices());
  }

  Future<void> _initializeCache() async {
    try {
      await _cacheService.initialize();
    } catch (e) {
      // Silent failure - cache is not critical
    }
  }

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

  Future<void> _loadMoodEntries() async {
    try {
      final entries = await _moodService.getMoodEntries(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _moodEntries = entries;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadWeeklyIndulgences() async {
    try {
      final indulgences = await _viceService.getWeeklyIndulgences();
      if (mounted) {
        setState(() {
          _weeklyIndulgences = indulgences;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _preloadProgressData() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      
      final activityService = ActivityService();
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      
      await activityService.getActivityStatistics(
        startDate: startDate,
        endDate: now,
        forceRefresh: false,
      ).catchError((e) => <String, dynamic>{});
    } catch (e) {
      // Silent failure
    }
  }

  Future<void> _preloadVicesData() async {
    try {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      
      await _viceService.getVices().catchError((e) => <ViceModel>[]);
    } catch (e) {
      // Silent failure
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;
    
    return Scaffold(
      appBar: HomeAppBar(currentMode: _currentMode),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 🎯 KILLER FEATURE: Balance Dashboard
              _buildBalanceDashboard(isDarkMode, isViceMode),
              
              // 🧠 AI BATTLE COACH
              _buildAIInsights(isDarkMode, isViceMode),
              
              // 🏆 BATTLE LEADERBOARDS
              _buildBattleLeaderboards(isDarkMode, isViceMode),
              
              // Charts section
              _buildChartsSection(isDarkMode, isViceMode),
              
              // Features section  
              _buildFeaturesSection(isDarkMode, isViceMode),
              
              // Settings section
              _buildSettingsSection(isDarkMode, isViceMode),
              
              // Bottom padding for navigation
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 COMPETITIVE ADVANTAGE: Balance Dashboard
  Widget _buildBalanceDashboard(bool isDarkMode, bool isViceMode) {
    return BlocBuilder<ValuesBloc, ValuesState>(
      builder: (context, valuesState) {
        return BlocBuilder<VicesBloc, VicesState>(
          builder: (context, vicesState) {
            return BlocBuilder<ActivitiesBloc, ActivitiesState>(
              builder: (context, activitiesState) {
                final values = valuesState is ValuesLoaded ? valuesState.values : <ValueModel>[];
                final vices = vicesState is VicesLoaded ? vicesState.vices : <ViceModel>[];
                final activities = activitiesState is ActivitiesLoaded ? activitiesState.activities : <ActivityModel>[];
                
                return EpicBalanceBattle(
                  values: values,
                  vices: vices,
                  recentActivities: activities,
                  recentIndulgences: _weeklyIndulgences,
                  daysToShow: 7,
                );
              },
            );
          },
        );
      },
    );
  }

  /// 🧠 AI-POWERED INSIGHTS: Unique to dual tracking
  Widget _buildAIInsights(bool isDarkMode, bool isViceMode) {
    return BlocBuilder<ValuesBloc, ValuesState>(
      builder: (context, valuesState) {
        return BlocBuilder<VicesBloc, VicesState>(
          builder: (context, vicesState) {
            return BlocBuilder<ActivitiesBloc, ActivitiesState>(
              builder: (context, activitiesState) {
                final values = valuesState is ValuesLoaded ? valuesState.values : <ValueModel>[];
                final vices = vicesState is VicesLoaded ? vicesState.vices : <ViceModel>[];
                final activities = activitiesState is ActivitiesLoaded ? activitiesState.activities : <ActivityModel>[];
                
                // Generate AI insights from balance data
                final insights = BalanceInsightsService.generateInsights(
                  activities: activities,
                  indulgences: _weeklyIndulgences,
                  values: values,
                  vices: vices,
                  moodEntries: _moodEntries,
                  daysToAnalyze: 30,
                );
                
                // Calculate current balance for coach
                final totalActivities = activities.length;
                final totalIndulgences = _weeklyIndulgences.length;
                final currentBalance = totalActivities + totalIndulgences > 0 
                    ? (totalActivities - totalIndulgences) / (totalActivities + totalIndulgences)
                    : 0.0;
                
                // Calculate battle streak
                int streak = 0;
                final now = DateTime.now();
                for (int i = 0; i < 30; i++) {
                  final checkDate = now.subtract(Duration(days: i));
                  final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
                  final dayEnd = dayStart.add(const Duration(days: 1));
                  
                  final dayActivities = activities.where((a) => 
                      a.date.isAfter(dayStart) && a.date.isBefore(dayEnd)).length;
                  final dayIndulgences = _weeklyIndulgences.where((i) => 
                      i.date.isAfter(dayStart) && i.date.isBefore(dayEnd)).length;
                  
                  if (dayActivities > dayIndulgences || (dayIndulgences == 0 && dayActivities >= 1)) {
                    streak++;
                  } else {
                    break;
                  }
                }
                
                // Determine battle phase
                String battlePhase = "preparation";
                if (currentBalance > 0.7) {
                  battlePhase = "victory";
                } else if (currentBalance < -0.7) {
                  battlePhase = "defeat";
                } else if (currentBalance.abs() > 0.3) {
                  battlePhase = "battle";
                } else if (currentBalance.abs() > 0.1) {
                  battlePhase = "skirmish";
                }
                
                // Calculate battle score for AI coach
                final battleScore = activities.isNotEmpty || _weeklyIndulgences.isNotEmpty
                    ? ((activities.length - _weeklyIndulgences.length) / 
                       (activities.length + _weeklyIndulgences.length + 1)).clamp(-1.0, 1.0)
                    : 0.0;
                
                return AIBattleCoach(
                  values: values,
                  vices: vices,
                  recentActivities: activities,
                  recentIndulgences: _weeklyIndulgences,
                  battleScore: battleScore,
                  winStreak: streak,
                  daysToShow: 7,
                );
              },
            );
          },
        );
      },
    );
  }

  /// 🏆 BATTLE LEADERBOARDS: Competitive social gaming
  Widget _buildBattleLeaderboards(bool isDarkMode, bool isViceMode) {
    return BlocBuilder<ValuesBloc, ValuesState>(
      builder: (context, valuesState) {
        return BlocBuilder<VicesBloc, VicesState>(
          builder: (context, vicesState) {
            return BlocBuilder<ActivitiesBloc, ActivitiesState>(
              builder: (context, activitiesState) {
                final values = valuesState is ValuesLoaded ? valuesState.values : <ValueModel>[];
                final vices = vicesState is VicesLoaded ? vicesState.vices : <ViceModel>[];
                final activities = activitiesState is ActivitiesLoaded ? activitiesState.activities : <ActivityModel>[];
                
                // Calculate battle score for leaderboards
                final battleScore = activities.isNotEmpty || _weeklyIndulgences.isNotEmpty
                    ? ((activities.length - _weeklyIndulgences.length) / 
                       (activities.length + _weeklyIndulgences.length + 1)).clamp(-1.0, 1.0)
                    : 0.0;
                
                // Calculate win streak
                final winStreak = math.max(0, activities.length - _weeklyIndulgences.length);
                
                return BattleLeaderboards(
                  values: values,
                  vices: vices,
                  recentActivities: activities,
                  recentIndulgences: _weeklyIndulgences,
                  personalBattleScore: battleScore,
                  personalWinStreak: winStreak,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChartsSection(bool isDarkMode, bool isViceMode) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: isViceMode 
          ? _buildViceChartsSection()
          : _buildValueChartsSection(),
    );
  }

  Widget _buildViceChartsSection() {
    return BlocBuilder<VicesBloc, VicesState>(
      builder: (context, state) {
        if (state is VicesLoading) {
          return HomeLoadingChart(isViceMode: true);
        } else if (state is VicesError) {
          return HomeErrorChart(
            message: state.message,
            isViceMode: true,
            onRetry: () => context.read<VicesBloc>().add(const LoadVices()),
          );
        } else if (state is VicesLoaded) {
          if (state.vices.isEmpty) {
            return HomeEmptyChart(
              isViceMode: true,
              onAddFirst: () => context.go('/vices-input'),
            );
          }
          return WeeklyVicesChart(
            vices: state.vices,
            weeklyIndulgences: _weeklyIndulgences,
          );
        }
        
        return HomeEmptyChart(isViceMode: true);
      },
    );
  }

  Widget _buildValueChartsSection() {
    return BlocBuilder<ValuesBloc, ValuesState>(
      builder: (context, state) {
        if (state is ValuesLoading) {
          return HomeLoadingChart(isViceMode: false);
        } else if (state is ValuesError) {
          return HomeErrorChart(
            message: state.message,
            isViceMode: false,
            onRetry: () => context.read<ValuesBloc>().add(const LoadValues()),
          );
        } else if (state is ValuesLoaded) {
          if (state.values.isEmpty) {
            return HomeEmptyChart(
              isViceMode: false,
              onAddFirst: () => context.go('/values-input'),
            );
          }
          
          // Get activities from ActivitiesBloc
          return BlocBuilder<ActivitiesBloc, ActivitiesState>(
            builder: (context, activitiesState) {
              final activities = activitiesState is ActivitiesLoaded 
                  ? activitiesState.activities 
                  : <ActivityModel>[];
              
              return SwipeableCharts(
                activities: activities,
                values: state.values,
                moodEntries: _moodEntries,
              );
            },
          );
        }
        
        return HomeEmptyChart(isViceMode: false);
      },
    );
  }

  Widget _buildFeaturesSection(bool isDarkMode, bool isViceMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          HomeFeatureCard(
            icon: Icons.trending_up,
            iconColor: TugColors.getPrimaryColor(isViceMode),
            title: isViceMode ? 'vice analytics' : 'progress analytics',
            subtitle: isViceMode 
                ? 'view detailed vice tracking insights'
                : 'view detailed progress insights',
            onTap: () => context.go('/progress'),
          ),
          
          HomeFeatureCard(
            icon: Icons.people,
            iconColor: TugColors.getPrimaryColor(isViceMode),
            title: 'social feed',
            subtitle: 'connect with friends and share your journey',
            onTap: () => context.go('/social'),
          ),
          
          HomeFeatureCard(
            icon: Icons.emoji_events,
            iconColor: Colors.amber,
            title: 'achievements',
            subtitle: 'view your milestones and earned badges',
            onTap: () => context.push('/achievements'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(bool isDarkMode, bool isViceMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: HomeSettingsSection(
        title: 'quick actions',
        currentMode: _currentMode,
        items: [
          HomeFeatureSettingsItem(
            icon: Icons.person,
            title: 'profile',
            description: 'manage your account and preferences',
            onTap: () => context.go('/profile'),
            isFirst: true,
            currentMode: _currentMode,
          ),
          
          HomeFeatureSettingsItem(
            icon: Icons.notifications,
            title: 'notifications',
            description: 'view recent updates and alerts',
            onTap: () => context.go('/notifications'),
            currentMode: _currentMode,
          ),
          
          HomeFeatureSettingsItem(
            icon: Icons.help,
            title: 'help & support',
            description: 'get help and contact support',
            onTap: () => context.go('/help'),
            isLast: true,
            currentMode: _currentMode,
          ),
        ],
      ),
    );
  }
}