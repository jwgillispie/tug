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
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced section header with premium styling
          Padding(
            padding: const EdgeInsets.only(
              left: 24,
              right: 16,
              top: 32,
              bottom: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [TugColors.primaryPurple.withValues(alpha: 0.2), TugColors.primaryPurpleLight.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'STREAKS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: TugColors.primaryPurple,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (onRefresh != null)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [TugColors.primaryPurple.withValues(alpha: 0.1), TugColors.primaryPurpleLight.withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: TugColors.primaryPurple,
                        size: 20,
                      ),
                      onPressed: () {
                        onRefresh!();
                        context.read<ValuesBloc>().add(
                          const LoadStreakStats(forceRefresh: true),
                        );
                      },
                      tooltip: 'refresh streak data',
                    ),
                  ),
              ],
            ),
          ),
          // Enhanced container with premium styling
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
                  color: TugColors.primaryPurple.withValues(alpha: 0.05),
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
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.withValues(alpha: 0.15), Colors.orange.withValues(alpha: 0.05)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'build your streaks!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'start logging activities to track your consistency',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced section header with premium styling
        Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 16,
            top: 32,
            bottom: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [TugColors.primaryPurple.withValues(alpha: 0.2), TugColors.primaryPurpleLight.withValues(alpha: 0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'STREAKS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: TugColors.primaryPurple,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Enhanced container with premium styling
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
                color: TugColors.primaryPurple.withValues(alpha: 0.05),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Row with enhanced styling
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
                          Container(
                            width: 1,
                            height: 40,
                            color: isDarkMode
                                ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
                                : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
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
                          Container(
                            width: 1,
                            height: 40,
                            color: isDarkMode
                                ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
                                : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
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
                        const SizedBox(height: 24),
                        Container(
                          height: 1,
                          color: isDarkMode
                              ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
                              : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 20),

                        // Top streaks list with enhanced styling
                        Text(
                          'your streaks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Streaks list - showing sorted values with longest streaks first
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: valuesWithStreaks.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
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
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStreakItem(BuildContext context, ValueModel value) {
    final Color valueColor = Color(int.parse(value.color.substring(1), radix: 16) + 0xFF000000);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculate streak progress percentage compared to best streak
    final double progress = value.longestStreak > 0
        ? (value.currentStreak / value.longestStreak)
        : 1.0;

    // Clamp progress to max of 1.0
    final double clampedProgress = progress > 1.0 ? 1.0 : progress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
            : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: valueColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Enhanced value color indicator
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [valueColor.withValues(alpha: 0.15), valueColor.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: valueColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Value name and streak count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),
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
                        fontSize: 13,
                        color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (value.longestStreak > value.currentStreak) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '(Best: ${value.longestStreak})',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? TugColors.darkTextSecondary.withValues(alpha: 0.7) : TugColors.lightTextSecondary.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Enhanced progress bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isDarkMode 
                        ? TugColors.darkSurfaceVariant.withValues(alpha: 0.5)
                        : TugColors.lightSurfaceVariant.withValues(alpha: 0.8),
                  ),
                  child: LinearProgressIndicator(
                    value: clampedProgress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(valueColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          
          // Enhanced streak badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [valueColor.withValues(alpha: 0.2), valueColor.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${value.currentStreak}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}