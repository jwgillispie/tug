// lib/screens/progress/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/services/activity_service.dart';
import 'package:tug/services/cache_service.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/quantum_effects.dart';
import 'package:tug/utils/loading_messages.dart';
import 'package:tug/widgets/tug_of_war/enhanced_tug_of_war_widget.dart';
import 'package:tug/widgets/values/streak_overview_widget.dart';
import 'package:tug/widgets/values/ai_insight_widget.dart';
import 'package:tug/utils/progress_calculator.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedTimeframe = 'daily';
  final List<String> _timeframes = ['daily', 'weekly', 'monthly'];

  bool _isLoading = false;
  bool _isFirstLoad = true;
  bool _isTimeframeLoading = false;
  Map<String, Map<String, dynamic>> _activityData = {};

  final ActivityService _activityService = ActivityService();
  final CacheService _cacheService = CacheService();

  @override
  void initState() {
    super.initState();
    // Initialize cache service and load only essential data
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    // Initialize services first
    await _initializeCache();
    
    // Load only values initially, delay other data until values are available
    if (mounted) {
      context.read<ValuesBloc>().add(LoadValues(forceRefresh: false));
      // Load activity data immediately in parallel
      _fetchActivityData(forceRefresh: false);
      
      // Pre-load other timeframes in background after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        _preloadTimeframes();
      });
    }
  }

  /// Pre-load other timeframes in the background for faster switching
  Future<void> _preloadTimeframes() async {
    if (!mounted) return;
    
    for (final timeframe in _timeframes) {
      if (timeframe != _selectedTimeframe) {
        // Pre-load in background without updating UI
        final originalTimeframe = _selectedTimeframe;
        _selectedTimeframe = timeframe;
        try {
          await _fetchActivityData(forceRefresh: false);
        } catch (e) {
          // Ignore errors in background loading
        }
        _selectedTimeframe = originalTimeframe;
      }
    }
  }

  Future<void> _initializeCache() async {
    try {
      await _cacheService.initialize();
    } catch (e) {
      // Cache initialization failed - not critical for functionality
    }
  }

  // Implement wantKeepAlive for AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  Future<void> _fetchActivityData({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Ensure values are loaded first
    final valuesState = context.read<ValuesBloc>().state;
    if (valuesState is! ValuesLoaded) {
      // Values not loaded yet, trigger loading and return
      context.read<ValuesBloc>().add(LoadValues(forceRefresh: true));
      return;
    }

    // Generate cache keys for this specific timeframe and data
    final startDate = getStartDate(_selectedTimeframe);
    final endDate = DateTime.now();
    final cacheKey = 'progress_data_${_selectedTimeframe}_${startDate.toIso8601String().split('T')[0]}_${endDate.toIso8601String().split('T')[0]}';

    // If not forcing refresh, try to load from cache first
    if (!forceRefresh) {
      try {
        final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null) {
          if (mounted) {
            setState(() {
              _activityData = Map<String, Map<String, dynamic>>.from(
                cachedData['activityData'] ?? {}
              );
              _isLoading = false;
              _isFirstLoad = false;
            });
          }
          return;
        }
      } catch (e) {
        // Failed to load cached data - will fetch fresh data instead
      }
    }

    // Only show loading indicator on first load or forced refresh
    setState(() {
      if (_isFirstLoad || forceRefresh) {
        _isLoading = true;
      }
    });

    try {
      // Fetch ALL activities to ensure we have current data
      final allActivities = await _activityService.getActivities(
        forceRefresh: forceRefresh,
      );

      // Get values from the ValuesBloc state (ensure mounted)
      if (!mounted) return;
      final valuesState = context.read<ValuesBloc>().state;
      if (valuesState is! ValuesLoaded) {
        throw Exception('Values not loaded');
      }
      
      final activeValues = valuesState.values.where((v) => v.active).toList();
      
      // Use the utility to calculate progress data
      final processedData = ProgressCalculator.calculateProgressData(
        values: activeValues,
        activities: allActivities,
        timeframe: _selectedTimeframe,
        startDate: startDate,
        endDate: endDate,
      );

      // Cache the combined data for faster subsequent loads
      // Use longer cache duration for weekly/monthly data since it changes less frequently
      final memoryCacheDuration = _selectedTimeframe == 'daily' 
          ? Duration(minutes: 5)
          : Duration(minutes: 30);
      final diskCacheDuration = _selectedTimeframe == 'daily'
          ? Duration(hours: 1)
          : Duration(hours: 6);

      try {
        await _cacheService.set(
          cacheKey,
          {
            'activityData': processedData,
            'timeframe': _selectedTimeframe,
            'startDate': startDate.toIso8601String(),
            'endDate': endDate.toIso8601String(),
          },
          memoryCacheDuration: memoryCacheDuration,
          diskCacheDuration: diskCacheDuration,
        );
      } catch (e) {
        // Cache save failed - not critical, continue
      }

      if (mounted) {
        setState(() {
          _activityData = processedData;
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFirstLoad = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('could not load activity data. please try again later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Add a refresh method to force reload from server
  Future<void> _refreshData() async {
    try {
      // Clear ALL cache entries before refreshing
      await _clearProgressCache();
      
      // Force clear activity cache as well
      try {
        await _cacheService.clearByPrefix('activities');
        await _cacheService.clearByPrefix('progress');
        await _cacheService.clearByPrefix('summary');
        await _cacheService.clearByPrefix('statistics');
      } catch (e) {
        // Cache clear failed - not critical
      }
      
      // Load values and activity data in parallel for faster refresh
      await Future.wait([
        Future(() {
          if (mounted) {
            context.read<ValuesBloc>().add(LoadValues(forceRefresh: true));
          }
        }),
        _fetchActivityData(forceRefresh: true),
      ]);
      
      // Load streak stats in background (non-blocking)
      if (mounted) {
        context.read<ValuesBloc>().add(LoadStreakStats(forceRefresh: true));
      }
    } catch (e) {
      // Silent fail - user will see individual error messages
    }
  }

  // Clear progress-specific cache entries
  Future<void> _clearProgressCache() async {
    try {
      // Clear our custom progress cache
      await _cacheService.clearByPrefix('progress_data_');
    } catch (e) {
      // Cache clear failed - not critical
    }
  }


  DateTime getStartDate(String timeframe) {
    final now = DateTime.now();
    switch (timeframe) {
      case 'daily':
        return DateTime(now.year, now.month, now.day); // Start of today
      case 'weekly':
        return now.subtract(const Duration(days: 7));
      case 'monthly':
        return now.subtract(const Duration(days: 30));
      default:
        return now.subtract(const Duration(days: 7));
    }
  }



  @override
  Widget build(BuildContext context) {
    // Must call super.build for AutomaticKeepAliveClientMixin
    super.build(context);
    
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
            'progress',
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeframe Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                const Text(
                  'timeframe:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _timeframes.map((timeframe) {
                        final isSelected = timeframe == _selectedTimeframe;
                        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: _isTimeframeLoading && timeframe == _selectedTimeframe
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isSelected ? Colors.white : Colors.grey,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(timeframe),
                                    ],
                                  )
                                : Text(timeframe),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedTimeframe = timeframe;
                                  _isTimeframeLoading = true;
                                });
                                // Load data immediately from cache, then refresh in background
                                _fetchActivityData(forceRefresh: false).then((_) {
                                  // If no cached data was found, force refresh
                                  if (_activityData.isEmpty) {
                                    _fetchActivityData(forceRefresh: true);
                                  }
                                  if (mounted) {
                                    setState(() {
                                      _isTimeframeLoading = false;
                                    });
                                  }
                                });
                              }
                            },
                            selectedColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade600,
                            backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : isDarkMode 
                                      ? Colors.grey.shade300 
                                      : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: _isLoading
                  ? ListView(
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                LoadingMessages.getProgress(),
                                style: TextStyle(
                                  color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : BlocBuilder<ValuesBloc, ValuesState>(
                    builder: (context, state) {
                      if (state is ValuesLoading) {
                        return ListView(
                          children: [
                            const SizedBox(height: 200),
                            Center(
                              child: Column(
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
                            ),
                          ],
                        );
                      }

                      if (state is ValuesError) {
                        return ListView(
                          children: [
                            const SizedBox(height: 200),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: TugColors.error,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'error loading values: ${state.message}',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'pull down to refresh',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      if (state is ValuesLoaded) {
                        final values =
                            state.values.where((v) => v.active).toList();

                        if (values.isEmpty) {
                          return ListView(
                            children: const [
                              SizedBox(height: 200),
                              Center(
                                child: Text('hello? values? add some!'),
                              ),
                            ],
                          );
                        }

                        // Trigger activity data fetch when values are loaded
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_activityData.isEmpty && !_isLoading) {
                            _fetchActivityData();
                          }
                        });

                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                            // Enhanced streak overview widget
                            StreakOverviewWidget(
                              values: values,
                              onRefresh: () {
                                // Force reload values and streak data
                                context.read<ValuesBloc>().add(LoadValues(forceRefresh: true));
                                context.read<ValuesBloc>().add(LoadStreakStats(forceRefresh: true));
                              },
                            ),

                            // Title for tug of war visualizations
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8, left: 4, top: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.balance,
                                    color: TugColors.primaryPurple,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'your tug',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),

                            // Tug of war visualizations for each value
                            ...values.map((value) {
                              // Get activity data
                              final activityData = _activityData[value.name] ??
                                  {
                                    'minutes': 0,
                                    'community_avg': 60,
                                  };

                              return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: EnhancedTugOfWarWidget(
                                    valueName: value.name,
                                    statedImportance: value.importance,
                                    actualBehavior:
                                        activityData['minutes'] as int,
                                    communityAverage:
                                        activityData['community_avg'] as int,
                                    valueColor:
                                        value.color, // Pass the value's color
                                    timeframe: _selectedTimeframe, // Pass the selected timeframe
                                  ));
                            }),

                            const SizedBox(height: 16),

                            // AI Insights section
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, left: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ai insights',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),

                            // Individual AI Insight Widgets for each value
                            ...values.map((value) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AIInsightWidget(
                                value: value,
                                timeframe: _selectedTimeframe,
                              ),
                            )),
                          ],
                          ),
                        );
                      }

                      if (state is StreakStatsLoaded) {
                        // Handle streak stats loaded state - this shouldn't normally be reached
                        // as streak stats are usually loaded along with values
                        return ListView(
                          children: [
                            const SizedBox(height: 200),
                            Center(
                              child: Column(
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
                            ),
                          ],
                        );
                      }

                      return ListView(
                        children: const [
                          SizedBox(height: 200),
                          Center(
                            child: Text('no data available'),
                          ),
                        ],
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
