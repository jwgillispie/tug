// lib/widgets/balance/gamified_ai_coach.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../services/balance_insights_service.dart';
import '../../utils/theme/colors.dart';

/// GAMIFIED AI COACH
/// Revolutionary AI that talks like a battle strategist and gaming coach
/// This makes users feel like they have a personal trainer for their life balance
class GamefiedAICoach extends StatefulWidget {
  final List<BalanceInsight> insights;
  final double currentBalance;
  final int battleStreak;
  final String battlePhase;
  
  const GamefiedAICoach({
    super.key,
    required this.insights,
    required this.currentBalance,
    required this.battleStreak,
    required this.battlePhase,
  });

  @override
  State<GamefiedAICoach> createState() => _GamefiedAICoachState();
}

class _GamefiedAICoachState extends State<GamefiedAICoach>
    with TickerProviderStateMixin {
  
  late AnimationController _aiController;
  late AnimationController _typingController;
  late AnimationController _glowController;
  late AnimationController _orbController;
  
  late Animation<double> _aiPulse;
  late Animation<double> _typingAnimation;
  late Animation<double> _glowIntensity;
  late Animation<double> _orbRotation;
  
  int _currentInsightIndex = 0;
  String _currentCoachMessage = "";
  String _coachPersonality = "strategist"; // strategist, motivator, analyst
  bool _isTyping = false;
  final List<String> _coachQuotes = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _determineCoachPersonality();
    _generateCoachQuotes();
    _startCoachSequence();
  }

  void _setupAnimations() {
    _aiController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    
    _orbController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _aiPulse = Tween<double>(
      begin: 0.95,
      end: 1.12,
    ).animate(CurvedAnimation(
      parent: _aiController,
      curve: Curves.easeInOut,
    ));
    
    _typingAnimation = CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    );
    
    _glowIntensity = Tween<double>(
      begin: 0.3,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _orbRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _orbController,
      curve: Curves.linear,
    ));
  }

  void _determineCoachPersonality() {
    if (widget.battleStreak >= 10) {
      _coachPersonality = "motivator"; // You're doing great!
    } else if (widget.currentBalance < -0.5) {
      _coachPersonality = "strategist"; // Need tactical advice
    } else {
      _coachPersonality = "analyst"; // Balanced analysis
    }
  }

  void _generateCoachQuotes() {
    _coachQuotes.clear();
    
    switch (_coachPersonality) {
      case "strategist":
        _coachQuotes.addAll([
          "🎯 Analyzing battle patterns...",
          "⚔️ I see weakness in the enemy lines!",
          "🛡️ Time to fortify your defenses, warrior!",
          "📊 Victory requires strategic thinking!",
          "🎲 Every move counts in this battle!",
        ]);
        break;
      case "motivator":
        _coachQuotes.addAll([
          "🔥 You're absolutely crushing it!",
          "💪 That streak is LEGENDARY!",
          "🏆 Champions never give up!",
          "⭐ You're inspiring others with this performance!",
          "🚀 Keep this momentum going!",
        ]);
        break;
      case "analyst":
        _coachQuotes.addAll([
          "🤖 Processing your behavior patterns...",
          "📈 I've found optimization opportunities!",
          "🧠 Let's dive deep into the data...",
          "⚖️ Balance is the path to mastery!",
          "🔍 Precision beats power every time!",
        ]);
        break;
    }
    
    // Add contextual quotes based on insights
    for (final insight in widget.insights) {
      switch (insight.type) {
        case BalanceInsightType.moodCorrelation:
          _coachQuotes.add("😊 Your mood data reveals powerful patterns!");
          break;
        case BalanceInsightType.timePattern:
          _coachQuotes.add("⏰ Timing is everything in battle!");
          break;
        case BalanceInsightType.streak:
          _coachQuotes.add("🔥 That streak power is off the charts!");
          break;
        case BalanceInsightType.balance:
          _coachQuotes.add("⚖️ Balance mastery unlocked!");
          break;
        case BalanceInsightType.prediction:
          _coachQuotes.add("🔮 I can see your future victories!");
          break;
        case BalanceInsightType.weeklyPattern:
          _coachQuotes.add("📅 Weekly patterns reveal your true strength!");
          break;
      }
    }
    
    if (_coachQuotes.isEmpty) {
      _coachQuotes.add("🤖 Gathering intel on your progress...");
    }
  }

  void _startCoachSequence() {
    _currentCoachMessage = _coachQuotes.isNotEmpty ? _coachQuotes.first : "Loading...";
    
    // Start typing animation
    setState(() {
      _isTyping = true;
    });
    
    _typingController.forward().then((_) {
      setState(() {
        _isTyping = false;
      });
      _typingController.reset();
      
      // Auto-cycle through quotes
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          _cycleCoachMessage();
        }
      });
    });
  }

  void _cycleCoachMessage() {
    if (_coachQuotes.isNotEmpty) {
      setState(() {
        _currentInsightIndex = (_currentInsightIndex + 1) % _coachQuotes.length;
        _currentCoachMessage = _coachQuotes[_currentInsightIndex];
        _isTyping = true;
      });
      
      _typingController.forward().then((_) {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
          _typingController.reset();
          
          // Continue cycling
          Future.delayed(const Duration(seconds: 6), () {
            if (mounted) {
              _cycleCoachMessage();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _aiController.dispose();
    _typingController.dispose();
    _glowController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.insights.isEmpty && widget.battleStreak < 1) {
      return _buildInitialCoachState(isDarkMode);
    }
    
    return Semantics(
      label: 'Gamified AI Coach: $_coachPersonality personality. Current message: $_currentCoachMessage. ${widget.insights.length} insights available.',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildCoachHeader(isDarkMode),
            const SizedBox(height: 16),
            _buildCoachInterface(isDarkMode),
            const SizedBox(height: 12),
            if (widget.insights.isNotEmpty) _buildInsightCards(isDarkMode),
            const SizedBox(height: 16),
            _buildCoachActions(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCoachColor().withValues(alpha: 0.2),
            _getCoachColor().withValues(alpha: 0.1),
            _getCoachColor().withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _getCoachColor().withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getCoachColor().withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildCoachAvatar(isDarkMode),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getCoachName(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_getCoachColor(), _getCoachColor().withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _coachPersonality.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getCoachTitle(),
                  style: TextStyle(
                    fontSize: 14,
                    color: _getCoachColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildCoachStatus(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildCoachAvatar(bool isDarkMode) {
    return AnimatedBuilder(
      animation: Listenable.merge([_aiPulse, _orbRotation, _glowIntensity]),
      child: Stack(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _getCoachColor().withValues(alpha: 0.4),
                  _getCoachColor().withValues(alpha: 0.2),
                  _getCoachColor().withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getCoachColor().withValues(alpha: 0.6),
                width: 3,
              ),
            ),
            child: Icon(
              _getCoachIcon(),
              color: _getCoachColor(),
              size: 32,
            ),
          ),
          // Floating orbs around the avatar
          ...List.generate(3, (index) {
            final angle = (_orbRotation.value * 2 * math.pi) + (index * 2 * math.pi / 3);
            final radius = 40.0;
            final x = math.cos(angle) * radius;
            final y = math.sin(angle) * radius;
            
            return Positioned(
              left: 35 + x - 4,
              top: 35 + y - 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getCoachColor().withValues(alpha: _glowIntensity.value * 0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getCoachColor().withValues(alpha: _glowIntensity.value * 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      builder: (context, child) => Transform.scale(
        scale: _aiPulse.value,
        child: child,
      ),
    );
  }

  Widget _buildCoachStatus(bool isDarkMode) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ONLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'LVL ${widget.battleStreak + 1}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _getCoachColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildCoachInterface(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDarkMode ? TugColors.darkSurface : Colors.white,
            isDarkMode ? TugColors.darkSurface.withValues(alpha: 0.9) : Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getCoachColor().withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getCoachColor().withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: _getCoachColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Coach Message:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const Spacer(),
              if (_isTyping) _buildTypingIndicator(),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _typingAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCoachColor().withValues(alpha: 0.1),
                      _getCoachColor().withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getCoachColor().withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  _isTyping 
                      ? _currentCoachMessage.substring(0, (_currentCoachMessage.length * _typingAnimation.value).round())
                      : _currentCoachMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: _getCoachColor(),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final animValue = (_typingAnimation.value - delay).clamp(0.0, 1.0);
            final opacity = (math.sin(animValue * math.pi * 2) + 1) / 2;
            
            return Container(
              margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _getCoachColor().withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildInsightCards(bool isDarkMode) {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        itemCount: widget.insights.length,
        itemBuilder: (context, index) {
          final insight = widget.insights[index];
          return _buildGamefiedInsightCard(insight, isDarkMode);
        },
      ),
    );
  }

  Widget _buildGamefiedInsightCard(BalanceInsight insight, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            insight.priority.color.withValues(alpha: 0.15),
            insight.priority.color.withValues(alpha: 0.05),
            isDarkMode ? TugColors.darkSurface : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: insight.priority.color.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: insight.priority.color.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: insight.priority.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  insight.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: insight.priority.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        insight.priority.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: insight.priority.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.description,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  insight.priority.color.withValues(alpha: 0.1),
                  insight.priority.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: insight.priority.color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.actionSuggestion,
                    style: TextStyle(
                      fontSize: 12,
                      color: insight.priority.color,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachActions(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (context.mounted) {
                // Navigate based on coach recommendation
                final route = _getRecommendedAction();
                context.go(route);
              }
            },
            icon: Icon(_getActionIcon(), size: 20),
            label: Text(_getActionText()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getCoachColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: _getCoachColor().withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => _cycleCoachMessage(),
          style: IconButton.styleFrom(
            backgroundColor: _getCoachColor().withValues(alpha: 0.1),
            padding: const EdgeInsets.all(14),
          ),
          icon: Icon(
            Icons.refresh,
            color: _getCoachColor(),
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildInitialCoachState(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDarkMode ? TugColors.darkSurface : Colors.grey.shade50,
            isDarkMode ? TugColors.darkSurface.withValues(alpha: 0.8) : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _aiPulse,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.3),
                    Colors.purple.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                size: 48,
                color: Colors.purple,
              ),
            ),
            builder: (context, child) => Transform.scale(
              scale: _aiPulse.value,
              child: child,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'AI Coach Initializing...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your balance to unlock personalized coaching from your AI battle strategist!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (context.mounted) {
                context.go('/activities/new');
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Begin Training'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getCoachColor() {
    switch (_coachPersonality) {
      case "strategist":
        return Colors.blue;
      case "motivator":
        return Colors.orange;
      case "analyst":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCoachIcon() {
    switch (_coachPersonality) {
      case "strategist":
        return Icons.military_tech;
      case "motivator":
        return Icons.emoji_events;
      case "analyst":
        return Icons.analytics;
      default:
        return Icons.smart_toy;
    }
  }

  String _getCoachName() {
    switch (_coachPersonality) {
      case "strategist":
        return "Commander AI";
      case "motivator":
        return "Coach Champion";
      case "analyst":
        return "Professor Pixel";
      default:
        return "AI Assistant";
    }
  }

  String _getCoachTitle() {
    switch (_coachPersonality) {
      case "strategist":
        return "Battle Strategist & Tactical Advisor";
      case "motivator":
        return "Motivation Specialist & Streak Master";
      case "analyst":
        return "Data Analyst & Pattern Detective";
      default:
        return "Your Personal AI Coach";
    }
  }

  String _getRecommendedAction() {
    if (widget.currentBalance < -0.5) {
      return '/activities/new';
    } else if (widget.insights.isNotEmpty) {
      return '/progress';
    } else {
      return '/social';
    }
  }

  IconData _getActionIcon() {
    if (widget.currentBalance < -0.5) {
      return Icons.shield;
    } else if (widget.insights.isNotEmpty) {
      return Icons.analytics;
    } else {
      return Icons.people;
    }
  }

  String _getActionText() {
    if (widget.currentBalance < -0.5) {
      return 'TRAIN NOW';
    } else if (widget.insights.isNotEmpty) {
      return 'VIEW ANALYTICS';
    } else {
      return 'JOIN COMMUNITY';
    }
  }
}