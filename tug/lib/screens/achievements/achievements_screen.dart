// lib/screens/achievements/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:tug/models/achievement_model.dart';
import 'package:tug/services/achievement_notification_service.dart';
import 'package:tug/services/achievement_service.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/quantum_effects.dart';
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

      if (mounted) {
        setState(() {
          // Load predefined achievements with no progress as fallback
          _achievements = AchievementModel.getPredefinedAchievements();
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error loading achievements: ${e.toString()}'),
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
            content: Text('achievements updated'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error refreshing achievements: ${e.toString()}'),
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

      if (mounted) {
        setState(() {
          _isCheckingNew = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error checking for new achievements: ${e.toString()}'),
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
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode 
                  ? [TugColors.darkBackground, TugColors.primaryPurpleDark, TugColors.primaryPurple]
                  : [TugColors.lightBackground, TugColors.primaryPurple.withAlpha(20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: QuantumEffects.holographicShimmer(
          child: QuantumEffects.gradientText(
            'achievements',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            colors: isDarkMode 
                ? [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark] 
                : [TugColors.primaryPurple, TugColors.primaryPurpleLight],
          ),
        ),
        actions: [
          QuantumEffects.floating(
            offset: 3,
            child: QuantumEffects.quantumBorder(
              glowColor: TugColors.warning,
              intensity: 0.6,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      TugColors.warning.withAlpha(100),
                      TugColors.warning.withAlpha(80),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TugColors.warning.withAlpha(80),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: _isCheckingNew
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                  onPressed: _isCheckingNew ? null : _checkForNewAchievements,
                  tooltip: 'check for new achievements',
                ),
              ),
            ),
          ),
          QuantumEffects.floating(
            offset: 5,
            child: QuantumEffects.quantumBorder(
              glowColor: TugColors.primaryPurpleLight,
              intensity: 0.8,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      TugColors.primaryPurple.withAlpha(100),
                      TugColors.primaryPurpleDark.withAlpha(80),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TugColors.primaryPurple.withAlpha(80),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  onPressed: _refreshAchievements,
                  tooltip: 'refresh achievements',
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: TugColors.primaryPurpleLight,
          labelColor: isDarkMode ? Colors.white : TugColors.primaryPurple,
          unselectedLabelColor: isDarkMode ? Colors.white60 : TugColors.primaryPurple.withAlpha(150),
          tabs: const [
            Tab(text: 'all'),
            Tab(text: 'streaks'),
            Tab(text: 'balance'),
            Tab(text: 'milestones'),
            Tab(text: 'special'),
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
                        'you\'ve completed ${completionPercentage.toStringAsFixed(0)}% of all achievements',
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
        child: Text('no achievements in this category'),
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
            Icon(
              achievement.icon,
              size: 24,
              color: achievement.color,
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
                'achievement unlocked!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (achievement.unlockedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'unlocked on: ${_formatDate(achievement.unlockedAt!)}',
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
                'progress:',
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
                'keep going! ${_getEncouragementMessage(achievement)}',
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
            child: const Text('close'),
          ),
        ],
      ),
    );
  }

  String _getEncouragementMessage(AchievementModel achievement) {
    final progress = achievement.progress;

    if (progress > 0.9) {
      return 'you\'re so close to unlocking this!';
    } else if (progress > 0.7) {
      return 'just a bit more effort needed!';
    } else if (progress > 0.5) {
      return 'you\'re over halfway there!';
    } else if (progress > 0.2) {
      return 'making good progress!';
    } else {
      return 'every small step counts!';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}