// lib/widgets/values/simple_streak_widget.dart
import 'package:flutter/material.dart';
import 'package:tug/models/value_model.dart';

class SimpleStreakWidget extends StatelessWidget {
  final List<ValueModel> values;
  final VoidCallback? onRefresh;

  const SimpleStreakWidget({
    super.key,
    required this.values,
    this.onRefresh,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Streaks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (onRefresh != null)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: onRefresh,
                      tooltip: 'Refresh streak data',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'build your streaks!',
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

    // Calculate total active streaks
    int totalActiveStreaks = valuesWithStreaks.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          if (onRefresh != null) {
            onRefresh!();
          }
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Streaks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (onRefresh != null)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: onRefresh,
                        tooltip: 'Refresh streak data',
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Summary Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        context,
                        'Active Streaks',
                        '$totalActiveStreaks',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        context,
                        'Top Streak',
                        '${topStreakValue.currentStreak} days',
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Streaks list
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: valuesWithStreaks.length,
                  separatorBuilder: (context, index) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final value = valuesWithStreaks[index];
                    return _buildStreakItem(context, value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
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

    return Row(
      children: [
        // Value color indicator
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: valueColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),

        // Value name and streak count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${value.currentStreak} day${value.currentStreak == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (value.longestStreak > value.currentStreak) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '(Best: ${value.longestStreak})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),

              // Simple progress bar
              LinearProgressIndicator(
                value: clampedProgress,
                backgroundColor: Colors.grey.shade200,
                color: valueColor,
                minHeight: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}