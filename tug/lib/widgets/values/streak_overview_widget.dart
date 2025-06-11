// lib/widgets/values/streak_overview_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/theme/colors.dart';

class StreakOverviewWidget extends StatelessWidget {
  final List<ValueModel> values;
  final VoidCallback? onRefresh;
  final bool showDetails;

  const StreakOverviewWidget({
    super.key,
    required this.values,
    this.onRefresh,
    this.showDetails = true,
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
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'streaks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (onRefresh != null)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        onRefresh!();
                        context.read<ValuesBloc>().add(
                          const LoadStreakStats(forceRefresh: true),
                        );
                      },
                      tooltip: 'refresh streak data',
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

    // Calculate total streak days across all values
    int totalStreakDays = valuesWithStreaks.fold(
        0, (sum, value) => sum + value.currentStreak);

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
          context.read<ValuesBloc>().add(const LoadStreakStats(forceRefresh: true));
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
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'streaks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (onRefresh != null)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          onRefresh!();
                          context.read<ValuesBloc>().add(
                            const LoadStreakStats(forceRefresh: true),
                          );
                        },
                        tooltip: 'refresh streak data',
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
                        'active streaks',
                        '$totalActiveStreaks',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        context,
                        'top streak',
                        '${topStreakValue.currentStreak} days',
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        context,
                        'total days',
                        '$totalStreakDays',
                        Icons.calendar_today,
                        TugColors.primaryPurple,
                      ),
                    ),
                  ],
                ),

                if (showDetails) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Top streaks list
                  Text(
                    'your streaks',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Streaks list - showing sorted values with longest streaks first
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: valuesWithStreaks.length,
                    separatorBuilder: (context, index) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      // Sort values by streak length (descending)
                      final sortedValues = List<ValueModel>.from(valuesWithStreaks)
                        ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
                      final value = sortedValues[index];
                      return _buildStreakItem(context, value);
                    },
                  ),
                ],
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
                  const Icon(
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