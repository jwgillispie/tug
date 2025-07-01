// lib/widgets/profile/activity_statistics.dart
import 'package:flutter/material.dart';
import '../../services/activity_service.dart';
import '../../services/app_mode_service.dart';
import '../../utils/theme/colors.dart';

class ActivityStatistics extends StatefulWidget {
  const ActivityStatistics({super.key});

  @override
  State<ActivityStatistics> createState() => _ActivityStatisticsState();
}

class _ActivityStatisticsState extends State<ActivityStatistics> {
  final ActivityService _activityService = ActivityService();
  final AppModeService _appModeService = AppModeService();
  
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> _summary = {};
  String _selectedPeriod = '7_days';
  AppMode _currentMode = AppMode.valuesMode;

  final Map<String, String> _periods = {
    '7_days': 'past 7 days',
    '30_days': 'past 30 days',
    '90_days': 'past 90 days',
    'all_time': 'all time',
  };

  @override
  void initState() {
    super.initState();
    _initializeMode();
    _loadStatistics();
  }

  void _initializeMode() async {
    await _appModeService.initialize();
    if (mounted) {
      setState(() {
        _currentMode = _appModeService.currentMode;
      });
    }
  }

  DateTime? _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '7_days':
        return now.subtract(const Duration(days: 7));
      case '30_days':
        return now.subtract(const Duration(days: 30));
      case '90_days':
        return now.subtract(const Duration(days: 90));
      case 'all_time':
      default:
        return null;
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final startDate = _getStartDate();
      final endDate = DateTime.now();

      final results = await Future.wait([
        _activityService.getActivityStatistics(
          startDate: startDate,
          endDate: endDate,
          forceRefresh: false,
        ),
        _activityService.getActivitySummary(
          startDate: startDate,
          endDate: endDate,
          forceRefresh: false,
        ),
      ]);

      if (mounted) {
        setState(() {
          _statistics = results[0];
          _summary = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statistics = {};
          _summary = {};
          _isLoading = false;
        });
      }
    }
  }

  void _onPeriodChanged(String? period) {
    if (period != null && period != _selectedPeriod) {
      setState(() {
        _selectedPeriod = period;
      });
      _loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isViceMode
              ? [
                  TugColors.viceGreen.withValues(alpha: isDarkMode ? 0.9 : 0.8),
                  TugColors.viceGreen,
                ]
              : [
                  TugColors.primaryPurple.withValues(alpha: isDarkMode ? 0.9 : 0.8),
                  TugColors.primaryPurple,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isViceMode ? TugColors.viceGreen : TugColors.primaryPurple)
                .withValues(alpha: isDarkMode ? 0.4 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with period selector
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isViceMode ? Icons.psychology : Icons.timeline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isViceMode ? 'recovery statistics' : 'activity statistics',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Period selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              hint: const Text(
                'select period',
                style: TextStyle(color: Colors.white),
              ),
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: isDarkMode ? TugColors.darkSurface : Colors.white,
              items: _periods.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isDarkMode 
                          ? TugColors.darkTextPrimary 
                          : TugColors.lightTextPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _onPeriodChanged,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Statistics content
          if (_isLoading) ...[
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'loading statistics...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildStatisticsGrid(),
            const SizedBox(height: 16),
            if (_summary['values'] != null && (_summary['values'] as List).isNotEmpty)
              _buildValueBreakdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final totalActivities = _statistics['total_activities'] ?? 0;
    final totalHours = _statistics['total_duration_hours'] ?? 0.0;
    final avgDuration = _statistics['average_duration_minutes'] ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.fitness_center,
                label: 'total activities',
                value: '$totalActivities',
                subtitle: totalActivities == 1 ? 'activity' : 'activities',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.schedule,
                label: 'total time',
                value: '${totalHours.toStringAsFixed(1)}h',
                subtitle: 'hours tracked',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          icon: Icons.trending_up,
          label: 'average session',
          value: '${avgDuration.round()} min',
          subtitle: 'per activity',
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    bool isWide = false,
  }) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueBreakdown() {
    final values = _summary['values'] as List? ?? [];
    
    if (values.isEmpty) return const SizedBox.shrink();

    // Sort values by total duration
    values.sort((a, b) => (b['total_duration_minutes'] ?? 0).compareTo(a['total_duration_minutes'] ?? 0));
    
    // Take top 3 values
    final topValues = values.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'top values',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...topValues.map((value) => _buildValueItem(value)),
        ],
      ),
    );
  }

  Widget _buildValueItem(Map<String, dynamic> value) {
    final name = value['name'] ?? 'unknown';
    final duration = value['total_duration_minutes'] ?? 0;
    final activities = value['activity_count'] ?? 0;
    final hours = (duration / 60).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${hours}h • $activities activities',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}