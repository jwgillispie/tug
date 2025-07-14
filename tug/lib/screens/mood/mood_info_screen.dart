// lib/screens/mood/mood_info_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/models/mood_model.dart';
import 'package:tug/services/mood_service.dart';
import 'package:tug/utils/theme/colors.dart';

class MoodInfoScreen extends StatefulWidget {
  const MoodInfoScreen({super.key});

  @override
  State<MoodInfoScreen> createState() => _MoodInfoScreenState();
}

class _MoodInfoScreenState extends State<MoodInfoScreen> {
  final MoodService _moodService = MoodService();
  List<MoodOption> _moodOptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMoodOptions();
  }

  Future<void> _loadMoodOptions() async {
    try {
      final options = await _moodService.getMoodOptions();
      setState(() {
        _moodOptions = options..sort((a, b) => b.positivityScore.compareTo(a.positivityScore));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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

  String _getMoodCategory(int positivityScore) {
    if (positivityScore >= 8) {
      return 'Very Positive';
    } else if (positivityScore >= 6) {
      return 'Positive';
    } else if (positivityScore >= 4) {
      return 'Neutral';
    } else if (positivityScore >= 2) {
      return 'Challenging';
    } else {
      return 'Very Challenging';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Mood Tracking Guide',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: TugColors.primaryPurple),
                  const SizedBox(height: 16),
                  Text(
                    'Loading mood information...',
                    style: TextStyle(
                      color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: TugColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load mood information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your connection and try again',
                        style: TextStyle(
                          color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMoodOptions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Introduction
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              TugColors.primaryPurple.withValues(alpha: 0.1),
                              TugColors.primaryPurpleLight.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: TugColors.primaryPurple.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  color: TugColors.primaryPurple,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Understanding Mood Tracking',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Mood tracking helps you understand the connection between your activities and emotional well-being. Each mood has a positivity score from 0-10:',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('8-10: Very positive emotions', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.lightGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('6-7: Positive emotions', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('4-5: Neutral emotions', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('2-3: Challenging emotions', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('0-1: Very challenging emotions', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // All moods list
                      Text(
                        'All Available Moods',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Group moods by category
                      ...['Very Positive', 'Positive', 'Neutral', 'Challenging', 'Very Challenging']
                          .map((category) {
                        final categoryMoods = _moodOptions
                            .where((mood) => _getMoodCategory(mood.positivityScore) == category)
                            .toList();

                        if (categoryMoods.isEmpty) return Container();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _getMoodColor(categoryMoods.first.positivityScore),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...categoryMoods.map((mood) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? TugColors.darkSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getMoodColor(mood.positivityScore).withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        mood.emoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  mood.displayName,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _getMoodColor(mood.positivityScore),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    '${mood.positivityScore}/10',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              mood.description,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),

                      // Bottom info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tips for Mood Tracking',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Be honest about how you\'re feeling - there are no wrong answers\n'
                              '• Track your mood consistently to see patterns over time\n'
                              '• Notice which activities correlate with positive moods\n'
                              '• Use this data to make informed decisions about your daily habits\n'
                              '• Remember that all emotions are valid and temporary',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}