// lib/screens/progress/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/services/activity_service.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/widgets/tug_of_war/tug_of_war_widget.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedTimeframe = 'Daily';
  final List<String> _timeframes = ['Daily', 'Weekly', 'Monthly'];

  bool _isLoading = false;
  bool _isFirstLoad = true;
  Map<String, Map<String, dynamic>> _activityData = {};
  Map<String, dynamic>? _statistics;

  final ActivityService _activityService = ActivityService();

  @override
  void initState() {
    super.initState();
    // Load values without forcing refresh if we have cached data
    context.read<ValuesBloc>().add(LoadValues(forceRefresh: false));
    // Also load activity data
    _fetchActivityData(forceRefresh: false);
  }

  // Implement wantKeepAlive for AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  Future<void> _fetchActivityData({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Only show loading indicator on first load or forced refresh
    setState(() {
      if (_isFirstLoad || forceRefresh) {
        _isLoading = true;
      }
    });

    try {
      // Get current date and time
      final DateTime currentDate = DateTime.now();

      // Use the timeframe selector to determine the start date
      final DateTime startDate = getStartDate(_selectedTimeframe);

      // End date is today
      final DateTime endDate = currentDate;

      // Try to fetch activity statistics, but handle failure gracefully
      Map<String, dynamic>? statistics;
      try {
        statistics = await _activityService.getActivityStatistics(
          startDate: startDate,
          endDate: endDate,
          forceRefresh: forceRefresh,
        );
      } catch (e) {
        debugPrint('Error fetching statistics: $e');
        statistics = {
          "total_activities": 0,
          "total_duration_minutes": 0,
          "total_duration_hours": 0.0,
          "average_duration_minutes": 0.0
        };
      }

      // Try to fetch the summary data, but handle failure gracefully
      Map<String, dynamic> summary;
      try {
        summary = await _activityService.getActivitySummary(
          startDate: startDate,
          endDate: endDate,
          forceRefresh: forceRefresh,
        );
      } catch (e) {
        debugPrint('Error fetching summary: $e');
        summary = {"values": []};
      }

      // Process the summary data into the format we need
      final Map<String, Map<String, dynamic>> processedData = {};

      if (summary['values'] is List) {
        for (final value in summary['values']) {
          if (value is Map<String, dynamic> && value['name'] != null) {
            processedData[value['name']] = {
              'minutes': value['minutes'] ?? 0,
              'community_avg': value['community_avg'] ?? 60,
            };
          }
        }
      }

      if (mounted) {
        setState(() {
          _activityData = processedData;
          _statistics = statistics;
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching activity data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFirstLoad = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Could not load activity data. Please try again later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Add a refresh method to force reload from server
  void _refreshData() {
    _fetchActivityData(forceRefresh: true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing data...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  DateTime getStartDate(String timeframe) {
    final now = DateTime.now();
    switch (timeframe) {
      case 'Daily':
        return DateTime(now.year, now.month, now.day); // Start of today
      case 'Weekly':
        return now.subtract(const Duration(days: 7));
      case 'Monthly':
        return now.subtract(const Duration(days: 30));
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  int _calculateTotalTime(List<dynamic> values) {
    int total = 0;
    for (final value in values) {
      final activityData = _activityData[value.name];
      if (activityData != null) {
        total += activityData['minutes'] as int;
      }
    }
    return total;
  }

  String _calculateAlignment(List<dynamic> values) {
    if (values.isEmpty) return 'N/A';

    int alignedCount = 0;
    for (final value in values) {
      final activityData = _activityData[value.name];
      if (activityData != null) {
        final minutes = activityData['minutes'] as int;
        final communityAvg = activityData['community_avg'] as int;

        // Convert stated importance to percentage
        final statedImportancePercent = (value.importance / 5) * 100;

        // Calculate actual behavior as percentage of community average
        final actualBehaviorPercent = (minutes / communityAvg) * 100;

        // Calculate difference
        final difference =
            (actualBehaviorPercent - statedImportancePercent).abs();

        // Count as aligned if within 30% difference
        if (difference <= 30) {
          alignedCount++;
        }
      }
    }

    final percentage =
        values.isEmpty ? 0 : (alignedCount / values.length) * 100;
    return '${percentage.round()}%';
  }

  String _generateInsight(List<dynamic> values) {
    // Find most and least aligned values
    dynamic mostAligned;
    dynamic leastAligned;
    double mostAlignedDiff = double.infinity;
    double leastAlignedDiff = -1;

    for (final value in values) {
      final activityData = _activityData[value.name];
      if (activityData != null) {
        final minutes = activityData['minutes'] as int;
        final communityAvg = activityData['community_avg'] as int;

        final statedImportancePercent = (value.importance / 5) * 100;
        final actualBehaviorPercent = (minutes / communityAvg) * 100;
        final difference =
            (actualBehaviorPercent - statedImportancePercent).abs();

        if (difference < mostAlignedDiff) {
          mostAlignedDiff = difference;
          mostAligned = value;
        }

        if (difference > leastAlignedDiff) {
          leastAlignedDiff = difference;
          leastAligned = value;
        }
      }
    }

    if (values.isEmpty) {
      return 'Add some values and we\'ll give you some super helpful advice.';
    }

    if (mostAligned != null && leastAligned != null) {
      final activityData = _activityData[leastAligned.name];
      if (activityData != null) {
        final minutes = activityData['minutes'] as int;
        final communityAvg = activityData['community_avg'] as int;

        if (minutes < communityAvg) {
          return 'Your "${mostAligned.name}" value is looking GOOD! Put some more time towards "${leastAligned.name}" if you\'re fr about it.';
        } else {
          return 'Your "${mostAligned.name}" value has a real nice tug! You\'re spending hella time on "${leastAligned.name}", just making sure you\'re all good with that';
        }
      }
    }

    return 'Tug some activities and we\'ll get you some fantastic insights.';
  }

  Widget _buildSummaryItem(
      BuildContext context, String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: TugColors.primaryPurple,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Must call super.build for AutomaticKeepAliveClientMixin
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
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
                  'Timeframe:',
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
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(timeframe),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedTimeframe = timeframe;
                                });
                                _fetchActivityData(forceRefresh: true);
                              }
                            },
                            selectedColor:
                                TugColors.primaryPurple.withOpacity(0.8),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : TugColors.secondaryTeal,
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : BlocBuilder<ValuesBloc, ValuesState>(
                    builder: (context, state) {
                      if (state is ValuesLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (state is ValuesError) {
                        return Center(
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
                                'Error loading values: ${state.message}',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  context
                                      .read<ValuesBloc>()
                                      .add(LoadValues(forceRefresh: true));
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is ValuesLoaded) {
                        final values =
                            state.values.where((v) => v.active).toList();

                        if (values.isEmpty) {
                          return const Center(
                            child: Text('Hello? Values? Add some!'),
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Overall progress summary card
                            Card(
                              margin: const EdgeInsets.only(bottom: 24),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_selectedTimeframe Summary',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildSummaryItem(
                                          context,
                                          'Total Time',
                                          _statistics != null
                                              ? '${_statistics!['total_duration_minutes'] ?? 0} mins'
                                              : '${_calculateTotalTime(values)} mins',
                                          Icons.access_time,
                                        ),
                                        _buildSummaryItem(
                                          context,
                                          'Values',
                                          values.length.toString(),
                                          Icons.star,
                                        ),
                                        _buildSummaryItem(
                                          context,
                                          'Alignment',
                                          _calculateAlignment(values),
                                          Icons.balance,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Title for tug of war visualizations
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8, left: 4),
                              child: Text(
                                'Value Alignment',
                                style: Theme.of(context).textTheme.titleMedium,
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
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: TugOfWarWidget(
                                    valueName: value.name,
                                    statedImportance: value.importance,
                                    actualBehavior:
                                        activityData['minutes'] as int,
                                    communityAverage:
                                        activityData['community_avg'] as int,
                                    valueColor:
                                        value.color, // Pass the value's color
                                  ));
                            }).toList(),

                            const SizedBox(height: 16),

                            // Insight card
                            Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.lightbulb,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Insight',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(_generateInsight(values)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return const Center(
                        child: Text('No data available'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
