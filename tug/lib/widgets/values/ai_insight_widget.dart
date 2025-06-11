// lib/widgets/values/ai_insight_widget.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/services/ai_insight_service.dart';
import 'package:tug/services/activity_service.dart';

class AIInsightWidget extends StatefulWidget {
  final ValueModel value;
  final String timeframe;

  const AIInsightWidget({
    super.key,
    required this.value,
    required this.timeframe,
  });

  @override
  State<AIInsightWidget> createState() => _AIInsightWidgetState();
}

class _AIInsightWidgetState extends State<AIInsightWidget> {
  final AIInsightService _aiInsightService = AIInsightService();
  final ActivityService _activityService = ActivityService();
  
  String? _insightText;
  bool _isLoading = false;
  bool _hasBeenClicked = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = Color(int.parse(widget.value.color.substring(1), radix: 16) + 0xFF000000);

    return GestureDetector(
      onTap: _hasBeenClicked ? null : _generateInsight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: valueColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: valueColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _hasBeenClicked 
            ? _buildInsightContent(valueColor, isDark)
            : _buildClickPrompt(valueColor, isDark),
      ),
    );
  }

  Widget _buildClickPrompt(Color valueColor, bool isDark) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: valueColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Insights for ${widget.value.name}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap for personalized advice',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.touch_app_rounded,
          color: valueColor,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildInsightContent(Color valueColor, bool isDark) {
    if (_isLoading) {
      return Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: valueColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Generating personalized insights...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      );
    }

    if (_insightText != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: valueColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AI Insight',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _insightText!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Unable to generate insight. Try again later.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.orange,
            ),
          ),
        ),
        GestureDetector(
          onTap: _generateInsight,
          child: Icon(
            Icons.refresh,
            color: Colors.orange,
            size: 20,
          ),
        ),
      ],
    );
  }

  Future<void> _generateInsight() async {
    setState(() {
      _isLoading = true;
      _hasBeenClicked = true;
    });

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

      // Get activity summary data
      final activityData = {
        'minutes': 0,
        'community_avg': 60,
      };
      
      if (enhancedData['summary'] != null) {
        final summary = enhancedData['summary'] as Map<String, dynamic>;
        if (summary['values'] is List) {
          for (final value in summary['values']) {
            if (value is Map<String, dynamic> && value['name'] == widget.value.name) {
              activityData['minutes'] = value['minutes'] ?? 0;
              activityData['community_avg'] = value['community_avg'] ?? 60;
              break;
            }
          }
        }
      }

      // Generate specific actionable insight
      final insight = await _aiInsightService.generateSpecificActionableAdvice(
        value: widget.value,
        activityData: activityData,
        timeframe: widget.timeframe,
        recentActivities: valueActivities,
      );

      if (mounted) {
        setState(() {
          _insightText = insight;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Failed to generate insight for ${widget.value.name}: $e');
      if (mounted) {
        setState(() {
          _insightText = null;
          _isLoading = false;
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
}