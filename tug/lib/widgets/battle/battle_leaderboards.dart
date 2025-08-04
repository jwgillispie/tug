import 'package:flutter/material.dart';
import '../../models/activity_model.dart';
import '../../models/vice_model.dart';
import '../../models/value_model.dart';
import '../../utils/theme/colors.dart';
import '../../utils/quantum_effects.dart';

/// 🏆 BATTLE LEADERBOARDS
/// Competitive social features that gamify balance tracking
/// Shows rankings, achievements, and creates friendly competition
class BattleLeaderboards extends StatefulWidget {
  final List<ValueModel> values;
  final List<ViceModel> vices;
  final List<ActivityModel> recentActivities;
  final List<dynamic> recentIndulgences;
  final double personalBattleScore;
  final int personalWinStreak;

  const BattleLeaderboards({
    super.key,
    required this.values,
    required this.vices,
    required this.recentActivities,
    required this.recentIndulgences,
    required this.personalBattleScore,
    required this.personalWinStreak,
  });

  @override
  State<BattleLeaderboards> createState() => _BattleLeaderboardsState();
}

class _BattleLeaderboardsState extends State<BattleLeaderboards>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  
  // Mock leaderboard data - in real app this would come from API
  final List<BattleWarrior> _globalWarriors = [];
  final List<BattleWarrior> _friendWarriors = [];
  final List<Achievement> _weeklyAchievements = [];
  
  // User's current ranking
  int _globalRank = 0;
  String _currentLeague = "bronze";

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 3, vsync: this);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    
    _generateMockData();
  }

  void _generateMockData() {
    // Generate mock global leaderboard
    _globalWarriors.addAll([
      BattleWarrior(
        name: "BalanceMaster",
        battleScore: 0.85,
        winStreak: 21,
        level: 15,
        league: "diamond",
        isUser: false,
        avatar: "👑",
      ),
      BattleWarrior(
        name: "ZenWarrior",
        battleScore: 0.72,
        winStreak: 14,
        level: 12,
        league: "gold",
        isUser: false,
        avatar: "🥋",
      ),
      BattleWarrior(
        name: "You",
        battleScore: widget.personalBattleScore,
        winStreak: widget.personalWinStreak,
        level: _calculateUserLevel(),
        league: _determineUserLeague(),
        isUser: true,
        avatar: "⚔️",
      ),
      BattleWarrior(
        name: "MindfulJedi",
        battleScore: 0.58,
        winStreak: 8,
        level: 9,
        league: "silver",
        isUser: false,
        avatar: "🧘",
      ),
      BattleWarrior(
        name: "HabitHero",
        battleScore: 0.45,
        winStreak: 5,
        level: 7,
        league: "bronze",
        isUser: false,
        avatar: "💪",
      ),
    ]);
    
    // Sort by battle score
    _globalWarriors.sort((a, b) => b.battleScore.compareTo(a.battleScore));
    
    // Find user's rank
    _globalRank = _globalWarriors.indexWhere((w) => w.isUser) + 1;
    
    // Generate friend warriors (subset of global)
    _friendWarriors.addAll(_globalWarriors.where((w) => w.name != "BalanceMaster").toList());
    
    // Generate weekly achievements
    _weeklyAchievements.addAll([
      Achievement(
        title: "Balance Streak Master",
        description: "7+ day winning streak",
        icon: "🔥",
        rarity: AchievementRarity.epic,
        completedBy: 12,
        totalParticipants: 150,
      ),
      Achievement(
        title: "Vice Slayer",
        description: "Zero indulgences this week",
        icon: "⚔️",
        rarity: AchievementRarity.legendary,
        completedBy: 3,
        totalParticipants: 150,
      ),
      Achievement(
        title: "Value Champion",
        description: "25+ hours of value activities",
        icon: "🏆",
        rarity: AchievementRarity.rare,
        completedBy: 28,
        totalParticipants: 150,
      ),
    ]);
    
    _currentLeague = _determineUserLeague();
  }

  int _calculateUserLevel() {
    // Simple level calculation based on activities and consistency
    final totalActivities = widget.recentActivities.length;
    final baseLevel = (totalActivities / 5).floor() + 1;
    final streakBonus = (widget.personalWinStreak / 3).floor();
    return (baseLevel + streakBonus).clamp(1, 30);
  }

  String _determineUserLeague() {
    if (widget.personalBattleScore > 0.7 && widget.personalWinStreak >= 14) {
      return "diamond";
    } else if (widget.personalBattleScore > 0.5 && widget.personalWinStreak >= 7) {
      return "gold";
    } else if (widget.personalBattleScore > 0.2 && widget.personalWinStreak >= 3) {
      return "silver";
    } else {
      return "bronze";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: 'battle leaderboards: rank $_globalRank globally, $_currentLeague league',
      child: Container(
        margin: const EdgeInsets.all(16),
        child: QuantumEffects.glassContainer(
          isDark: isDarkMode,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLeaderboardHeader(isDarkMode),
                const SizedBox(height: 16),
                _buildUserRankCard(isDarkMode),
                const SizedBox(height: 16),
                _buildTabBar(isDarkMode),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGlobalLeaderboard(isDarkMode),
                      _buildFriendsLeaderboard(isDarkMode),
                      _buildWeeklyAchievements(isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardHeader(bool isDarkMode) {
    return Row(
      children: [
        Icon(
          Icons.leaderboard,
          color: Colors.amber,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'battle leaderboards',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
            ),
          ),
        ),
        _buildLeagueIndicator(isDarkMode),
      ],
    );
  }

  Widget _buildLeagueIndicator(bool isDarkMode) {
    final leagueColor = _getLeagueColor(_currentLeague);
    final leagueIcon = _getLeagueIcon(_currentLeague);
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              leagueColor.withValues(alpha: 0.2),
              leagueColor.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: leagueColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              leagueIcon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              _currentLeague,
              style: TextStyle(
                color: leagueColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: leagueColor.withValues(alpha: 0.3 * _glowAnimation.value),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildUserRankCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TugColors.primaryPurple.withValues(alpha: 0.1),
            Colors.amber.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TugColors.primaryPurple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: TugColors.primaryPurple.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('⚔️', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'your battle rank',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                  ),
                ),
                Text(
                  '#$_globalRank globally',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: TugColors.primaryPurple,
                  ),
                ),
                Text(
                  'level ${_calculateUserLevel()} • ${widget.personalWinStreak} win streak',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: TugColors.primaryPurple,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'global'),
          Tab(text: 'friends'),
          Tab(text: 'achievements'),
        ],
      ),
    );
  }

  Widget _buildGlobalLeaderboard(bool isDarkMode) {
    return ListView.builder(
      itemCount: _globalWarriors.length,
      itemBuilder: (context, index) {
        final warrior = _globalWarriors[index];
        return _buildWarriorCard(warrior, index + 1, isDarkMode);
      },
    );
  }

  Widget _buildFriendsLeaderboard(bool isDarkMode) {
    return ListView.builder(
      itemCount: _friendWarriors.length,
      itemBuilder: (context, index) {
        final warrior = _friendWarriors[index];
        return _buildWarriorCard(warrior, index + 1, isDarkMode);
      },
    );
  }

  Widget _buildWarriorCard(BattleWarrior warrior, int rank, bool isDarkMode) {
    final isUser = warrior.isUser;
    final leagueColor = _getLeagueColor(warrior.league);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser 
            ? TugColors.primaryPurple.withValues(alpha: 0.1)
            : isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isUser ? Border.all(
          color: TugColors.primaryPurple.withValues(alpha: 0.3),
          width: 2,
        ) : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _getRankColor(rank).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getRankColor(rank),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Avatar
          Text(warrior.avatar, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      warrior.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUser ? TugColors.primaryPurple : 
                               isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 8),
                      const Text('(you)', style: TextStyle(color: TugColors.primaryPurple, fontSize: 12)),
                    ],
                  ],
                ),
                Text(
                  'level ${warrior.level} • ${warrior.winStreak} streak',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(warrior.battleScore * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: leagueColor,
                  fontSize: 16,
                ),
              ),
              Text(
                warrior.league,
                style: TextStyle(
                  fontSize: 10,
                  color: leagueColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAchievements(bool isDarkMode) {
    return ListView.builder(
      itemCount: _weeklyAchievements.length,
      itemBuilder: (context, index) {
        final achievement = _weeklyAchievements[index];
        return _buildAchievementCard(achievement, isDarkMode);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isDarkMode) {
    final rarityColor = _getRarityColor(achievement.rarity);
    final completionRate = achievement.completedBy / achievement.totalParticipants;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rarityColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(achievement.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  achievement.rarity.name,
                  style: TextStyle(
                    color: rarityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${achievement.completedBy} warriors completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    '${(completionRate * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: rarityColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: completionRate,
                backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                minHeight: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLeagueColor(String league) {
    switch (league) {
      case "diamond":
        return Colors.cyan;
      case "gold":
        return Colors.amber;
      case "silver":
        return Colors.grey;
      case "bronze":
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getLeagueIcon(String league) {
    switch (league) {
      case "diamond":
        return "💎";
      case "gold":
        return "🏆";
      case "silver":
        return "🥈";
      case "bronze":
        return "🥉";
      default:
        return "⚔️";
    }
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey;
    if (rank == 3) return Colors.brown;
    return Colors.blue;
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.legendary:
        return Colors.orange;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.common:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

// Data models
class BattleWarrior {
  final String name;
  final double battleScore;
  final int winStreak;
  final int level;
  final String league;
  final bool isUser;
  final String avatar;

  BattleWarrior({
    required this.name,
    required this.battleScore,
    required this.winStreak,
    required this.level,
    required this.league,
    required this.isUser,
    required this.avatar,
  });
}

class Achievement {
  final String title;
  final String description;
  final String icon;
  final AchievementRarity rarity;
  final int completedBy;
  final int totalParticipants;

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.completedBy,
    required this.totalParticipants,
  });
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}