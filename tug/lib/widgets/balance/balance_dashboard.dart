// lib/widgets/balance/balance_dashboard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../utils/theme/colors.dart';
import '../../utils/quantum_effects.dart';
import '../../models/value_model.dart';
import '../../models/vice_model.dart';
import '../../models/activity_model.dart';
import '../../models/indulgence_model.dart';

class BalanceDashboard extends StatefulWidget {
  final List<ValueModel> values;
  final List<ViceModel> vices;
  final List<ActivityModel> recentActivities;
  final List<IndulgenceModel> recentIndulgences;
  final int daysToShow;
  
  const BalanceDashboard({
    super.key,
    required this.values,
    required this.vices,
    required this.recentActivities,
    required this.recentIndulgences,
    this.daysToShow = 7,
  });

  @override
  State<BalanceDashboard> createState() => _BalanceDashboardState();
}

class _BalanceDashboardState extends State<BalanceDashboard>
    with TickerProviderStateMixin {
  late AnimationController _ropeAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _ropeAnimation;
  late Animation<double> _pulseAnimation;
  
  double _balanceScore = 0.0; // -1.0 (vices winning) to 1.0 (values winning)
  int _balanceStreak = 0;
  String _dominantSide = "balanced";

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _calculateBalance();
  }

  void _setupAnimations() {
    _ropeAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _ropeAnimation = CurvedAnimation(
      parent: _ropeAnimationController,
      curve: Curves.elasticOut,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _ropeAnimationController.forward();
  }

  void _calculateBalance() {
    // Get recent data for the specified time period
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: widget.daysToShow));
    
    // Filter activities and indulgences within the time period
    final recentActivities = widget.recentActivities
        .where((a) => a.date.isAfter(cutoffDate))
        .toList();
    final recentIndulgences = widget.recentIndulgences
        .where((i) => i.date.isAfter(cutoffDate))
        .toList();
    
    // Calculate value strength (activities and time spent)
    final totalActivities = recentActivities.length;
    final totalValueMinutes = recentActivities
        .fold(0, (sum, activity) => sum + activity.duration);
    
    // Calculate vice pressure (indulgences frequency and recency)
    final totalIndulgences = recentIndulgences.length;
    final uniqueIndulgenceDays = recentIndulgences
        .map((i) => DateTime(i.date.year, i.date.month, i.date.day))
        .toSet().length;
    
    // Create a balanced scoring system
    // Values side: activities per day + time investment
    final avgActivitiesPerDay = totalActivities / widget.daysToShow.toDouble();
    final avgMinutesPerDay = totalValueMinutes / widget.daysToShow.toDouble();
    final valueStrength = (avgActivitiesPerDay * 0.7 + avgMinutesPerDay / 60 * 0.3).clamp(0.0, 3.0);
    
    // Vices side: indulgence frequency and consistency
    final avgIndulgencesPerDay = totalIndulgences / widget.daysToShow.toDouble();
    final indulgenceConsistency = uniqueIndulgenceDays / widget.daysToShow.toDouble();
    final viceStrength = (avgIndulgencesPerDay * 0.8 + indulgenceConsistency * 0.2).clamp(0.0, 3.0);
    
    // Calculate balance score (-1.0 = vices winning, +1.0 = values winning, 0 = balanced)
    if (valueStrength + viceStrength == 0) {
      _balanceScore = 0.0; // No data = balanced
    } else {
      _balanceScore = ((valueStrength - viceStrength) / (valueStrength + viceStrength)).clamp(-1.0, 1.0);
    }
    
    // Determine dominant side with better thresholds
    if (_balanceScore > 0.2) {
      _dominantSide = "values";
    } else if (_balanceScore < -0.2) {
      _dominantSide = "vices";
    } else {
      _dominantSide = "balanced";
    }
    
    // Calculate balance streak (count consecutive balanced days)
    _balanceStreak = _calculateBalanceStreak(recentActivities, recentIndulgences);
  }
  
  int _calculateBalanceStreak(List<ActivityModel> activities, List<IndulgenceModel> indulgences) {
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
      
      // Balanced day = has activity OR zero indulgences (recovery day)
      final isBalanced = (dayActivities > 0) || (dayIndulgences == 0 && i < 7); // Allow clean days
      
      if (isBalanced) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  @override
  void dispose() {
    _ropeAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: 'balance dashboard: $_dominantSide side is leading with ${_balanceStreak} day balance streak',
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getBalanceColor().withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _getBalanceColor().withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(isDarkMode),
            const SizedBox(height: 24),
            _buildTugOfWarVisualization(isDarkMode),
            const SizedBox(height: 24),
            _buildBalanceStats(isDarkMode),
            const SizedBox(height: 16),
            _buildActionButtons(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getBalanceColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBalanceColor().withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              _getBalanceIcon(),
              color: _getBalanceColor(),
              size: 28,
            ),
          ),
          builder: (context, child) => Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'balance dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getBalanceMessage(),
                style: TextStyle(
                  fontSize: 14,
                  color: _getBalanceColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getBalanceColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getBalanceColor().withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${_balanceStreak}d',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getBalanceColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTugOfWarVisualization(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _ropeAnimation,
      builder: (context, child) {
        return SizedBox(
          height: 120,
          child: Stack(
            children: [
              // Background track
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TugColors.viceGreen.withValues(alpha: 0.3),
                        Colors.grey.withValues(alpha: 0.2),
                        TugColors.primaryPurple.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              
              // Left side (Values) - Positive side
              Positioned(
                left: 0,
                top: 20,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: TugColors.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'values',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: TugColors.primaryPurple,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.favorite,
                      color: TugColors.primaryPurple,
                      size: 32,
                    ),
                  ],
                ),
              ),
              
              // Right side (Vices) - Negative side
              Positioned(
                right: 0,
                top: 20,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: TugColors.viceGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'vices',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: TugColors.viceGreen,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.psychology,
                      color: TugColors.viceGreen,
                      size: 32,
                    ),
                  ],
                ),
              ),
              
              // Center rope/handle
              Positioned(
                left: MediaQuery.of(context).size.width * 0.5 - 40 + (_balanceScore * 80),
                top: 45,
                child: QuantumEffects.floating(
                  offset: 3,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _getBalanceColor(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getBalanceColor().withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceStats(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'values side',
            '${widget.recentActivities.where((a) => DateTime.now().difference(a.date).inDays <= widget.daysToShow).length}',
            'activities',
            TugColors.primaryPurple,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'balance score',
            '${(_balanceScore * 100).toInt()}%',
            _dominantSide,
            _getBalanceColor(),
            isDarkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'vices side',
            '${widget.recentIndulgences.where((i) => DateTime.now().difference(i.date).inDays <= widget.daysToShow).length}',
            'indulgences',
            TugColors.viceGreen,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              fontSize: 12,
              color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to values input/tracking screen
              if (context.mounted) {
                context.go('/activities/new');
              }
            },
            icon: const Icon(Icons.favorite, size: 18),
            label: const Text('track values'),
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
              // Navigate to vices tracking screen
              if (context.mounted) {
                context.go('/indulgences/new');
              }
            },
            icon: const Icon(Icons.psychology, size: 18),
            label: const Text('track vices'),
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

  Color _getBalanceColor() {
    if (_balanceScore > 0.3) return TugColors.primaryPurple;
    if (_balanceScore < -0.3) return TugColors.viceGreen;
    return Colors.amber;
  }

  IconData _getBalanceIcon() {
    if (_dominantSide == "values") return Icons.trending_up;
    if (_dominantSide == "vices") return Icons.trending_down;
    return Icons.balance;
  }

  String _getBalanceMessage() {
    if (_dominantSide == "values") return "Values are winning! 💪";
    if (_dominantSide == "vices") return "Vices need attention 🎯";
    return "Perfectly balanced ⚖️";
  }
}