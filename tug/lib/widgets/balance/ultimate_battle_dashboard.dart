// lib/widgets/balance/ultimate_battle_dashboard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../utils/theme/colors.dart';
import '../../utils/quantum_effects.dart';
import '../../models/value_model.dart';
import '../../models/vice_model.dart';
import '../../models/activity_model.dart';
import '../../models/indulgence_model.dart';

/// THE ULTIMATE BATTLE DASHBOARD
/// This is the killer feature that makes Tug completely unique - a gamified
/// tug-of-war battle between values and vices that users can't put down
class UltimateBattleDashboard extends StatefulWidget {
  final List<ValueModel> values;
  final List<ViceModel> vices;
  final List<ActivityModel> recentActivities;
  final List<IndulgenceModel> recentIndulgences;
  final int daysToShow;
  
  const UltimateBattleDashboard({
    super.key,
    required this.values,
    required this.vices,
    required this.recentActivities,
    required this.recentIndulgences,
    this.daysToShow = 7,
  });

  @override
  State<UltimateBattleDashboard> createState() => _UltimateBattleDashboardState();
}

class _UltimateBattleDashboardState extends State<UltimateBattleDashboard>
    with TickerProviderStateMixin {
  
  // Epic Animation Controllers
  late AnimationController _battleController;
  late AnimationController _pulseController;
  late AnimationController _ropeController;
  late AnimationController _explosionController;
  late AnimationController _healthController;
  late AnimationController _victoryController;
  
  // Battle Animations
  late Animation<double> _battleIntensity;
  late Animation<double> _characterPulse;
  late Animation<double> _ropeShake;
  late Animation<double> _explosionScale;
  late Animation<double> _healthPulse;
  late Animation<double> _victoryGlow;
  
  // GAME STATE - This is what makes it addictive
  double _balanceScore = 0.0; // -1.0 to 1.0
  int _valuesHealth = 100;    // 0-100 HP
  int _vicesHealth = 100;     // 0-100 HP
  int _battleStreak = 0;      // Consecutive balanced days
  String _battlePhase = "preparation"; // preparation, skirmish, battle, victory, defeat
  String _heroStatus = "ready for battle";
  String _villainStatus = "plotting in shadows";
  bool _isEpicMoment = false;
  final int _totalBattleScore = 0;   // Lifetime battle score
  
  // Battle Statistics
  final Map<String, dynamic> _battleStats = {
    'totalWins': 0,
    'totalLosses': 0,
    'longestStreak': 0,
    'epicMoments': 0,
    'powerLevel': 1,
  };

  @override
  void initState() {
    super.initState();
    _setupEpicAnimations();
    _calculateBattleState();
    _startBattleSequence();
  }

  void _setupEpicAnimations() {
    // Main battle animation - builds intensity over time
    _battleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    // Character pulse - shows energy and health
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Rope shake for dramatic moments
    _ropeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Explosion effects for epic moments
    _explosionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Health bar pulsing
    _healthController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Victory/defeat glow
    _victoryController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Setup animation curves
    _battleIntensity = CurvedAnimation(
      parent: _battleController,
      curve: Curves.elasticOut,
    );
    
    _characterPulse = Tween<double>(
      begin: 0.95,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _ropeShake = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _ropeController,
      curve: Curves.elasticInOut,
    ));
    
    _explosionScale = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _explosionController,
      curve: Curves.easeOutBack,
    ));
    
    _healthPulse = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _healthController,
      curve: Curves.easeInOut,
    ));
    
    _victoryGlow = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _victoryController,
      curve: Curves.easeInOut,
    ));
  }

  void _calculateBattleState() {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: widget.daysToShow));
    
    // Filter recent battle data
    final recentActivities = widget.recentActivities
        .where((a) => a.date.isAfter(cutoffDate))
        .toList();
    final recentIndulgences = widget.recentIndulgences
        .where((i) => i.date.isAfter(cutoffDate))
        .toList();
    
    // Calculate Values Army strength (0-100)
    final valuesStrength = _calculateValuesStrength(recentActivities);
    
    // Calculate Vice Legion power (0-100)  
    final vicesStrength = _calculateVicesStrength(recentIndulgences);
    
    // Determine battle balance (-1.0 = vices winning, +1.0 = values winning)
    final totalStrength = valuesStrength + vicesStrength;
    if (totalStrength > 0) {
      _balanceScore = ((valuesStrength - vicesStrength) / totalStrength).clamp(-1.0, 1.0);
    } else {
      _balanceScore = 0.0;
    }
    
    // Calculate health bars (more engaging than simple percentages)
    _valuesHealth = math.min(100, valuesStrength + 20).round();
    _vicesHealth = math.min(100, vicesStrength + 20).round();
    
    // Determine battle phase and status
    _updateBattlePhase();
    _calculateBattleStreak(recentActivities, recentIndulgences);
    _updateBattleStats();
    
    // Trigger epic moments
    _checkForEpicMoments();
  }

  int _calculateValuesStrength(List<ActivityModel> activities) {
    if (activities.isEmpty) return 10; // Base strength
    
    // Multi-factor strength calculation
    final activityCount = activities.length;
    final totalMinutes = activities.fold<int>(0, (sum, a) => sum + a.duration);
    final uniqueDays = activities
        .map((a) => DateTime(a.date.year, a.date.month, a.date.day))
        .toSet().length;
    
    // Consistency bonus (daily activity = power multiplier)
    final consistencyBonus = uniqueDays >= widget.daysToShow ? 30 : uniqueDays * 4;
    
    // Activity frequency strength
    final frequencyStrength = math.min(40, activityCount * 6);
    
    // Time investment strength
    final timeStrength = math.min(30, (totalMinutes / 30).round());
    
    return (frequencyStrength + timeStrength + consistencyBonus).clamp(10, 100);
  }

  int _calculateVicesStrength(List<IndulgenceModel> indulgences) {
    if (indulgences.isEmpty) return 5; // Vices start weak
    
    final indulgenceCount = indulgences.length;
    final recentCount = indulgences.where((i) => 
        DateTime.now().difference(i.date).inHours <= 24).length;
    
    // Recent activity makes vices stronger (addiction model)
    final recentStrength = recentCount * 25;
    
    // Frequency strength  
    final frequencyStrength = math.min(50, indulgenceCount * 8);
    
    // Momentum bonus (consecutive days)
    final momentum = _calculateViceMomentum(indulgences);
    
    return (frequencyStrength + recentStrength + momentum).clamp(5, 100);
  }

  int _calculateViceMomentum(List<IndulgenceModel> indulgences) {
    int momentum = 0;
    final now = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayIndulgences = indulgences.where((ind) => 
          ind.date.isAfter(dayStart) && ind.date.isBefore(dayEnd)).length;
      
      if (dayIndulgences > 0) {
        momentum += 10;
      } else {
        break; // Streak broken
      }
    }
    
    return momentum;
  }

  void _updateBattlePhase() {
    if (_balanceScore > 0.7) {
      _battlePhase = "victory";
      _heroStatus = "🏆 CHAMPION OF VALUES!";
      _villainStatus = "retreating in defeat...";
    } else if (_balanceScore < -0.7) {
      _battlePhase = "defeat";
      _heroStatus = "wounded but not broken...";
      _villainStatus = "😈 VICE LORDS REIGN!";
    } else if (_balanceScore.abs() > 0.3) {
      _battlePhase = "battle";
      _heroStatus = "⚔️ fighting with honor!";
      _villainStatus = "🔥 unleashing chaos!";
    } else if (_balanceScore.abs() > 0.1) {
      _battlePhase = "skirmish";
      _heroStatus = "preparing for battle...";
      _villainStatus = "gathering dark forces...";
    } else {
      _battlePhase = "preparation";
      _heroStatus = "training and meditating";
      _villainStatus = "lurking in shadows";
    }
  }

  void _calculateBattleStreak(List<ActivityModel> activities, List<IndulgenceModel> indulgences) {
    int streak = 0;
    final now = DateTime.now();
    
    for (int i = 0; i < 30; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayActivities = activities.where((a) => 
          a.date.isAfter(dayStart) && a.date.isBefore(dayEnd)).length;
      final dayIndulgences = indulgences.where((i) => 
          i.date.isAfter(dayStart) && i.date.isBefore(dayEnd)).length;
      
      // Victory condition: more activities than indulgences OR clean day
      final dayBalance = dayActivities > dayIndulgences || 
          (dayIndulgences == 0 && dayActivities >= 1);
      
      if (dayBalance) {
        streak++;
      } else {
        break;
      }
    }
    
    _battleStreak = streak;
  }

  void _updateBattleStats() {
    // This would normally come from a database
    _battleStats['powerLevel'] = (_battleStreak / 7).floor() + 1;
    _battleStats['longestStreak'] = math.max(_battleStats['longestStreak'], _battleStreak);
    
    if (_battlePhase == "victory") {
      _battleStats['totalWins']++;
    } else if (_battlePhase == "defeat") {
      _battleStats['totalLosses']++;
    }
  }

  void _checkForEpicMoments() {
    final wasEpic = _isEpicMoment;
    
    // Epic moment triggers
    _isEpicMoment = _battleStreak >= 7 || 
                   _balanceScore.abs() > 0.8 ||
                   (_valuesHealth > 90 && _vicesHealth < 20);
    
    // Trigger animations for epic moments
    if (_isEpicMoment && !wasEpic) {
      _explosionController.forward().then((_) => _explosionController.reset());
      _ropeController.forward().then((_) => _ropeController.reset());
      _battleStats['epicMoments']++;
    }
    
    if (_battlePhase == "victory" || _battlePhase == "defeat") {
      _victoryController.forward();
    }
  }

  void _startBattleSequence() {
    _battleController.forward();
    
    // Auto-trigger health pulse when health is low
    if (_valuesHealth < 30 || _vicesHealth < 30) {
      _healthController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _battleController.dispose();
    _pulseController.dispose();
    _ropeController.dispose();
    _explosionController.dispose();
    _healthController.dispose();
    _victoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: 'Ultimate Battle Dashboard: $_battlePhase phase. Hero: $_heroStatus. Villain: $_villainStatus. Battle streak: $_battleStreak days.',
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getBattleBackgroundColor(isDarkMode).withValues(alpha: 0.9),
              _getBattleBackgroundColor(isDarkMode).withValues(alpha: 0.7),
              _getBattleAccentColor().withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _getBattleAccentColor().withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.1),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: _getBattleAccentColor().withValues(alpha: 0.4),
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            if (_isEpicMoment) _buildEpicEffects(),
            if (_battlePhase == "victory" || _battlePhase == "defeat") _buildVictoryEffects(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildBattleHeader(isDarkMode),
                  const SizedBox(height: 20),
                  _buildEpicBattlefield(isDarkMode),
                  const SizedBox(height: 20),
                  _buildHealthBars(isDarkMode),
                  const SizedBox(height: 16),
                  _buildBattleStats(isDarkMode),
                  const SizedBox(height: 20),
                  _buildBattleActions(isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpicEffects() {
    return AnimatedBuilder(
      animation: _explosionScale,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: RadialGradient(
                center: Alignment.center,
                colors: [
                  Colors.amber.withValues(alpha: _explosionScale.value * 0.3),
                  Colors.orange.withValues(alpha: _explosionScale.value * 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVictoryEffects() {
    return AnimatedBuilder(
      animation: _victoryGlow,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  _getBattleAccentColor().withValues(alpha: _victoryGlow.value * 0.2),
                  Colors.transparent,
                  _getBattleAccentColor().withValues(alpha: _victoryGlow.value * 0.2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBattleHeader(bool isDarkMode) {
    return Column(
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _characterPulse,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _getBattleAccentColor().withValues(alpha: 0.3),
                      _getBattleAccentColor().withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getBattleAccentColor().withValues(alpha: 0.5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getBattleAccentColor().withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getBattleIcon(),
                  color: _getBattleAccentColor(),
                  size: 36,
                ),
              ),
              builder: (context, child) => Transform.scale(
                scale: _characterPulse.value,
                child: child,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'battle arena',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getBattlePhaseDescription(),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getBattleAccentColor(),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _buildPowerLevelBadge(),
          ],
        ),
        const SizedBox(height: 16),
        _buildBattleStatusBar(isDarkMode),
      ],
    );
  }

  Widget _buildPowerLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber,
            Colors.orange,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flash_on, color: Colors.white, size: 20),
              const SizedBox(width: 4),
              Text(
                'LVL ${_battleStats['powerLevel']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            '${_battleStreak}d streak',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleStatusBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getBattleAccentColor().withValues(alpha: 0.1),
            _getBattleAccentColor().withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBattleAccentColor().withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hero Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: TugColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _heroStatus,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 2,
            height: 40,
            color: _getBattleAccentColor().withValues(alpha: 0.3),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Villain Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: TugColors.viceGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _villainStatus,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpicBattlefield(bool isDarkMode) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ropeShake, _battleIntensity]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_ropeShake.value, 0),
          child: SizedBox(
            height: 160,
            child: Stack(
              children: [
                _buildBattleground(isDarkMode),
                _buildValuesHero(isDarkMode),
                _buildViceVillain(isDarkMode),
                _buildEpicRope(isDarkMode),
                if (_isEpicMoment) _buildBattleEffects(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBattleground(bool isDarkMode) {
    return Positioned(
      top: 70,
      left: 0,
      right: 0,
      child: Container(
        height: 25,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              TugColors.primaryPurple.withValues(alpha: 0.5),
              _getBattleAccentColor().withValues(alpha: 0.4),
              TugColors.viceGreen.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _getBattleAccentColor().withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Battle intensity indicator
            AnimatedBuilder(
              animation: _battleIntensity,
              builder: (context, child) {
                return Container(
                  height: 25,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _getBattleAccentColor().withValues(alpha: _battleIntensity.value * 0.3),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValuesHero(bool isDarkMode) {
    return Positioned(
      left: 30,
      top: 15,
      child: AnimatedBuilder(
        animation: _characterPulse,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TugColors.primaryPurple.withValues(alpha: 0.3),
                    TugColors.primaryPurple.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: TugColors.primaryPurple.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TugColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'VALUES HERO ⚔️',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: TugColors.primaryPurple,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: TugColors.primaryPurple.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.shield_outlined,
                color: TugColors.primaryPurple,
                size: 42,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'HP: $_valuesHealth',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: TugColors.primaryPurple,
              ),
            ),
          ],
        ),
        builder: (context, child) => Transform.scale(
          scale: 1.0 + (_valuesHealth / 100.0) * _characterPulse.value * 0.1,
          child: child,
        ),
      ),
    );
  }

  Widget _buildViceVillain(bool isDarkMode) {
    return Positioned(
      right: 30,
      top: 15,
      child: AnimatedBuilder(
        animation: _characterPulse,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TugColors.viceGreen.withValues(alpha: 0.3),
                    TugColors.viceGreen.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: TugColors.viceGreen.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TugColors.viceGreen.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '👹 VICE VILLAIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: TugColors.viceGreen,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: TugColors.viceGreen.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.psychology_outlined,
                color: TugColors.viceGreen,
                size: 42,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'HP: $_vicesHealth',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: TugColors.viceGreen,
              ),
            ),
          ],
        ),
        builder: (context, child) => Transform.scale(
          scale: 1.0 + (_vicesHealth / 100.0) * _characterPulse.value * 0.1,
          child: child,
        ),
      ),
    );
  }

  Widget _buildEpicRope(bool isDarkMode) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ropePosition = (screenWidth * 0.5) - 80 + (_balanceScore * 120);
    
    return Positioned(
      left: ropePosition,
      top: 75,
      child: QuantumEffects.floating(
        offset: 6,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                _getBattleAccentColor(),
                _getBattleAccentColor().withValues(alpha: 0.7),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getBattleAccentColor().withValues(alpha: 0.6),
                blurRadius: 25,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.anchor,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildBattleEffects() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _explosionScale,
        builder: (context, child) {
          return Stack(
            children: [
              // Sparks effect
              ...List.generate(8, (index) {
                final angle = (index * math.pi * 2) / 8;
                final x = math.cos(angle) * 50 * _explosionScale.value;
                final y = math.sin(angle) * 50 * _explosionScale.value;
                
                return Positioned(
                  left: 80 + x,
                  top: 80 + y,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: _explosionScale.value),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHealthBars(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildHealthBar(
            'Values Hero',
            _valuesHealth,
            TugColors.primaryPurple,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getBattleAccentColor().withValues(alpha: 0.2),
                _getBattleAccentColor().withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getBattleAccentColor().withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                'BALANCE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getBattleAccentColor(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(_balanceScore * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getBattleAccentColor(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildHealthBar(
            'Vice Villain',
            _vicesHealth,
            TugColors.viceGreen,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthBar(String title, int health, Color color, bool isDarkMode) {
    final isLowHealth = health < 30;
    
    return AnimatedBuilder(
      animation: isLowHealth ? _healthPulse : Listenable.merge([]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                health > 70 ? Icons.favorite : health > 30 ? Icons.favorite_border : Icons.heart_broken,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              widthFactor: health / 100.0,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      health > 50 ? color : Colors.red,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$health/100 HP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
      builder: (context, child) => Transform.scale(
        scale: isLowHealth ? _healthPulse.value : 1.0,
        child: child,
      ),
    );
  }

  Widget _buildBattleStats(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.grey.shade100,
            isDarkMode ? Colors.grey.shade900.withValues(alpha: 0.3) : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Wins', '${_battleStats['totalWins']}', Icons.emoji_events, Colors.amber),
          _buildStatItem('Losses', '${_battleStats['totalLosses']}', Icons.close, Colors.red),
          _buildStatItem('Best Streak', '${_battleStats['longestStreak']}', Icons.local_fire_department, Colors.orange),
          _buildStatItem('Epic Moments', '${_battleStats['epicMoments']}', Icons.auto_awesome, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBattleActions(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (context.mounted) {
                context.go('/activities/new');
              }
            },
            icon: const Icon(Icons.shield, size: 22),
            label: Text(_valuesHealth < 50 ? 'HEAL HERO' : 'POWER UP'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TugColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 12,
              shadowColor: TugColors.primaryPurple.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (context.mounted) {
                context.go('/indulgences/new');
              }
            },
            icon: const Icon(Icons.visibility, size: 22),
            label: Text(_vicesHealth > 70 ? 'TRACK ENEMY' : 'LOG DEFEAT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TugColors.viceGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 12,
              shadowColor: TugColors.viceGreen.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods for dynamic theming
  Color _getBattleBackgroundColor(bool isDarkMode) {
    if (isDarkMode) return TugColors.darkSurface;
    return Colors.white;
  }

  Color _getBattleAccentColor() {
    switch (_battlePhase) {
      case "victory":
        return Colors.green;
      case "defeat":
        return Colors.red;
      case "battle":
        return Colors.orange;
      case "skirmish":
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _getBattleIcon() {
    switch (_battlePhase) {
      case "victory":
        return Icons.emoji_events;
      case "defeat":
        return Icons.warning;
      case "battle":
        return Icons.flash_on;
      case "skirmish":
        return Icons.flash_on;
      default:
        return Icons.balance;
    }
  }

  String _getBattlePhaseDescription() {
    switch (_battlePhase) {
      case "victory":
        return "🏆 GLORIOUS VICTORY ACHIEVED!";
      case "defeat":
        return "💔 Heroes never give up!";
      case "battle":
        return "⚔️ EPIC BATTLE IN PROGRESS!";
      case "skirmish":
        return "🎯 Preparing for battle...";
      default:
        return "🧘 Peace before the storm";
    }
  }
}