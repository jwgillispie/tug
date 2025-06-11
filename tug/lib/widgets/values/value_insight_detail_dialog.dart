// lib/widgets/values/value_insight_detail_dialog.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/services/ai_insight_service.dart';
import 'package:tug/services/activity_service.dart';
import 'package:tug/widgets/home/value_insights.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/loading_messages.dart';

class ValueInsightDetailDialog extends StatefulWidget {
  final ValueModel value;
  final Map<String, dynamic> activityData;
  final String timeframe;

  const ValueInsightDetailDialog({
    super.key,
    required this.value,
    required this.activityData,
    required this.timeframe,
  });

  @override
  State<ValueInsightDetailDialog> createState() => _ValueInsightDetailDialogState();
}

class _ValueInsightDetailDialogState extends State<ValueInsightDetailDialog> {
  final AIInsightService _aiInsightService = AIInsightService();
  final ActivityService _activityService = ActivityService();
  List<ValueInsight> _insights = [];
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadValueInsights();
  }

  Future<void> _loadValueInsights() async {
    try {
      // Get enhanced data for this specific value
      final startDate = _getStartDate(widget.timeframe);
      final endDate = DateTime.now();
      
      final enhancedData = await _activityService.getInsightData(
        startDate: startDate,
        endDate: endDate,
        forceRefresh: false,
      );

      // Filter activities for this specific value
      final allActivities = enhancedData['individual_activities'] as List<dynamic>? ?? [];
      final valueActivities = allActivities
          .where((activity) => activity['value_id'] == widget.value.id)
          .cast<Map<String, dynamic>>()
          .toList();

      // Sort by date (most recent first)
      valueActivities.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateB.compareTo(dateA);
      });

      // Generate insights specifically for this value
      final insights = await _aiInsightService.generateValueSpecificInsights(
        value: widget.value,
        activityData: widget.activityData,
        timeframe: widget.timeframe,
        recentActivities: valueActivities,
      );

      if (mounted) {
        setState(() {
          _insights = insights;
          _recentActivities = valueActivities.take(10).toList(); // Show last 10 activities
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Failed to load value insights: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _insights = [
            ValueInsight(
              title: "Error Loading Insights",
              message: "Try again later",
              color: Color(int.parse(widget.value.color.substring(1), radix: 16) + 0xFF000000),
              category: InsightCategory.reflection,
            )
          ];
        });
      }
    }
  }

  DateTime _getStartDate(String timeframe) {
    final now = DateTime.now();
    switch (timeframe) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = Color(int.parse(widget.value.color.substring(1), radix: 16) + 0xFF000000);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: valueColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    valueColor.withOpacity(isDark ? 0.2 : 0.1),
                    valueColor.withOpacity(isDark ? 0.1 : 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: valueColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.insights,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.value.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.timeframe} insights',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: valueColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            LoadingMessages.getProgress(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AI Insights
                          if (_insights.isNotEmpty) ...[
                            Text(
                              'Personalized Insights',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._insights.map((insight) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: insight.color.withOpacity(isDark ? 0.1 : 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: insight.color.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getCategoryIcon(insight.category),
                                          color: insight.color,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          insight.category.name,
                                          style: TextStyle(
                                            color: insight.color,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      insight.title,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      insight.message,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            )),
                          ],

                          // Recent Activities
                          if (_recentActivities.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Recent Activities',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._recentActivities.map((activity) {
                              final date = DateTime.parse(activity['date']);
                              final timeAgo = _getTimeAgo(date);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: valueColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              activity['name'],
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (activity['notes'] != null && activity['notes'].toString().isNotEmpty)
                                              Text(
                                                activity['notes'],
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${activity['duration']} min',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: valueColor,
                                            ),
                                          ),
                                          Text(
                                            timeAgo,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey.shade600,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],

                          if (_recentActivities.isEmpty && !_isLoading) ...[
                            const SizedBox(height: 24),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.timeline,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No activities yet',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Start logging activities for this value to get personalized insights',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(InsightCategory category) {
    switch (category) {
      case InsightCategory.balance:
        return Icons.balance_rounded;
      case InsightCategory.progress:
        return Icons.trending_up_rounded;
      case InsightCategory.achievement:
        return Icons.emoji_events_rounded;
      case InsightCategory.focus:
        return Icons.center_focus_strong_rounded;
      case InsightCategory.reflection:
        return Icons.psychology_rounded;
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}