// lib/widgets/values/streak_overview_widget.dart
import 'package:flutter/material.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/theme/colors.dart';

class StreakOverviewWidget extends StatelessWidget {
  final List<ValueModel> values;

  const StreakOverviewWidget({
    super.key,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox();
    }

    // Filter values with active streaks (current streak > 0)
    final valuesWithStreaks = values.where((v) => v.currentStreak > 0).toList();
    
    if (valuesWithStreaks.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Streaks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No active streaks yet. Log activities daily to build your streaks!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Find the value with the highest current streak
    ValueModel topStreakValue = valuesWithStreaks.reduce(
        (a, b) => a.currentStreak > b.currentStreak ? a : b);
    
    // Find the value with the highest longest streak
    ValueModel topLongestStreakValue = values.reduce(
        (a, b) => a.longestStreak > b.longestStreak ? a : b);
    
    // Calculate total active streaks
    int totalActiveStreaks = valuesWithStreaks.length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Streaks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Top row with summary stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakSummaryItem(
                  context,
                  'Active Streaks',
                  '$totalActiveStreaks',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildStreakSummaryItem(
                  context,
                  'Top Streak',
                  '${topStreakValue.currentStreak} days',
                  Icons.emoji_events,
                  Colors.amber,
                ),
                _buildStreakSummaryItem(
                  context,
                  'Best Ever',
                  '${topLongestStreakValue.longestStreak} days',
                  Icons.military_tech,
                  Colors.deepPurple,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Current streaks listing
            Text(
              'Active Streaks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // List of active streaks
            ...valuesWithStreaks.map((value) => _buildStreakItem(context, value)).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStreakSummaryItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStreakItem(BuildContext context, ValueModel value) {
    final Color valueColor = Color(int.parse(value.color.substring(1), radix: 16) + 0xFF000000);
    
    // Calculate streak progress percentage compared to best streak
    final double progress = value.longestStreak > 0 
        ? (value.currentStreak / value.longestStreak) 
        : 1.0;
        
    // Clamp progress to max of 1.0
    final double clampedProgress = progress > 1.0 ? 1.0 : progress;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: valueColor.withOpacity(0.1),
        border: Border.all(
          color: valueColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: valueColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${value.currentStreak} ${value.currentStreak == 1 ? 'day' : 'days'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: clampedProgress,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: valueColor,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Best: ${value.longestStreak}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}