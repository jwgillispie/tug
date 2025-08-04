import 'package:flutter/material.dart';
import '../../models/activity_model.dart';
import '../../models/vice_model.dart';
import '../../models/value_model.dart';
import '../../utils/theme/colors.dart';
import '../../utils/quantum_effects.dart';

/// 🤖 AI BATTLE COACH
/// Dynamic AI personality that adapts to user's battle performance
/// Provides tactical advice, motivation, and strategic insights
class AIBattleCoach extends StatefulWidget {
  final List<ValueModel> values;
  final List<ViceModel> vices;
  final List<ActivityModel> recentActivities;
  final List<dynamic> recentIndulgences;
  final double battleScore; // -1.0 to +1.0
  final int winStreak;
  final int daysToShow;

  const AIBattleCoach({
    super.key,
    required this.values,
    required this.vices,
    required this.recentActivities,
    required this.recentIndulgences,
    required this.battleScore,
    required this.winStreak,
    this.daysToShow = 7,
  });

  @override
  State<AIBattleCoach> createState() => _AIBattleCoachState();
}

class _AIBattleCoachState extends State<AIBattleCoach>
    with SingleTickerProviderStateMixin {
  
  // AI Coach personalities based on battle performance
  String _currentPersonality = "mentor";
  String _coachName = "sage";
  String _coachEmoji = "🧙‍♂️";
  Color _coachColor = Colors.blue;
  
  late AnimationController _coachController;
  late Animation<double> _coachAnimation;
  
  // Coach insights
  final List<CoachInsight> _insights = [];
  int _currentInsightIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _setupAnimation();
    _determineCoachPersonality();
    _generateCoachInsights();
  }

  void _setupAnimation() {
    _coachController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _coachAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _coachController,
      curve: Curves.easeInOut,
    ));
  }

  void _determineCoachPersonality() {
    final performance = widget.battleScore;
    final consistency = _calculateConsistency();
    final improvement = _calculateImprovement();
    
    if (widget.winStreak >= 7 && performance > 0.5) {
      // Legendary performance
      _currentPersonality = "champion";
      _coachName = "champion";
      _coachEmoji = "👑";
      _coachColor = Colors.amber;
    } else if (performance > 0.3 && consistency > 0.7) {
      // Strong consistent performance
      _currentPersonality = "warrior";
      _coachName = "sensei";
      _coachEmoji = "🥋";
      _coachColor = TugColors.primaryPurple;
    } else if (improvement > 0.2) {
      // Improving performance
      _currentPersonality = "coach";
      _coachName = "coach";
      _coachEmoji = "💪";
      _coachColor = Colors.green;
    } else if (performance < -0.3) {
      // Struggling performance
      _currentPersonality = "drill_sergeant";
      _coachName = "sergeant";
      _coachEmoji = "🔥";
      _coachColor = Colors.red;
    } else if (widget.recentActivities.isEmpty && widget.recentIndulgences.isEmpty) {
      // No activity
      _currentPersonality = "motivator";
      _coachName = "spark";
      _coachEmoji = "✨";
      _coachColor = Colors.orange;
    } else {
      // Default mentor
      _currentPersonality = "mentor";
      _coachName = "sage";
      _coachEmoji = "🧙‍♂️";
      _coachColor = Colors.blue;
    }
  }

  double _calculateConsistency() {
    if (widget.recentActivities.isEmpty) return 0.0;
    
    final uniqueDays = widget.recentActivities
        .map((a) => DateTime(a.date.year, a.date.month, a.date.day))
        .toSet().length;
    
    return uniqueDays / widget.daysToShow.toDouble();
  }

  double _calculateImprovement() {
    // Simplified improvement calculation
    // In a real app, you'd compare current period vs previous period
    final recentActivities = widget.recentActivities.length;
    final recentIndulgences = widget.recentIndulgences.length;
    
    if (recentActivities + recentIndulgences == 0) return 0.0;
    
    return (recentActivities - recentIndulgences) / 
           (recentActivities + recentIndulgences).toDouble();
  }

  void _generateCoachInsights() {
    _insights.clear();
    
    switch (_currentPersonality) {
      case "champion":
        _insights.addAll(_getChampionInsights());
        break;
      case "warrior":
        _insights.addAll(_getWarriorInsights());
        break;
      case "coach":
        _insights.addAll(_getCoachInsights());
        break;
      case "drill_sergeant":
        _insights.addAll(_getDrillSergeantInsights());
        break;
      case "motivator":
        _insights.addAll(_getMotivatorInsights());
        break;
      default:
        _insights.addAll(_getMentorInsights());
    }
    
    // Shuffle for variety
    _insights.shuffle();
  }

  List<CoachInsight> _getChampionInsights() {
    return [
      CoachInsight(
        type: CoachInsightType.celebration,
        title: "legendary warrior! 👑",
        message: "you've achieved battle mastery! your consistency and strength inspire others to greatness.",
        actionSuggestion: "consider mentoring others in your balance journey",
        priority: CoachPriority.high,
      ),
      CoachInsight(
        type: CoachInsightType.strategic,
        title: "maintain your throne",
        message: "even champions must stay vigilant. continue your daily practices to keep evil at bay.",
        actionSuggestion: "schedule one challenging value activity to maintain momentum",
        priority: CoachPriority.medium,
      ),
    ];
  }

  List<CoachInsight> _getWarriorInsights() {
    return [
      CoachInsight(
        type: CoachInsightType.tactical,
        title: "strong discipline, warrior! 🥋",
        message: "your consistent training shows. you're winning more battles than you're losing.",
        actionSuggestion: "focus on your strongest value to build an unbreakable streak",
        priority: CoachPriority.high,
      ),
      CoachInsight(
        type: CoachInsightType.strategic,
        title: "time for advanced techniques",
        message: "you're ready for the next level. try combining multiple values in single activities.",
        actionSuggestion: "plan a value activity that serves 2+ of your core values",
        priority: CoachPriority.medium,
      ),
    ];
  }

  List<CoachInsight> _getCoachInsights() {
    return [
      CoachInsight(
        type: CoachInsightType.encouragement,
        title: "great progress! 💪",
        message: "i see real improvement in your balance. you're building momentum nicely.",
        actionSuggestion: "keep this energy going with one more value activity today",
        priority: CoachPriority.high,
      ),
      CoachInsight(
        type: CoachInsightType.tactical,
        title: "sharpen your focus",
        message: "you're doing well, but consistency is key. try setting specific times for value activities.",
        actionSuggestion: "schedule your next value activity for a specific time today",
        priority: CoachPriority.medium,
      ),
    ];
  }

  List<CoachInsight> _getDrillSergeantInsights() {
    return [
      CoachInsight(
        type: CoachInsightType.challenge,
        title: "wake up call! 🔥",
        message: "the battle is being lost! you need immediate action to turn this around.",
        actionSuggestion: "complete one value activity RIGHT NOW to start your comeback",
        priority: CoachPriority.urgent,
      ),
      CoachInsight(
        type: CoachInsightType.toughLove,
        title: "no excuses, soldier!",
        message: "vices are winning because you're not fighting back. time to show what you're made of.",
        actionSuggestion: "commit to 3 value activities today - no compromises",
        priority: CoachPriority.urgent,
      ),
    ];
  }

  List<CoachInsight> _getMotivatorInsights() {
    return [
      CoachInsight(
        type: CoachInsightType.inspiration,
        title: "ready to begin? ✨",
        message: "every great warrior starts with a single step. your balance journey awaits!",
        actionSuggestion: "choose your easiest value and do one small activity right now",
        priority: CoachPriority.high,
      ),
      CoachInsight(
        type: CoachInsightType.encouragement,
        title: "your potential is limitless",
        message: "i sense great strength within you. all you need is to take the first brave step.",
        actionSuggestion: "spend just 15 minutes on any value activity to ignite your journey",
        priority: CoachPriority.high,
      ),
    ];
  }

  List<CoachInsight> _getMentorInsights() {
    return [
      CoachInsight(
        type: CoachInsightType.wisdom,
        title: "balance is a journey 🧙‍♂️",
        message: "every warrior faces ups and downs. what matters is continuing to fight for your values.",
        actionSuggestion: "reflect on which value needs your attention most today",
        priority: CoachPriority.medium,
      ),
      CoachInsight(
        type: CoachInsightType.tactical,
        title: "strategic wisdom",
        message: "consider the patterns in your battle. when do vices strike? when are values strongest?",
        actionSuggestion: "identify your most vulnerable time and plan a value activity then",
        priority: CoachPriority.medium,
      ),
    ];
  }

  void _nextInsight() {
    setState(() {
      _currentInsightIndex = (_currentInsightIndex + 1) % _insights.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_insights.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final currentInsight = _insights[_currentInsightIndex];
    
    return Semantics(
      label: 'ai battle coach $_coachName: ${currentInsight.title}. ${currentInsight.message}',
      child: Container(
        margin: const EdgeInsets.all(16),
        child: QuantumEffects.glassContainer(
          isDark: isDarkMode,
          borderRadius: BorderRadius.circular(16),
          gradientColors: [
            _coachColor.withValues(alpha: 0.1),
            _coachColor.withValues(alpha: 0.05),
          ],
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoachHeader(isDarkMode),
                const SizedBox(height: 12),
                _buildCoachInsight(currentInsight, isDarkMode),
                if (_insights.length > 1) ...[
                  const SizedBox(height: 12),
                  _buildInsightNavigation(isDarkMode),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoachHeader(bool isDarkMode) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _coachAnimation,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _coachColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _coachColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _coachEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          builder: (context, child) {
            return Transform.scale(
              scale: _coachAnimation.value,
              child: child,
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ai battle coach',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _coachColor,
                ),
              ),
              Text(
                _coachName,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _coachColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _currentPersonality.replaceAll('_', ' '),
            style: TextStyle(
              color: _coachColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoachInsight(CoachInsight insight, bool isDarkMode) {
    final priorityColor = _getPriorityColor(insight.priority);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                insight.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          insight.message,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
            height: 1.4,
          ),
        ),
        if (insight.actionSuggestion.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: priorityColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: priorityColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.actionSuggestion,
                    style: TextStyle(
                      fontSize: 13,
                      color: priorityColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInsightNavigation(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_currentInsightIndex + 1} of ${_insights.length}',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
          ),
        ),
        TextButton(
          onPressed: _nextInsight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'next insight',
                style: TextStyle(
                  color: _coachColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: _coachColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(CoachPriority priority) {
    switch (priority) {
      case CoachPriority.urgent:
        return Colors.red;
      case CoachPriority.high:
        return Colors.orange;
      case CoachPriority.medium:
        return Colors.blue;
      case CoachPriority.low:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _coachController.dispose();
    super.dispose();
  }
}

// Data models for coach insights
class CoachInsight {
  final CoachInsightType type;
  final String title;
  final String message;
  final String actionSuggestion;
  final CoachPriority priority;

  CoachInsight({
    required this.type,
    required this.title,
    required this.message,
    required this.actionSuggestion,
    required this.priority,
  });
}

enum CoachInsightType {
  celebration,
  encouragement,
  tactical,
  strategic,
  challenge,
  toughLove,
  inspiration,
  wisdom,
}

enum CoachPriority {
  urgent,
  high,
  medium,
  low,
}