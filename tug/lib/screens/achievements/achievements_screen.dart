// lib/screens/achievements/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:tug/models/achievement_model.dart';
import 'package:tug/services/achievement_notification_service.dart';
import 'package:tug/services/achievement_service.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/widgets/achievements/achievement_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AchievementModel> _achievements = [];
  bool _isLoading = true;
  bool _isCheckingNew = false;
  final AchievementService _achievementService = AchievementService();
  final AchievementNotificationService _notificationService = AchievementNotificationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Load real achievement data
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final achievements = await _achievementService.getAchievements();

      if (mounted) {
        setState(() {
          _achievements = achievements;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading achievements: $e');

      if (mounted) {
        setState(() {
          // Load predefined achievements with no progress as fallback
          _achievements = AchievementModel.getPredefinedAchievements();
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading achievements: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshAchievements() async {
    try {
      final achievements = await _achievementService.getAchievements(
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _achievements = achievements;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Achievements updated'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error refreshing achievements: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing achievements: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkForNewAchievements() async {
    if (_isCheckingNew) return;

    setState(() {
      _isCheckingNew = true;
    });

    try {
      await _notificationService.checkForAchievements(context);

      // After checking for new achievements, refresh the list
      final achievements = await _achievementService.getAchievements(
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _achievements = achievements;
          _isCheckingNew = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking for new achievements: $e');

      if (mounted) {
        setState(() {
          _isCheckingNew = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking for new achievements: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get unlock statistics
    final totalAchievements = _achievements.length;
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final completionPercentage = totalAchievements > 0
        ? (unlockedCount / totalAchievements) * 100
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          // Check for new achievements button
          IconButton(
            icon: _isCheckingNew
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.emoji_events),
            onPressed: _isCheckingNew ? null : _checkForNewAchievements,
            tooltip: 'Check for new achievements',
          ),
          // Refresh current achievements
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAchievements,
            tooltip: 'Refresh achievements',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: TugColors.primaryPurple,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Streaks'),
            Tab(text: 'Balance'),
            Tab(text: 'Milestones'),
            Tab(text: 'Special'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Achievement progress overview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? TugColors.darkSurface : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13), // 0.05 opacity (13/255)
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalAchievements > 0
                                    ? unlockedCount / totalAchievements
                                    : 0.0,
                                backgroundColor: isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                                color: TugColors.primaryPurple,
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '$unlockedCount/$totalAchievements',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: TugColors.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ve completed ${completionPercentage.toStringAsFixed(0)}% of all achievements',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Achievement list tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // All achievements tab
                      _buildAchievementList(_achievements),

                      // Streaks tab
                      _buildAchievementList(_achievements.where(
                        (a) => a.type == AchievementType.streak
                      ).toList()),

                      // Balance tab
                      _buildAchievementList(_achievements.where(
                        (a) => a.type == AchievementType.balance
                      ).toList()),

                      // Milestones tab (combining frequency and milestone types)
                      _buildAchievementList(_achievements.where(
                        (a) => a.type == AchievementType.frequency || a.type == AchievementType.milestone
                      ).toList()),

                      // Special tab
                      _buildAchievementList(_achievements.where(
                        (a) => a.type == AchievementType.special
                      ).toList()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAchievementList(List<AchievementModel> achievements) {
    // Sort with unlocked first, then by progress
    final sortedAchievements = [...achievements]
      ..sort((a, b) {
        if (a.isUnlocked && !b.isUnlocked) return -1;
        if (!a.isUnlocked && b.isUnlocked) return 1;
        return b.progress.compareTo(a.progress);
      });

    if (sortedAchievements.isEmpty) {
      return const Center(
        child: Text('No achievements in this category'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedAchievements.length,
      itemBuilder: (context, index) {
        final achievement = sortedAchievements[index];

        return AchievementCard(
          achievement: achievement,
          onTap: () => _showAchievementDetails(achievement),
        );
      },
    );
  }

  void _showAchievementDetails(AchievementModel achievement) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Text(
              achievement.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                achievement.title,
                style: TextStyle(
                  color: achievement.isUnlocked ? achievement.color : null,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 16),
            if (achievement.isUnlocked) ...[
              const Text(
                'Achievement unlocked!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (achievement.unlockedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Unlocked on: ${_formatDate(achievement.unlockedAt!)}',
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ] else ...[
              const Text(
                'Progress:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: achievement.progress,
                backgroundColor: isDarkMode
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                color: achievement.color,
                minHeight: 8,
              ),
              const SizedBox(height: 4),
              Text(
                '${(achievement.progress * 100).toInt()}% complete',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Keep going! ${_getEncouragementMessage(achievement)}',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.grey.shade300
                      : Colors.grey.shade800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getEncouragementMessage(AchievementModel achievement) {
    final progress = achievement.progress;

    if (progress > 0.9) {
      return 'You\'re so close to unlocking this!';
    } else if (progress > 0.7) {
      return 'Just a bit more effort needed!';
    } else if (progress > 0.5) {
      return 'You\'re over halfway there!';
    } else if (progress > 0.2) {
      return 'Making good progress!';
    } else {
      return 'Every small step counts!';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}