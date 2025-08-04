// lib/widgets/balance/balance_dashboard.dart
import 'package:flutter/material.dart';
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
    // Calculate values score (positive activities)
    final valueActivity = widget.recentActivities.length;
    final totalValueTime = widget.recentActivities
        .fold(0, (sum, activity) => sum + activity.duration);
    
    // Calculate vices score (clean days vs indulgences)
    final totalIndulgences = widget.recentIndulgences.length;
    final cleanDays = widget.daysToShow - 
        widget.recentIndulgences.map((i) => i.date.day).toSet().length;
    
    // Normalize scores (0-1 range)
    final valueScore = math.min(1.0, (valueActivity * 0.1 + totalValueTime * 0.01) / 10);
    final viceScore = math.min(1.0, cleanDays / widget.daysToShow.toDouble());
    
    // Calculate overall balance (-1 to 1, where 0 is perfect balance)
    _balanceScore = (valueScore + viceScore - 1.0).clamp(-1.0, 1.0);
    
    // Determine dominant side
    if (_balanceScore > 0.3) {
      _dominantSide = "values";
    } else if (_balanceScore < -0.3) {
      _dominantSide = "vices";
    } else {
      _dominantSide = "balanced";
    }
    
    // Calculate balance streak (simplified - in real app, store in database)
    _balanceStreak = _balanceScore.abs() < 0.2 ? 5 : 0; // Mock data
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
      label: 'Balance Dashboard: $_dominantSide side is leading with ${_balanceStreak} day balance streak',
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
                'Balance Dashboard',
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
        return Container(
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
              
              // Left side (Vices)
              Positioned(
                left: 0,
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
                        'VICES',
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
              
              // Right side (Values)
              Positioned(
                right: 0,
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
                        'VALUES',
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
            'Values Side',
            '${widget.recentActivities.length}',
            'activities',
            TugColors.primaryPurple,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Balance Score',
            '${(_balanceScore * 100).abs().toInt()}%',
            _dominantSide,
            _getBalanceColor(),
            isDarkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Vices Side',
            '${widget.recentIndulgences.length}',
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
            onPressed: () {/* Navigate to values */},
            icon: const Icon(Icons.favorite, size: 18),
            label: const Text('Track Values'),
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
            onPressed: () {/* Navigate to vices */},
            icon: const Icon(Icons.psychology, size: 18),
            label: const Text('Track Vices'),
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