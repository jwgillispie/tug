// lib/widgets/balance/revolutionary_balance_widget.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../utils/theme/colors.dart';
import '../../utils/quantum_effects.dart';
import '../../models/value_model.dart';
import '../../models/vice_model.dart';
import '../../models/activity_model.dart';
import '../../models/indulgence_model.dart';

class RevolutionaryBalanceWidget extends StatefulWidget {
  final List<ValueModel> values;
  final List<ViceModel> vices;
  final List<ActivityModel> recentActivities;
  final List<IndulgenceModel> recentIndulgences;
  final int daysToShow;
  
  const RevolutionaryBalanceWidget({
    super.key,
    required this.values,
    required this.vices,
    required this.recentActivities,
    required this.recentIndulgences,
    this.daysToShow = 7,
  });

  @override
  State<RevolutionaryBalanceWidget> createState() => _RevolutionaryBalanceWidgetState();
}

class _RevolutionaryBalanceWidgetState extends State<RevolutionaryBalanceWidget>
    with TickerProviderStateMixin {
  
  // Animation controllers for epic effects
  late AnimationController _battleController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late AnimationController _ropeController;
  
  // Animations
  late Animation<double> _battleIntensity;
  late Animation<double> _characterPulse;
  late Animation<double> _sparkleOpacity;
  late Animation<double> _ropeShake;
  
  // Game state
  double _balanceScore = 0.0;
  int _balanceStreak = 0;
  String _dominantSide = "balanced";
  String _battleStatus = "The battle rages on!";
  int _valuesEnergy = 0;
  int _vicesEnergy = 0;
  bool _isInBattle = false;

  @override
  void initState() {
    super.initState();
    _setupEpicAnimations();
    _calculateBattleState();
  }

  void _setupEpicAnimations() {
    // Battle intensity animation (for dramatic effect)
    _battleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Character pulse animation (shows energy levels)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    // Sparkle effects for achievements
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Rope shake animation for dramatic moments
    _ropeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _battleIntensity = CurvedAnimation(
      parent: _battleController,
      curve: Curves.elasticOut,
    );
    
    _characterPulse = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _sparkleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));
    
    _ropeShake = Tween<double>(
      begin: -3.0,
      end: 3.0,
    ).animate(CurvedAnimation(
      parent: _ropeController,
      curve: Curves.elasticInOut,
    ));
    
    _battleController.forward();
  }

  void _calculateBattleState() {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: widget.daysToShow));
    
    // Filter recent data
    final recentActivities = widget.recentActivities
        .where((a) => a.date.isAfter(cutoffDate))
        .toList();
    final recentIndulgences = widget.recentIndulgences
        .where((i) => i.date.isAfter(cutoffDate))
        .toList();
    
    // Calculate energy levels (0-100 for each side)
    _valuesEnergy = _calculateValuesEnergy(recentActivities);
    _vicesEnergy = _calculateVicesEnergy(recentIndulgences);
    
    // Calculate battle balance
    final totalEnergy = _valuesEnergy + _vicesEnergy;
    if (totalEnergy > 0) {
      _balanceScore = ((_valuesEnergy - _vicesEnergy) / totalEnergy.toDouble()).clamp(-1.0, 1.0);
    } else {
      _balanceScore = 0.0;
    }
    
    // Determine battle outcome
    _updateBattleStatus();
    _calculateStreak(recentActivities, recentIndulgences);
    
    // Trigger dramatic effects for major shifts
    if (_balanceScore.abs() > 0.7) {
      _ropeController.forward().then((_) => _ropeController.reset());
      if (_balanceScore > 0.8) {
        _sparkleController.forward().then((_) => _sparkleController.reset());
      }
    }
  }

  int _calculateValuesEnergy(List<ActivityModel> activities) {
    if (activities.isEmpty) return 0;
    
    // Energy from activity count (0-50 points)
    final activityEnergy = math.min(50, activities.length * 8);
    
    // Energy from time invested (0-30 points)
    final totalMinutes = activities.fold(0, (sum, a) => sum + a.duration);
    final timeEnergy = math.min(30, (totalMinutes / 60).round());
    
    // Energy from consistency (0-20 points)
    final uniqueDays = activities
        .map((a) => DateTime(a.date.year, a.date.month, a.date.day))
        .toSet().length;
    final consistencyEnergy = math.min(20, uniqueDays * 3);
    
    return activityEnergy + timeEnergy + consistencyEnergy;
  }

  int _calculateVicesEnergy(List<IndulgenceModel> indulgences) {
    if (indulgences.isEmpty) return 0;
    
    // Vice energy from frequency (0-60 points)
    final frequencyEnergy = math.min(60, indulgences.length * 10);
    
    // Energy from recent activity (more recent = more energy)
    final now = DateTime.now();
    int recencyEnergy = 0;
    for (final indulgence in indulgences) {
      final daysSince = now.difference(indulgence.date).inDays;
      if (daysSince <= 1) {
        recencyEnergy += 15;
      } else if (daysSince <= 3) {
        recencyEnergy += 8;
      } else if (daysSince <= 7) {
        recencyEnergy += 3;
      }
    }
    recencyEnergy = math.min(40, recencyEnergy);
    
    return frequencyEnergy + recencyEnergy;
  }

  void _updateBattleStatus() {
    if (_balanceScore > 0.7) {
      _dominantSide = "values";
      _battleStatus = "🏆 Values Warriors are dominating!";
      _isInBattle = false;
    } else if (_balanceScore < -0.7) {
      _dominantSide = "vices";
      _battleStatus = "⚠️ Vice Demons are taking over!";
      _isInBattle = false;
    } else if (_balanceScore.abs() < 0.2) {
      _dominantSide = "balanced";
      _battleStatus = "⚖️ Perfect balance achieved!";
      _isInBattle = false;
    } else {
      _dominantSide = _balanceScore > 0 ? "values" : "vices";
      _battleStatus = "⚔️ Epic battle in progress!";
      _isInBattle = true;
    }
  }

  void _calculateStreak(List<ActivityModel> activities, List<IndulgenceModel> indulgences) {
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
      
      // Balanced day = has activity AND low indulgences, OR clean recovery day
      final dailyBalance = dayActivities > 0 ? dayActivities / math.max(1, dayIndulgences) : 0;
      final isBalanced = dailyBalance >= 1.0 || (dayIndulgences == 0 && i < 3);
      
      if (isBalanced) {
        streak++;
      } else {
        break;
      }
    }
    
    _balanceStreak = streak;
  }

  @override
  void dispose() {
    _battleController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    _ropeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: 'Revolutionary Balance Dashboard: $_battleStatus. Values energy: $_valuesEnergy, Vices energy: $_vicesEnergy. Balance streak: $_balanceStreak days',
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDarkMode ? TugColors.darkSurface : Colors.white,
              isDarkMode 
                  ? TugColors.darkSurface.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _getBattleColor().withValues(alpha: 0.2),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: _getBattleColor().withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            _buildBattleHeader(isDarkMode),
            const SizedBox(height: 24),
            _buildEpicBattlefield(isDarkMode),
            const SizedBox(height: 24),
            _buildEnergyBars(isDarkMode),
            const SizedBox(height: 20),
            _buildActionButtons(isDarkMode),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _characterPulse,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getBattleColor().withValues(alpha: 0.2),
                        _getBattleColor().withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getBattleColor().withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getBattleIcon(),
                    color: _getBattleColor(),
                    size: 32,
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
                      'balance battlefield',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _battleStatus,
                      style: TextStyle(
                        fontSize: 14,
                        color: _getBattleColor(),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStreakBadge(),
            ],
          ),
          const SizedBox(height: 16),
          if (_isInBattle) _buildBattleIntensityIndicator(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStreakBadge() {
    return AnimatedBuilder(
      animation: _sparkleOpacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withValues(alpha: 0.2),
              Colors.orange.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              '${_balanceStreak}d',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
      builder: (context, child) => Opacity(
        opacity: _sparkleOpacity.value > 0.5 ? 1.0 : 0.9,
        child: Transform.scale(
          scale: 1.0 + (_sparkleOpacity.value * 0.1),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBattleIntensityIndicator(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _battleIntensity,
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              TugColors.primaryPurple.withValues(alpha: 0.3),
              Colors.red.withValues(alpha: 0.5),
              TugColors.viceGreen.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: LinearProgressIndicator(
          value: _battleIntensity.value,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation(_getBattleColor()),
        ),
      ),
      builder: (context, child) => child!,
    );
  }

  Widget _buildEpicBattlefield(bool isDarkMode) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ropeShake, _battleIntensity]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_ropeShake.value, 0),
          child: SizedBox(
            height: 140,
            child: Stack(
              children: [
                _buildBattleBackground(isDarkMode),
                _buildValuesWarrior(isDarkMode),
                _buildViceDemons(isDarkMode),
                _buildEpicRope(isDarkMode),
                if (_sparkleOpacity.value > 0) _buildVictoryEffects(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBattleBackground(bool isDarkMode) {
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              TugColors.primaryPurple.withValues(alpha: 0.4),
              _getBattleColor().withValues(alpha: 0.3),
              TugColors.viceGreen.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: _getBattleColor().withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValuesWarrior(bool isDarkMode) {
    return Positioned(
      left: 20,
      top: 10,
      child: AnimatedBuilder(
        animation: _characterPulse,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TugColors.primaryPurple.withValues(alpha: 0.2),
                    TugColors.primaryPurple.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TugColors.primaryPurple.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Text(
                'values ⚔️',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: TugColors.primaryPurple,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: TugColors.primaryPurple.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.shield,
                color: TugColors.primaryPurple,
                size: 36,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Energy: $_valuesEnergy',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: TugColors.primaryPurple,
              ),
            ),
          ],
        ),
        builder: (context, child) => Transform.scale(
          scale: 1.0 + (_valuesEnergy / 200.0) * _characterPulse.value * 0.2,
          child: child,
        ),
      ),
    );
  }

  Widget _buildViceDemons(bool isDarkMode) {
    return Positioned(
      right: 20,
      top: 10,
      child: AnimatedBuilder(
        animation: _characterPulse,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TugColors.viceGreen.withValues(alpha: 0.2),
                    TugColors.viceGreen.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TugColors.viceGreen.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Text(
                '👹 vices',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: TugColors.viceGreen,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: TugColors.viceGreen.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.psychology,
                color: TugColors.viceGreen,
                size: 36,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Energy: $_vicesEnergy',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: TugColors.viceGreen,
              ),
            ),
          ],
        ),
        builder: (context, child) => Transform.scale(
          scale: 1.0 + (_vicesEnergy / 200.0) * _characterPulse.value * 0.2,
          child: child,
        ),
      ),
    );
  }

  Widget _buildEpicRope(bool isDarkMode) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ropePosition = (screenWidth * 0.5) - 60 + (_balanceScore * 100);
    
    return Positioned(
      left: ropePosition,
      top: 55,
      child: QuantumEffects.floating(
        offset: 4,
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                _getBattleColor(),
                _getBattleColor().withValues(alpha: 0.7),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getBattleColor().withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.anchor,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryEffects() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _sparkleOpacity,
        builder: (context, child) {
          return Opacity(
            opacity: _sparkleOpacity.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  colors: [
                    Colors.amber.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnergyBars(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildEnergyBar(
              'Values Power',
              _valuesEnergy,
              TugColors.primaryPurple,
              isDarkMode,
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getBattleColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBattleColor().withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Text(
              '${(_balanceScore * 100).toInt()}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getBattleColor(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildEnergyBar(
              'Vice Power',
              _vicesEnergy,
              TugColors.viceGreen,
              isDarkMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyBar(String label, int energy, Color color, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            widthFactor: math.min(1.0, energy / 100.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$energy/100',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (context.mounted) {
                  context.go('/activities/new');
                }
              },
              icon: const Icon(Icons.add_circle, size: 20),
              label: const Text('boost values'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TugColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: TugColors.primaryPurple.withValues(alpha: 0.4),
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
              icon: const Icon(Icons.remove_circle, size: 20),
              label: const Text('track vices'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TugColors.viceGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: TugColors.viceGreen.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBattleColor() {
    if (_balanceScore > 0.4) return TugColors.primaryPurple;
    if (_balanceScore < -0.4) return TugColors.viceGreen;
    if (_isInBattle) return Colors.orange;
    return Colors.amber;
  }

  IconData _getBattleIcon() {
    if (_dominantSide == "values") return Icons.emoji_events;
    if (_dominantSide == "vices") return Icons.warning;
    if (_isInBattle) return Icons.flash_on;
    return Icons.balance;
  }
}