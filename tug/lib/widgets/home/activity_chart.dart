// lib/widgets/home/activity_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/time_utils.dart';

class ActivityChart extends StatefulWidget {
  final List<ActivityModel> activities;
  final List<ValueModel> values;
  final int? daysToShow; // Made optional to allow time range selection
  
  const ActivityChart({
    super.key,
    required this.activities,
    required this.values,
    this.daysToShow, // No default, will use internal time range selection
  });

  @override
  State<ActivityChart> createState() => _ActivityChartState();
}

enum TimeRange {
  week('1W', 7),
  month('1M', 30),
  threeMonths('3M', 90),
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

class _ActivityChartState extends State<ActivityChart> {
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
  void didUpdateWidget(ActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activities != widget.activities || 
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
    
    return _selectedTimeRange.days!;
  }
  
  void _prepareChartData() {
    final now = DateTime.now();
    final effectiveDays = _effectiveDaysToShow;
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: effectiveDays - 1));
    
    // Get aggregation level based on time range
    final aggregation = widget.daysToShow != null 
        ? DataAggregation.daily 
        : _selectedTimeRange.aggregation;
    
    if (aggregation == DataAggregation.daily) {
      _prepareDailyData(startDate, effectiveDays);
    } else {
      _prepareWeeklyData(startDate, effectiveDays);
    }
    
