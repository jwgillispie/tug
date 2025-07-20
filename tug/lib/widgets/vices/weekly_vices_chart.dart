import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/vice_model.dart';
import '../../models/indulgence_model.dart';
import '../../utils/theme/colors.dart';

class WeeklyVicesChart extends StatelessWidget {
  final List<ViceModel> vices;
  final List<IndulgenceModel> weeklyIndulgences;

  const WeeklyVicesChart({
    super.key,
    required this.vices,
    required this.weeklyIndulgences,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final weeklyData = _calculateWeeklyData();

    if (weeklyData.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TugColors.viceGreen.withValues(alpha: isDarkMode ? 0.9 : 0.8),
            TugColors.viceGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TugColors.viceGreen.withValues(alpha: isDarkMode ? 0.4 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'this week\'s indulgences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(weeklyData),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                        return Text(
                          days[value.toInt()],
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(weeklyData),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayIndex = group.x;
                      const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                      final viceId = weeklyData[dayIndex]![rodIndex]['viceId'];
                      final vice = vices.cast<ViceModel?>().firstWhere(
                        (v) => v?.id == viceId, 
                        orElse: () => null,
                      );
                      final count = rod.toY.round();
                      final viceName = vice?.name ?? 'Unknown Vice';
                      return BarTooltipItem(
                        '${days[dayIndex]}\n$viceName: $count',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (weeklyData.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TugColors.viceGreen.withValues(alpha: isDarkMode ? 0.9 : 0.8),
            TugColors.viceGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TugColors.viceGreen.withValues(alpha: isDarkMode ? 0.4 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 16),
            Text(
              'no indulgences this week',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'great job staying clean!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final displayedVices = vices.take(3).toList(); // Show max 3 vices in legend
    
    return Wrap(
      spacing: 12,
      children: displayedVices.map((vice) {
        final color = Color(int.parse(vice.color.substring(1), radix: 16) + 0xFF000000);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              vice.name.length > 10 ? '${vice.name.substring(0, 10)}...' : vice.name,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Map<int, List<Map<String, dynamic>>> _calculateWeeklyData() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final weekData = <int, List<Map<String, dynamic>>>{};

    // Initialize all days with empty data
    for (int i = 0; i < 7; i++) {
      weekData[i] = [];
    }

    // Get valid vice IDs to filter out orphaned indulgences
    final validViceIds = vices.map((v) => v.id).toSet();

    // Group indulgences by day and vice (only for vices that still exist)
    for (final indulgence in weeklyIndulgences) {
      // Skip indulgences for vices that no longer exist
      if (!validViceIds.contains(indulgence.viceId)) {
        continue;
      }
      final indulgenceDate = indulgence.date;
      final daysDiff = indulgenceDate.difference(startOfWeek).inDays;
      
      if (daysDiff >= 0 && daysDiff < 7) {
        final existingViceIndex = weekData[daysDiff]!.indexWhere(
          (item) => item['viceId'] == indulgence.viceId,
        );
        
        if (existingViceIndex >= 0) {
          weekData[daysDiff]![existingViceIndex]['count']++;
        } else {
          weekData[daysDiff]!.add({
            'viceId': indulgence.viceId,
            'count': 1,
          });
        }
      }
    }

    return weekData;
  }

  double _getMaxY(Map<int, List<Map<String, dynamic>>> weeklyData) {
    double maxY = 1.0;
    
    for (final dayData in weeklyData.values) {
      final dayTotal = dayData.fold<int>(0, (sum, item) => sum + (item['count'] as int));
      if (dayTotal > maxY) {
        maxY = dayTotal.toDouble();
      }
    }
    
    return maxY + 1; // Add some padding
  }

  List<BarChartGroupData> _buildBarGroups(Map<int, List<Map<String, dynamic>>> weeklyData) {
    return List.generate(7, (dayIndex) {
      final dayData = weeklyData[dayIndex] ?? [];
      
      if (dayData.isEmpty) {
        return BarChartGroupData(
          x: dayIndex,
          barRods: [
            BarChartRodData(
              toY: 0,
              color: Colors.transparent,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }

      final barRods = dayData.map((item) {
        final viceId = item['viceId'];
        final vice = vices.cast<ViceModel?>().firstWhere(
          (v) => v?.id == viceId, 
          orElse: () => null,
        );
        
        // Use vice color if found, otherwise use a default color
        final color = vice?.color != null 
            ? Color(int.parse(vice!.color.substring(1), radix: 16) + 0xFF000000)
            : Colors.grey; // Fallback color for missing vices
        
        return BarChartRodData(
          toY: (item['count'] as int).toDouble(),
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        );
      }).toList();

      return BarChartGroupData(
        x: dayIndex,
        barRods: barRods,
      );
    });
  }
}