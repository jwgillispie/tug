// lib/widgets/home/activity_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/theme/colors.dart';

class ActivityChart extends StatefulWidget {
  final List<ActivityModel> activities;
  final List<ValueModel> values;
  final int daysToShow;
  
  const ActivityChart({
    super.key,
    required this.activities,
    required this.values,
    this.daysToShow = 7, // Default to showing a week
  });

  @override
  State<ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends State<ActivityChart> {
  late List<FlSpot> _spots;
  late double _maxY;
  late List<DateTime> _dateLabels;
  
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
  
  void _prepareChartData() {
    // Get the range of dates to show
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: widget.daysToShow - 1));
    
    // Create a list of dates for the x-axis
    _dateLabels = List.generate(
      widget.daysToShow,
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
      // Normalize to just the date (no time)
      final activityDate = DateTime(
        activity.date.year,
        activity.date.month,
        activity.date.day,
      );
      
      // Convert dates to strings for accurate comparison without time
      final activityKey = '${activityDate.year}-${activityDate.month}-${activityDate.day}';
      
      // Check if this date is in our range by comparing with date keys
      bool isInRange = _dateLabels.any((dateLabel) {
        final labelKey = '${dateLabel.year}-${dateLabel.month}-${dateLabel.day}';
        return labelKey == activityKey;
      });
      
      if (isInRange) {
        dailyTotals[activityKey] = (dailyTotals[activityKey] ?? 0) + activity.duration;
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
    
    _updateMaxY();
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
    return totalMinutes / widget.daysToShow;
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
    
    return Container(
      height: 220, // Same height as the quotes widget
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: chartGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.4 : 0.3),
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
                      'Avg: ${_calculateDailyAverage().toInt()} min/day',
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
                          'past week',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11, // Slightly smaller font
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45, // Increased for more vertical space
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _dateLabels.length) {
                            return const SizedBox.shrink();
                          }
                          
                          final date = _dateLabels[index];
                          final now = DateTime.now();
                          final isToday = date.year == now.year && 
                                         date.month == now.month && 
                                         date.day == now.day;
                          
                          // Compact date display to fit in the available space
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: SizedBox(
                              height: 34, // Fixed height to prevent overflow
                              child: Column(
                                mainAxisSize: MainAxisSize.min, // Use minimum space needed
                                children: [
                                  Text(
                                    DateFormat('E').format(date), // Day of week
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(isToday ? 1.0 : 0.8),
                                      fontSize: 9, // Slightly smaller font
                                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 2), // Reduced spacing
                                  Text(
                                    DateFormat('d').format(date), // Day number
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(isToday ? 1.0 : 0.8),
                                      fontSize: 9, // Slightly smaller font
                                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  if (isToday)
                                    Container(
                                      margin: const EdgeInsets.only(top: 1), // Reduced margin
                                      width: 3, // Slightly smaller dot
                                      height: 3, // Slightly smaller dot
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
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
                                '${value.toInt()} min',
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
                  maxX: (widget.daysToShow - 1).toDouble(),
                  minY: 0,
                  maxY: _maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _spots,
                      isCurved: true,
                      color: Colors.white,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: TugColors.primaryPurple,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.white.withOpacity(0.2),
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
                          
                          // Standard tooltip
                          return LineTooltipItem(
                            '$minutes min\n${DateFormat('MMM d').format(date)}',
                            TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
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
                          'Total: ${_calculateTotalMinutes()} min (${widget.daysToShow}d)',
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
    );
  }
}