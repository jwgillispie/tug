// lib/screens/progress/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bevent.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/widgets/tug_of_war/tug_of_war_widget.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedTimeframe = 'Daily';
  final List<String> _timeframes = ['Daily', 'Weekly', 'Monthly'];

  // Mock data for demonstration
  final Map<String, Map<String, dynamic>> _mockActivityData = {
    'Health': {'minutes': 45, 'community_avg': 60},
    'Family': {'minutes': 120, 'community_avg': 90},
    'Career': {'minutes': 360, 'community_avg': 300},
    'Learning': {'minutes': 30, 'community_avg': 60},
    'Creativity': {'minutes': 15, 'community_avg': 45},
  };

  @override
  void initState() {
    super.initState();
    // Load values when screen is initialized
    context.read<ValuesBloc>().add(LoadValues());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
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
                              }
                            },
                            selectedColor: TugColors.primaryPurple.withOpacity(0.8),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            child: BlocBuilder<ValuesBloc, ValuesState>(
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
                            context.read<ValuesBloc>().add(LoadValues());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (state is ValuesLoaded) {
                  final values = state.values.where((v) => v.active).toList();
                  
                  if (values.isEmpty) {
                    return const Center(
                      child: Text('No values defined yet. Add some values to track your progress.'),
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
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildSummaryItem(
                                    context,
                                    'Total Time',
                                    '${_calculateTotalTime(values)} mins',
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
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Text(
                          'Value Alignment',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      
                      // Tug of war visualizations for each value
                      ...values.map((value) {
                        // Get activity data from mock data
                        final activityData = _mockActivityData[value.name] ?? {
                          'minutes': 0,
                          'community_avg': 60,
                        };
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TugOfWarWidget(
                            valueName: value.name,
                            statedImportance: value.importance,
                            actualBehavior: activityData['minutes'],
                            communityAverage: activityData['community_avg'],
                          ),
                        );
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
                                    style: Theme.of(context).textTheme.titleMedium,
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
  
  // Helper methods for summary calculations
  int _calculateTotalTime(List<dynamic> values) {
    int total = 0;
    for (final value in values) {
      final activityData = _mockActivityData[value.name];
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
      final activityData = _mockActivityData[value.name];
      if (activityData != null) {
        final minutes = activityData['minutes'] as int;
        final communityAvg = activityData['community_avg'] as int;
        
        // Convert stated importance to percentage
        final statedImportancePercent = (value.importance / 5) * 100;
        
        // Calculate actual behavior as percentage of community average
        final actualBehaviorPercent = (minutes / communityAvg) * 100;
        
        // Calculate difference
        final difference = (actualBehaviorPercent - statedImportancePercent).abs();
        
        // Count as aligned if within 30% difference
        if (difference <= 30) {
          alignedCount++;
        }
      }
    }
    
    final percentage = (alignedCount / values.length) * 100;
    return '${percentage.round()}%';
  }
  
  String _generateInsight(List<dynamic> values) {
    // Find most and least aligned values
    dynamic mostAligned;
    dynamic leastAligned;
    double mostAlignedDiff = double.infinity;
    double leastAlignedDiff = -1;
    
    for (final value in values) {
      final activityData = _mockActivityData[value.name];
      if (activityData != null) {
        final minutes = activityData['minutes'] as int;
        final communityAvg = activityData['community_avg'] as int;
        
        final statedImportancePercent = (value.importance / 5) * 100;
        final actualBehaviorPercent = (minutes / communityAvg) * 100;
        final difference = (actualBehaviorPercent - statedImportancePercent).abs();
        
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
    
    if (mostAligned != null && leastAligned != null) {
      final activityData = _mockActivityData[leastAligned.name];
      if (activityData != null) {
        final minutes = activityData['minutes'] as int;
        final communityAvg = activityData['community_avg'] as int;
        
        if (minutes < communityAvg) {
          return 'Your "${mostAligned.name}" value shows great alignment! Consider dedicating more time to "${leastAligned.name}" to better reflect its importance to you.';
        } else {
          return 'Your "${mostAligned.name}" value shows great alignment! You\'re spending more time than average on "${leastAligned.name}", consider if this reflects its true importance to you.';
        }
      }
    }
    
    return 'Continue tracking your activities to get personalized insights about your value alignment.';
  }
  
  Widget _buildSummaryItem(BuildContext context, String title, String value, IconData icon) {
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
}