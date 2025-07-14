// lib/widgets/home/swipeable_charts.dart
import 'package:flutter/material.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/models/mood_model.dart';
import 'package:tug/widgets/home/activity_chart.dart';
import 'package:tug/widgets/home/mood_chart.dart';
import 'package:tug/utils/theme/colors.dart';

class SwipeableCharts extends StatefulWidget {
  final List<ActivityModel> activities;
  final List<ValueModel> values;
  final List<MoodEntry> moodEntries;
  final int? daysToShow;
  
  const SwipeableCharts({
    super.key,
    required this.activities,
    required this.values,
    required this.moodEntries,
    this.daysToShow,
  });

  @override
  State<SwipeableCharts> createState() => _SwipeableChartsState();
}

class _SwipeableChartsState extends State<SwipeableCharts> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _navigateToChart(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Chart Navigation Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? TugColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToChart(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _currentPage == 0
                          ? TugColors.primaryPurple
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insights,
                          size: 16,
                          color: _currentPage == 0
                              ? Colors.white
                              : (isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Activity',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _currentPage == 0 ? FontWeight.bold : FontWeight.w500,
                            color: _currentPage == 0
                                ? Colors.white
                                : (isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToChart(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _currentPage == 1
                          ? Colors.deepPurple
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 16,
                          color: _currentPage == 1
                              ? Colors.white
                              : (isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mood',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _currentPage == 1 ? FontWeight.bold : FontWeight.w500,
                            color: _currentPage == 1
                                ? Colors.white
                                : (isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Swipeable Charts
        SizedBox(
          height: widget.daysToShow == null ? 300 : 260, // Adjust height based on time selector presence
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              // Activity Chart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ActivityChart(
                  activities: widget.activities,
                  values: widget.values,
                  daysToShow: widget.daysToShow,
                ),
              ),
              
              // Mood Chart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MoodChart(
                  moodEntries: widget.moodEntries,
                  daysToShow: widget.daysToShow,
                ),
              ),
            ],
          ),
        ),
        
        // Page Indicator Dots
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? (index == 0 ? TugColors.primaryPurple : Colors.deepPurple)
                      : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                ),
              );
            }),
          ),
        ),
        
        // Swipe Hint (only show initially)
        if (_currentPage == 0)
          Container(
            margin: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swipe,
                  size: 14,
                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Swipe for mood chart',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}