    _updateMaxY();
  }

  void _prepareDailyData(DateTime startDate, int days) {
    // Create a list of dates for the x-axis
    _dateLabels = List.generate(
      days,
      (index) => startDate.add(Duration(days: index)),
    );
    
    // Group activities by day and sum their durations
    final Map<String, int> dailyTotals = {};
    
    // Initialize all days in range with zero
    for (final date in _dateLabels) {
      final dateKey = '${date.year}-${date.month}-${date.day}';
      dailyTotals[dateKey] = 0;
    }
    
    // Sum the activity durations for each day
    for (final activity in widget.activities) {
      final activityDate = DateTime(
        activity.date.year,
        activity.date.month,
        activity.date.day,
      );
      
      final activityKey = '${activityDate.year}-${activityDate.month}-${activityDate.day}';
      
      if (dailyTotals.containsKey(activityKey)) {
        dailyTotals[activityKey] = dailyTotals[activityKey]! + activity.duration;
      }
    }
    
    // Create spots for the line chart
    _spots = _dateLabels.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final minutes = dailyTotals[dateKey] ?? 0;
      return FlSpot(index.toDouble(), minutes.toDouble());
    }).toList();
  }

  void _prepareWeeklyData(DateTime startDate, int days) {
    // Group data by weeks for better readability on longer time frames
    final weeklyTotals = <DateTime, int>{};
    
    // Find the Monday of the week containing startDate
    final startOfWeek = startDate.subtract(Duration(days: startDate.weekday - 1));
    
    // Calculate number of weeks to show
    final numWeeks = (days / 7).ceil();
    
    // Create weekly date labels
    _dateLabels = List.generate(
      numWeeks,
      (index) => startOfWeek.add(Duration(days: index * 7)),
    );
    
    // Initialize weekly totals
    for (final weekStart in _dateLabels) {
      weeklyTotals[weekStart] = 0;
    }
    
    // Sum activities by week
    for (final activity in widget.activities) {
      final activityDate = DateTime(
        activity.date.year,
        activity.date.month,
        activity.date.day,
      );
      
      // Skip if activity is outside our range
      if (activityDate.isBefore(startDate) || 
          activityDate.isAfter(startDate.add(Duration(days: days)))) {
        continue;
      }
      
      // Find which week this activity belongs to
      final weekStart = activityDate.subtract(Duration(days: activityDate.weekday - 1));
      
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
        weeklyTotals[closestWeek] = weeklyTotals[closestWeek]! + activity.duration;
      }
    }
    
    // Create spots for weekly data
    _spots = _dateLabels.asMap().entries.map((entry) {
      final index = entry.key;
      final weekStart = entry.value;
      final totalMinutes = weeklyTotals[weekStart] ?? 0;
      // Average daily minutes for the week for better comparison
      final avgDailyMinutes = totalMinutes / 7;
      return FlSpot(index.toDouble(), avgDailyMinutes);
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

  // Smart dot visibility - hide dots for longer time ranges like Robinhood
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
          strokeColor: TugColors.primaryPurple,
        );
      },
    );
  }

  // Get appropriate footer text based on aggregation
  String _getFooterText() {
    final aggregation = widget.daysToShow != null 
        ? DataAggregation.daily 
        : _selectedTimeRange.aggregation;
    
    if (aggregation == DataAggregation.weekly) {
      final totalMinutes = _calculateTotalMinutes();
      final weeks = _dateLabels.length;
      return 'total: ${TimeUtils.formatMinutes(totalMinutes)} (${weeks}w)';
    } else {
      final totalMinutes = _calculateTotalMinutes();
      return 'total: ${TimeUtils.formatMinutes(totalMinutes)} (${_effectiveDaysToShow}d)';
    }
  }
  
  void _updateMaxY() {
    // Set a reasonable max Y value based on data or default for better visualization
    if (widget.activities.isEmpty) {
      // If there are no activities, set a default maximum of 60 minutes
      _maxY = 60.0;
    } else {
      // Find the maximum y value for scaling, or use 60 as a minimum
      _maxY = _spots.fold(60.0, (max, spot) => spot.y > max ? spot.y : max);
      // Round up to the nearest 30 minutes for better y-axis labels
      _maxY = ((_maxY / 30).ceil() * 30).toDouble();
      
      // Make sure we have a reasonable minimum (at least 60 minutes)
      if (_maxY < 60) {
        _maxY = 60.0;
      }
    }
  }
  
  // Calculate the daily average minutes from the activity data
  double _calculateDailyAverage() {
    if (widget.activities.isEmpty) {
      return 0;
    }
    
    // Create a map to track which days have activities
    final Map<String, int> dailyMinutes = {};
    
    // Initialize all dates in our range with zero
    for (final date in _dateLabels) {
      final dateKey = '${date.year}-${date.month}-${date.day}';
      dailyMinutes[dateKey] = 0;
    }
    
    // Process each activity
    for (final activity in widget.activities) {
      // Normalize to just the date (no time)
      final activityDate = DateTime(
        activity.date.year,
        activity.date.month,
        activity.date.day,
      );
      
      // Convert to string key for comparison
      final activityKey = '${activityDate.year}-${activityDate.month}-${activityDate.day}';
      
      // Check if this date is in our range
      if (dailyMinutes.containsKey(activityKey)) {
        // Add to daily tracker
        dailyMinutes[activityKey] = dailyMinutes[activityKey]! + activity.duration;
      }
    }
    
    // Get total minutes from daily totals
    int totalMinutes = dailyMinutes.values.fold(0, (sum, minutes) => sum + minutes);
    
    // Calculate average minutes per day across all days in the range
    // This will include days with zero activity in the average
    return totalMinutes / _effectiveDaysToShow;
  }
  
  // Calculate the total minutes across all days in the range
  int _calculateTotalMinutes() {
    if (widget.activities.isEmpty) {
      return 0;
    }
    
    int totalMinutes = 0;
    
    // Create a set of date keys in our range for fast lookups
    final Set<String> dateKeysInRange = {};
    for (final date in _dateLabels) {
      final dateKey = '${date.year}-${date.month}-${date.day}';
      dateKeysInRange.add(dateKey);
    }
    
    // Sum up all activities in our date range
    for (final activity in widget.activities) {
      // Normalize to just the date (no time)
      final activityDate = DateTime(
        activity.date.year,
        activity.date.month,
        activity.date.day,
      );
      
      // Convert to string key for comparison
      final activityKey = '${activityDate.year}-${activityDate.month}-${activityDate.day}';
      
      // Add to total if date is in our range
      if (dateKeysInRange.contains(activityKey)) {
        totalMinutes += activity.duration;
      }
    }
    
    return totalMinutes;
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Default purple gradient
    final chartGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        TugColors.primaryPurple.withOpacity(isDarkMode ? 0.9 : 0.8),
        TugColors.primaryPurple,
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
          height: 220, // Same height as the quotes widget
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: chartGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: TugColors.primaryPurple.withValues(alpha: isDarkMode ? 0.4 : 0.3),
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
                    Icons.insights,
                    color: Colors.white,
                    size: 18, // Slightly smaller icon
                  ),
                  const SizedBox(width: 6), // Reduced spacing
                  const Text(
                    'activity time',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14, // Smaller font
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Daily average stat
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10), // Slightly smaller radius
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_graph,
                      color: Colors.white,
                      size: 10, // Smaller icon
                    ),
                    const SizedBox(width: 3), // Reduced spacing
                    Text(
                      'avg: ${TimeUtils.formatMinutes(_calculateDailyAverage().toInt())}/day',
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
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    drawHorizontalLine: true,
                    horizontalInterval: _maxY / 3,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.white.withOpacity(0.15),
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
                          'minutes',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11, // Slightly smaller font
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45, // Increased for better fit
                        getTitlesWidget: (value, meta) {
                          // Show fewer labels to avoid overcrowding
                          if (value == 0 || value == _maxY) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                TimeUtils.formatMinutes(value.toInt()),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
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
                          ? Colors.black.withOpacity(0.8) 
                          : Colors.white.withOpacity(0.8),
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final index = touchedSpot.x.toInt();
                          final date = _dateLabels[index];
                          final minutes = touchedSpot.y.toInt();
                          final aggregation = widget.daysToShow != null 
                              ? DataAggregation.daily 
                              : _selectedTimeRange.aggregation;
                          
                          String tooltip;
                          if (aggregation == DataAggregation.weekly) {
                            tooltip = '${TimeUtils.formatMinutes(minutes)}/day avg\nWeek of ${DateFormat('MMM d').format(date)}';
                          } else {
                            tooltip = '${TimeUtils.formatMinutes(minutes)}\n${DateFormat('MMM d').format(date)}';
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
          
          // Chart footer with motivational text and total minutes
          SizedBox(
            height: 24, // Fixed height to prevent overflow
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Total minutes badge
                if (widget.activities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8), // Smaller radius
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
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
                  const SizedBox.shrink(), // Empty widget when no activities
                
                // Motivational text
                Text(
                  'keep up the great work!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
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