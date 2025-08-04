import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  
  // User's current stats
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
      label: 'battle leaderboards: $_currentLeague league',
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
                  height: 280,
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
                  'your battle stats',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                  ),
                ),
                Text(
                  'level ${_calculateUserLevel()}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: TugColors.primaryPurple,
                  ),
                ),
                Text(
                  '${widget.personalWinStreak} win streak • $_currentLeague league',
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
    return _buildPremiumFeatureState(
      'global rankings available!',
      'compete with warriors worldwide and see where you rank',
      '🌍',
      'view rankings',
      () => context.push('/rankings'),
      isDarkMode,
    );
  }

  Widget _buildFriendsLeaderboard(bool isDarkMode) {
    return _buildEmptyState(
      'friend battles coming soon!',
      'challenge friends to balance duels once social features are activated',
      '👥',
      isDarkMode,
    );
  }

  Widget _buildWeeklyAchievements(bool isDarkMode) {
    return _buildEmptyState(
      'weekly challenges coming soon!',
      'epic achievements and challenges will be available once the feature is activated',
      '🏆',
      isDarkMode,
    );
  }

  Widget _buildEmptyState(String title, String description, String emoji, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeatureState(String title, String description, String emoji, String buttonText, VoidCallback onTap, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: TugColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
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

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}