// lib/widgets/home/mood_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:tug/models/mood_model.dart';

class MoodChart extends StatefulWidget {
  final List<MoodEntry> moodEntries;
  final int? daysToShow; // Made optional to allow time range selection
  
  const MoodChart({
    super.key,
    required this.moodEntries,
    this.daysToShow, // No default, will use internal time range selection
  });

  @override
  State<MoodChart> createState() => _MoodChartState();
}

enum TimeRange {
  week('1W', 7),
  month('1M', 30),
  threeMonths('3M', null), // null for actual 3-month calculation
  ytd('YTD', null); // null for year-to-date calculation

  const TimeRange(this.label, this.days);
  final String label;
  final int? days;
  
  // Determine data aggregation level based on time range
  DataAggregation get aggregation {
    switch (this) {
      case TimeRange.week:
        return DataAggregation.daily;
      case TimeRange.month:
        return DataAggregation.daily;
      case TimeRange.threeMonths:
        return DataAggregation.weekly;
      case TimeRange.ytd:
        return DataAggregation.weekly;
    }
  }
}

enum DataAggregation {
  daily,
  weekly,
  monthly;
}

class _MoodChartState extends State<MoodChart> {
  late List<FlSpot> _spots;
  late double _maxY;
  late List<DateTime> _dateLabels;
  TimeRange _selectedTimeRange = TimeRange.week;
  
  @override
  void initState() {
    super.initState();
    _prepareChartData();
  }
  
