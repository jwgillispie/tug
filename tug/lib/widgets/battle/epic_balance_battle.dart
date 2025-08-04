import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../models/activity_model.dart';
import '../../models/vice_model.dart';
import '../../models/value_model.dart';
import '../../utils/theme/colors.dart';
import '../../utils/quantum_effects.dart';

/// 🎮 REVOLUTIONARY BATTLE VISUALIZATION
/// This widget transforms boring balance tracking into an epic battle between good and evil
class EpicBalanceBattle extends StatefulWidget {
  final List<ValueModel> values;
  final List<ViceModel> vices;
  final List<ActivityModel> recentActivities;
  final List<dynamic> recentIndulgences;
  final int daysToShow;

  const EpicBalanceBattle({
    super.key,
    required this.values,
    required this.vices,
    required this.recentActivities,
    required this.recentIndulgences,
    this.daysToShow = 7,
  });

  @override
  State<EpicBalanceBattle> createState() => _EpicBalanceBattleState();
}

class _EpicBalanceBattleState extends State<EpicBalanceBattle>
    with TickerProviderStateMixin {
  
  // Battle state
  double _battleScore = 0.0; // -1.0 (evil wins) to +1.0 (good wins)
  String _battleStatus = "preparing for battle";
  int _consecutiveWins = 0;
  
  // Battle animations
  late AnimationController _battleController;
  late AnimationController _pulseController;
  late AnimationController _energyController;
  
  late Animation<double> _battleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _energyAnimation;
  
  // Battle entities
  final Map<String, String> _goodHeroes = {
    'dominant': '⚔️', 'strong': '🛡️', 'balanced': '⚖️', 'weak': '🙏'
  };
  final Map<String, String> _evilForces = {
    'dominant': '👹', 'strong': '😈', 'balanced': '😼', 'weak': '👻'
  };

  @override
  void initState() {
    super.initState();
    
    _setupAnimations();
    _calculateBattleState();
  }

  void _setupAnimations() {
    _battleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _energyController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
    
    _battleAnimation = CurvedAnimation(
      parent: _battleController,
      curve: Curves.elasticOut,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _energyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_energyController);
    
    _battleController.forward();
  }

  void _calculateBattleState() {
    // Get recent battle data
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: widget.daysToShow));
    
    final recentActivities = widget.recentActivities
        .where((a) => a.date.isAfter(cutoffDate))
        .toList();
    final recentIndulgences = widget.recentIndulgences
        .where((i) => i.date.isAfter(cutoffDate))
        .toList();
    
    // Calculate good forces strength (values/activities)
    final goodPower = _calculateGoodPower(recentActivities);
    final evilPower = _calculateEvilPower(recentIndulgences);
    
    // Determine battle outcome
    if (goodPower + evilPower == 0) {
      _battleScore = 0.0;
      _battleStatus = "gathering strength";
    } else {
      _battleScore = ((goodPower - evilPower) / (goodPower + evilPower)).clamp(-1.0, 1.0);
      _updateBattleStatus();
    }
    
    // Calculate winning streak
    _consecutiveWins = _calculateWinStreak(recentActivities, recentIndulgences);
  }

  double _calculateGoodPower(List<ActivityModel> activities) {
    if (activities.isEmpty) return 0.0;
    
    // Values power: consistency + time investment + variety
    final totalMinutes = activities.fold(0, (sum, a) => sum + a.duration);
    final uniqueDays = activities.map((a) => 
        DateTime(a.date.year, a.date.month, a.date.day)).toSet().length;
    final uniqueValues = activities.expand((a) => a.valueIds).toSet().length;
    
    final consistency = uniqueDays / widget.daysToShow.toDouble();
    final timeInvestment = (totalMinutes / 60) / widget.daysToShow.toDouble();
    final variety = uniqueValues / math.max(1, widget.values.length).toDouble();
    
    return (consistency * 0.4 + timeInvestment * 0.4 + variety * 0.2).clamp(0.0, 3.0);
  }

  double _calculateEvilPower(List<dynamic> indulgences) {
    if (indulgences.isEmpty) return 0.0;
    
    // Evil power: frequency + recency + dominance
    final frequency = indulgences.length / widget.daysToShow.toDouble();
    final recency = _calculateRecencyFactor(indulgences);
    final dominance = _calculateDominanceFactor(indulgences);
    
    return (frequency * 0.5 + recency * 0.3 + dominance * 0.2).clamp(0.0, 3.0);
  }

  double _calculateRecencyFactor(List<dynamic> indulgences) {
    if (indulgences.isEmpty) return 0.0;
    
    final now = DateTime.now();
    double recencyScore = 0.0;
    
    for (final indulgence in indulgences) {
      final daysSince = now.difference(indulgence.date).inDays;
      recencyScore += math.exp(-daysSince / 3.0); // Exponential decay
    }
    
    return (recencyScore / indulgences.length).clamp(0.0, 1.0);
  }

  double _calculateDominanceFactor(List<dynamic> indulgences) {
    if (indulgences.isEmpty) return 0.0;
    
    final uniqueDays = indulgences.map((i) => 
        DateTime(i.date.year, i.date.month, i.date.day)).toSet().length;
    
    return (uniqueDays / widget.daysToShow.toDouble()).clamp(0.0, 1.0);
  }

  void _updateBattleStatus() {
    if (_battleScore > 0.6) {
      _battleStatus = "heroic victory! ⚔️";
    } else if (_battleScore > 0.3) {
      _battleStatus = "values advancing 🛡️";
    } else if (_battleScore > -0.3) {
      _battleStatus = "epic battle rages ⚖️";
    } else if (_battleScore > -0.6) {
      _battleStatus = "dark forces rising 😈";
    } else {
      _battleStatus = "evil dominates 👹";
    }
  }

  int _calculateWinStreak(List<ActivityModel> activities, List<dynamic> indulgences) {
    // Calculate consecutive days where good > evil
    // This is a simplified version - you could make it more sophisticated
    return math.max(0, activities.length - indulgences.length);
  }

  String _getGoodHero() {
    if (_battleScore > 0.6) return _goodHeroes['dominant']!;
    if (_battleScore > 0.2) return _goodHeroes['strong']!;
    if (_battleScore > -0.2) return _goodHeroes['balanced']!;
    return _goodHeroes['weak']!;
  }

  String _getEvilForce() {
    if (_battleScore < -0.6) return _evilForces['dominant']!;
    if (_battleScore < -0.2) return _evilForces['strong']!;
    if (_battleScore < 0.2) return _evilForces['balanced']!;
    return _evilForces['weak']!;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: 'epic balance battle: $_battleStatus with ${_consecutiveWins} win streak',
      child: Container(
        margin: const EdgeInsets.all(16),
        child: QuantumEffects.glassContainer(
          isDark: isDarkMode,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildBattleHeader(isDarkMode),
                const SizedBox(height: 20),
                _buildEpicBattleField(isDarkMode),
                const SizedBox(height: 20),
                _buildBattleStats(isDarkMode),
                const SizedBox(height: 20),
                _buildBattleActions(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBattleHeader(bool isDarkMode) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.sports_martial_arts,
              color: Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'epic balance battle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                ),
              ),
            ),
            if (_consecutiveWins > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_consecutiveWins🔥',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _battleStatus,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEpicBattleField(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _battleAnimation,
      child: SizedBox(
        height: 120,
        child: Stack(
          children: [
            // Battle background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    TugColors.primaryPurple.withValues(alpha: 0.1),
                    Colors.amber.withValues(alpha: 0.1),
                    TugColors.viceGreen.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            
            // Battle line
            Positioned(
              left: 0,
              right: 0,
              top: 55,
              child: Container(
                height: 2,
                color: isDarkMode ? Colors.white24 : Colors.black12,
              ),
            ),
            
            // Good forces (left side)
            Positioned(
              left: 20,
              top: 20,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                child: Column(
                  children: [
                    Text(
                      _getGoodHero(),
                      style: TextStyle(fontSize: 40 * (_battleScore > 0 ? 1.2 : 0.8)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'values',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: TugColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _battleScore > 0 ? _pulseAnimation.value : 1.0,
                    child: child,
                  );
                },
              ),
            ),
            
            // Evil forces (right side)
            Positioned(
              right: 20,
              top: 20,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                child: Column(
                  children: [
                    Text(
                      _getEvilForce(),
                      style: TextStyle(fontSize: 40 * (_battleScore < 0 ? 1.2 : 0.8)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'vices',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: TugColors.viceGreen,
                      ),
                    ),
                  ],
                ),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _battleScore < 0 ? _pulseAnimation.value : 1.0,
                    child: child,
                  );
                },
              ),
            ),
            
            // Battle energy in center
            Positioned(
              left: 0,
              right: 0,
              top: 40,
              child: Center(
                child: AnimatedBuilder(
                  animation: _energyAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.amber.withValues(alpha: 0.8),
                            Colors.amber.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Icon(
                        Icons.flash_on,
                        color: Colors.amber,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_battleScore * 20, 0), // Battlefield shifts based on who's winning
          child: child,
        );
      },
    );
  }

  Widget _buildBattleStats(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'good power',
            '${((_battleScore + 1) * 50).toInt()}%',
            '${widget.recentActivities.length} activities',
            TugColors.primaryPurple,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'battle score',
            '${(_battleScore.abs() * 100).toInt()}%',
            _battleScore > 0 ? 'good leads' : _battleScore < 0 ? 'evil leads' : 'balanced',
            _battleScore > 0 ? TugColors.primaryPurple : _battleScore < 0 ? TugColors.viceGreen : Colors.amber,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'evil power',
            '${((1 - _battleScore) * 50).toInt()}%',
            '${widget.recentIndulgences.length} indulgences',
            TugColors.viceGreen,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBattleActions(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (context.mounted) {
                context.go('/activity');
              }
            },
            icon: const Icon(Icons.add_circle, size: 18),
            label: const Text('strengthen good ⚔️'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TugColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (context.mounted) {
                context.go('/vices');
              }
            },
            icon: const Icon(Icons.psychology, size: 18),
            label: const Text('track temptations 👹'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TugColors.viceGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _battleController.dispose();
    _pulseController.dispose();
    _energyController.dispose();
    super.dispose();
  }
}