  @override
  void didUpdateWidget(MoodChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moodEntries != widget.moodEntries || 
        oldWidget.daysToShow != widget.daysToShow) {
      _prepareChartData();
    }
  }

  int get _effectiveDaysToShow {
    // Use provided daysToShow if available, otherwise use selected time range
    if (widget.daysToShow != null) {
      return widget.daysToShow!;
    }
    
    if (_selectedTimeRange == TimeRange.ytd) {
      // Calculate days from start of year to today
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      return now.difference(startOfYear).inDays + 1;
    }
    
    if (_selectedTimeRange == TimeRange.threeMonths) {
      // Calculate actual 3-month period (90-93 days depending on months)
      final now = DateTime.now();
      // Handle month overflow correctly
      int targetYear = now.year;
      int targetMonth = now.month - 3;
      if (targetMonth <= 0) {
        targetYear--;
        targetMonth += 12;
      }
      final threeMonthsAgo = DateTime(targetYear, targetMonth, now.day);
      return now.difference(threeMonthsAgo).inDays + 1;
    }
    
    return _selectedTimeRange.days!;
  }
  
  void _prepareChartData() {
    final now = DateTime.now();
    final effectiveDays = _effectiveDaysToShow;
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: effectiveDays - 1));
    
    // Debug mood data
    print('DEBUG MoodChart: Processing ${widget.moodEntries.length} mood entries');
    print('DEBUG MoodChart: Date range: $startDate to $now');
    
    // Get aggregation level based on time range
    final aggregation = widget.daysToShow != null 
        ? DataAggregation.daily 
        : _selectedTimeRange.aggregation;
    
    if (aggregation == DataAggregation.daily) {
      _prepareDailyData(startDate, effectiveDays);
    } else {
      _prepareWeeklyData(startDate, effectiveDays);
    }
    
    print('DEBUG MoodChart: Generated ${_spots.length} chart spots');
    if (_spots.isNotEmpty) {
      for (int i = 0; i < _spots.length && i < 3; i++) {
        print('  - Spot $i: x=${_spots[i].x}, y=${_spots[i].y}');
      }
    }
    
    _updateMaxY();
  }

  void _prepareDailyData(DateTime startDate, int days) {
    // Create a list of dates for the x-axis
    _dateLabels = List.generate(
      days,
      (index) => startDate.add(Duration(days: index)),
    );
    
    // Group mood entries by day and average their positivity scores
    final Map<String, List<int>> dailyMoodScores = {};
    
    // Initialize all days in range with empty lists
    for (final date in _dateLabels) {
      final dateKey = '${date.year}-${date.month}-${date.day}';
      dailyMoodScores[dateKey] = [];
    }
    
    // Group mood entries by day
    for (final moodEntry in widget.moodEntries) {
      final moodDate = DateTime(
        moodEntry.recordedAt.year,
        moodEntry.recordedAt.month,
        moodEntry.recordedAt.day,
      );
      
      final moodKey = '${moodDate.year}-${moodDate.month}-${moodDate.day}';
      
      if (dailyMoodScores.containsKey(moodKey)) {
        dailyMoodScores[moodKey]!.add(moodEntry.positivityScore);
      }
    }
    
    // Create spots for the line chart (only include days with mood entries)
    _spots = _dateLabels.asMap().entries
        .where((entry) {
          final date = entry.value;
          final dateKey = '${date.year}-${date.month}-${date.day}';
          final moodScores = dailyMoodScores[dateKey] ?? [];
          return moodScores.isNotEmpty; // Only include days with actual mood data
        })
        .map((entry) {
          final index = entry.key;
          final date = entry.value;
          final dateKey = '${date.year}-${date.month}-${date.day}';
          final moodScores = dailyMoodScores[dateKey]!; // Safe because we filtered above
          
          // Calculate average mood score for the day
          final avgScore = moodScores.reduce((a, b) => a + b) / moodScores.length.toDouble();
          
          return FlSpot(index.toDouble(), avgScore);
        }).toList();
  }

  void _prepareWeeklyData(DateTime startDate, int days) {
    // Group data by weeks for better readability on longer time frames
    final weeklyMoodScores = <DateTime, List<int>>{};
    
    // Find the Monday of the week containing startDate
    final startOfWeek = startDate.subtract(Duration(days: startDate.weekday - 1));
    
    // Calculate number of weeks to show
    final numWeeks = (days / 7).ceil();
    
    // Create weekly date labels
    _dateLabels = List.generate(
      numWeeks,
      (index) => startOfWeek.add(Duration(days: index * 7)),
    );
    
    // Initialize weekly mood scores
    for (final weekStart in _dateLabels) {
      weeklyMoodScores[weekStart] = [];
    }
    
    // Group mood entries by week
    for (final moodEntry in widget.moodEntries) {
      final moodDate = DateTime(
        moodEntry.recordedAt.year,
        moodEntry.recordedAt.month,
        moodEntry.recordedAt.day,
      );
      
      // Find which week this mood entry belongs to
      final weekStart = moodDate.subtract(Duration(days: moodDate.weekday - 1));
      
      // Find the closest week in our data
      DateTime? closestWeek;
      int minDiff = double.maxFinite.toInt();
      
      for (final week in _dateLabels) {
        final diff = (week.difference(weekStart).inDays).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestWeek = week;
        }
      }
      
      if (closestWeek != null && minDiff <= 3) { // Within same week
        // Only include if mood entry is within our date range
        final endDate = startDate.add(Duration(days: days - 1));
        if (!moodDate.isBefore(startDate) && !moodDate.isAfter(endDate)) {
          weeklyMoodScores[closestWeek]!.add(moodEntry.positivityScore);
        }
      }
    }
    
    // Create spots for weekly data (only include weeks with mood entries)
    _spots = _dateLabels.asMap().entries
        .where((entry) {
          final weekStart = entry.value;
          final moodScores = weeklyMoodScores[weekStart] ?? [];
          return moodScores.isNotEmpty; // Only include weeks with actual mood data
        })
        .map((entry) {
          final index = entry.key;
          final weekStart = entry.value;
          final moodScores = weeklyMoodScores[weekStart]!; // Safe because we filtered above
          
          // Calculate average mood score for the week
          final avgScore = moodScores.reduce((a, b) => a + b) / moodScores.length.toDouble();
          
          return FlSpot(index.toDouble(), avgScore);
        }).toList();
  }

  // Smart X-axis interval calculation for cleaner labels
  double _getXAxisInterval() {
    final numPoints = _dateLabels.length;
    final aggregation = widget.daysToShow != null 
        ? DataAggregation.daily 
        : _selectedTimeRange.aggregation;
    
    if (aggregation == DataAggregation.daily) {
      // For daily data, show fewer labels as time range increases
      if (numPoints <= 7) return 1.0; // Show every day for week
      if (numPoints <= 30) return 3.0; // Every 3 days for month
      return 7.0; // Every week for longer periods
    } else {
      // For weekly data, show every few weeks
      if (numPoints <= 12) return 1.0; // Show every week for ~3 months
      return 2.0; // Every 2 weeks for longer periods
    }
  }

  // Format date labels based on aggregation level
  String _formatDateLabel(DateTime date, DataAggregation aggregation) {
    switch (aggregation) {
      case DataAggregation.daily:
        final now = DateTime.now();
        final isCurrentYear = date.year == now.year;
        
        if (_effectiveDaysToShow <= 7) {
          // For week view: show day abbreviation
          return DateFormat('E').format(date);
        } else if (_effectiveDaysToShow <= 30) {
          // For month view: show day number
          return DateFormat('d').format(date);
        } else {
          // For longer periods: show month/day
          return isCurrentYear 
              ? DateFormat('M/d').format(date)
              : DateFormat('M/d/yy').format(date);
        }
      
      case DataAggregation.weekly:
        final now = DateTime.now();
        final isCurrentYear = date.year == now.year;
        
        // For weekly data: show month/day of week start
        return isCurrentYear 
            ? DateFormat('M/d').format(date)
            : DateFormat('M/d/yy').format(date);
      
      case DataAggregation.monthly:
        // For monthly data: show month abbreviation
        return DateFormat('MMM').format(date);
    }
  }

  // Adaptive line width for better visibility
  double _getLineWidth() {
    final aggregation = widget.daysToShow != null 
        ? DataAggregation.daily 
        : _selectedTimeRange.aggregation;
    
    return aggregation == DataAggregation.daily ? 2.5 : 3.0;
  }

  // Smart dot visibility - hide dots for longer time ranges
  FlDotData _getDotData() {
    final numPoints = _dateLabels.length;
    final aggregation = widget.daysToShow != null 
        ? DataAggregation.daily 
        : _selectedTimeRange.aggregation;
    
    // Hide dots for longer time ranges to reduce clutter
    final showDots = numPoints <= 30 && aggregation == DataAggregation.daily;
    
    if (!showDots) {
      return const FlDotData(show: false);
    }
    
    return FlDotData(
      show: true,
      getDotPainter: (spot, percent, barData, index) {
        return FlDotCirclePainter(
          radius: 3,
          color: Colors.white,
          strokeWidth: 1.5,
          strokeColor: _getMoodColor(spot.y.toInt()),
        );
      },
    );
  }

  // Get mood color based on positivity score
  Color _getMoodColor(int positivityScore) {
    if (positivityScore >= 8) {
      return Colors.green;
    } else if (positivityScore >= 6) {
      return Colors.lightGreen;
    } else if (positivityScore >= 4) {
      return Colors.orange;
    } else if (positivityScore >= 2) {
      return Colors.redAccent;
    } else {
      return Colors.red;
    }
  }

  // Get appropriate footer text based on aggregation
  String _getFooterText() {
    final aggregation = widget.daysToShow != null 
        ? DataAggregation.daily 
        : _selectedTimeRange.aggregation;
    
    if (aggregation == DataAggregation.weekly) {
      final avgScore = _calculateAverageScore();
      final weeks = _dateLabels.length;
      return 'avg mood: ${avgScore.toStringAsFixed(1)}/10 (${weeks}w)';
    } else {
      final avgScore = _calculateAverageScore();
      return 'avg mood: ${avgScore.toStringAsFixed(1)}/10 (${_effectiveDaysToShow}d)';
    }
  }
  
  void _updateMaxY() {
    // Set max Y value to 10 for mood scores (0-10 scale)
    _maxY = 10.0;
  }
  
  // Calculate the average mood score from the mood data
  double _calculateAverageScore() {
    if (widget.moodEntries.isEmpty) {
      return 5.0; // Default neutral mood
    }
    
    // Create a map to track daily mood scores
    final Map<String, List<int>> dailyMoodScores = {};
    
    // Initialize all dates in our range
    for (final date in _dateLabels) {
      final dateKey = '${date.year}-${date.month}-${date.day}';
      dailyMoodScores[dateKey] = [];
    }
    
    // Process each mood entry
    for (final moodEntry in widget.moodEntries) {
      // Normalize to just the date (no time)
      final moodDate = DateTime(
        moodEntry.recordedAt.year,
        moodEntry.recordedAt.month,
        moodEntry.recordedAt.day,
      );
      
      // Convert to string key for comparison
      final moodKey = '${moodDate.year}-${moodDate.month}-${moodDate.day}';
      
      // Check if this date is in our range
      if (dailyMoodScores.containsKey(moodKey)) {
        // Add to daily tracker
        dailyMoodScores[moodKey]!.add(moodEntry.positivityScore);
      }
    }
    
    // Calculate daily averages and then overall average
    double totalScore = 0.0;
    int daysWithMoods = 0;
    
    for (final scores in dailyMoodScores.values) {
      if (scores.isNotEmpty) {
        final dayAvg = scores.reduce((a, b) => a + b) / scores.length;
        totalScore += dayAvg;
        daysWithMoods++;
      }
    }
    
    // Return overall average, or neutral if no moods recorded
    return daysWithMoods > 0 ? totalScore / daysWithMoods : 5.0;
  }
  
  // Get mood name from score
  String _getMoodNameFromScore(double score) {
    final roundedScore = score.round();
    if (roundedScore >= 9) return 'excellent';
    if (roundedScore >= 7) return 'good';
    if (roundedScore >= 5) return 'neutral';
    if (roundedScore >= 3) return 'challenging';
    return 'difficult';
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Mood-themed gradient (blue to purple)
    final chartGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.blue.withValues(alpha: isDarkMode ? 0.9 : 0.8),
        Colors.deepPurple,
      ],
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Range Selector (only show if daysToShow is not provided)
        if (widget.daysToShow == null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TimeRange.values.map((timeRange) {
                  final isSelected = timeRange == _selectedTimeRange;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(timeRange.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTimeRange = timeRange;
                          });
                          _prepareChartData();
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
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Chart Container
        Container(
          height: 220, // Same height as the activity chart
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: chartGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withValues(alpha: isDarkMode ? 0.4 : 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart title and stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 18, // Slightly smaller icon
                      ),
                      const SizedBox(width: 6), // Reduced spacing
                      const Text(
                        'mood tracking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14, // Smaller font
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Average mood stat
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10), // Slightly smaller radius
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mood,
                          color: Colors.white,
                          size: 10, // Smaller icon
                        ),
                        const SizedBox(width: 3), // Reduced spacing
                        Text(
                          'avg: ${_getMoodNameFromScore(_calculateAverageScore())}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10, // Smaller font
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6), // Reduced spacing
              
              // Main chart
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8),
                  child: _spots.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                size: 40,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No mood data yet',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Log activities with moods to see trends',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        drawHorizontalLine: true,
                        horizontalInterval: _maxY / 4, // 4 horizontal lines for 0, 2.5, 5, 7.5, 10
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withValues(alpha: 0.15),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          axisNameSize: 16, // Reduced size
                          axisNameWidget: Padding(
                            padding: const EdgeInsets.only(top: 4), // Reduced padding
                            child: Text(
                              widget.daysToShow != null ? 'past week' : _selectedTimeRange.label.toLowerCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11, // Slightly smaller font
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _getXAxisInterval(),
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= _dateLabels.length) {
                                return const SizedBox.shrink();
                              }
                              
                              final date = _dateLabels[index];
                              final aggregation = widget.daysToShow != null 
                                  ? DataAggregation.daily 
                                  : _selectedTimeRange.aggregation;
                              
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _formatDateLabel(date, aggregation),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameSize: 16, // Reduced size
                          axisNameWidget: Padding(
                            padding: const EdgeInsets.only(bottom: 4), // Reduced padding
                            child: Text(
                              'mood',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11, // Slightly smaller font
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35, // Smaller reserved size
                            getTitlesWidget: (value, meta) {
                              // Show mood scale labels
                              if (value == 0 || value == 5 || value == 10) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 9, // Smaller font size
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (_dateLabels.length - 1).toDouble(),
                      minY: 0,
                      maxY: _maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots,
                          isCurved: true,
                          color: Colors.white,
                          barWidth: _getLineWidth(),
                          isStrokeCapRound: true,
                          dotData: _getDotData(),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => isDarkMode 
                              ? Colors.black.withValues(alpha: 0.8) 
                              : Colors.white.withValues(alpha: 0.8),
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              final index = touchedSpot.x.toInt();
                              final date = _dateLabels[index];
                              final moodScore = touchedSpot.y;
                              final aggregation = widget.daysToShow != null 
                                  ? DataAggregation.daily 
                                  : _selectedTimeRange.aggregation;
                              
                              String tooltip;
                              if (aggregation == DataAggregation.weekly) {
                                tooltip = '${moodScore.toStringAsFixed(1)}/10 avg\nWeek of ${DateFormat('MMM d').format(date)}';
                              } else {
                                tooltip = '${moodScore.toStringAsFixed(1)}/10 (${_getMoodNameFromScore(moodScore)})\n${DateFormat('MMM d').format(date)}';
                              }
                              
                              return LineTooltipItem(
                                tooltip,
                                TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Chart footer with motivational text and average mood
              SizedBox(
                height: 24, // Fixed height to prevent overflow
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Average mood badge
                    if (widget.moodEntries.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8), // Smaller radius
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.analytics_outlined,
                              color: Colors.white,
                              size: 10, // Smaller icon
                            ),
                            const SizedBox(width: 3), // Reduced spacing
                            Text(
                              _getFooterText(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10, // Smaller font
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox.shrink(), // Empty widget when no moods
                    
                    // Motivational text
                    Text(
                      'emotional awareness matters!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10, // Smaller font
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}