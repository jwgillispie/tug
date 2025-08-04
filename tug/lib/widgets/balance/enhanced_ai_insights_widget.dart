// lib/widgets/balance/enhanced_ai_insights_widget.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/balance_insights_service.dart';
import '../../utils/theme/colors.dart';

class EnhancedAIInsightsWidget extends StatefulWidget {
  final List<BalanceInsight> insights;
  
  const EnhancedAIInsightsWidget({
    super.key,
    required this.insights,
  });

  @override
  State<EnhancedAIInsightsWidget> createState() => _EnhancedAIInsightsWidgetState();
}

class _EnhancedAIInsightsWidgetState extends State<EnhancedAIInsightsWidget>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _aiController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  
  late Animation<double> _aiPulse;
  late Animation<double> _slideAnimation;
  late Animation<double> _glowAnimation;
  
  int _currentInsight = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _aiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _aiPulse = Tween<double>(
      begin: 0.95,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _aiController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _aiController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.insights.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }
    
    return Semantics(
      label: 'Enhanced AI Insights: ${widget.insights.length} personalized balance insights powered by artificial intelligence',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAIHeader(isDarkMode),
            const SizedBox(height: 16),
            _buildInsightsCarousel(isDarkMode),
            const SizedBox(height: 12),
            _buildInsightIndicators(isDarkMode),
            const SizedBox(height: 12),
            _buildActionableButtons(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildAIHeader(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _aiPulse,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.3),
                  Colors.blue.withValues(alpha: 0.1),
                  Colors.pink.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Colors.purple,
                  size: 28,
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.pink.withValues(alpha: _glowAnimation.value),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withValues(alpha: _glowAnimation.value),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ai coach',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.pink],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SMART',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'personalized insights from your balance patterns',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.1),
                  Colors.pink.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.purple,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.insights.length}',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      builder: (context, child) => Transform.scale(
        scale: _aiPulse.value,
        child: child,
      ),
    );
  }

  Widget _buildInsightsCarousel(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      child: SizedBox(
        height: 200,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentInsight = index;
            });
          },
          itemCount: widget.insights.length,
          itemBuilder: (context, index) {
            final insight = widget.insights[index];
            return _buildEnhancedInsightCard(insight, isDarkMode);
          },
        ),
      ),
      builder: (context, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: child,
      ),
    );
  }

  Widget _buildEnhancedInsightCard(BalanceInsight insight, bool isDarkMode) {
    final isHighPriority = insight.priority == BalanceInsightPriority.high;
    
    return Semantics(
      label: '${insight.priority.displayName}: ${insight.title}. ${insight.description}. Suggestion: ${insight.actionSuggestion}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDarkMode ? TugColors.darkSurface : Colors.white,
              isDarkMode 
                  ? TugColors.darkSurface.withValues(alpha: 0.9)
                  : Colors.grey.shade50,
              if (isHighPriority) insight.priority.color.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: insight.priority.color.withValues(alpha: 0.15),
              blurRadius: isHighPriority ? 25 : 15,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: insight.priority.color.withValues(alpha: isHighPriority ? 0.4 : 0.2),
            width: isHighPriority ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (isHighPriority) _buildHighPriorityGlow(insight.priority.color),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInsightHeader(insight, isDarkMode),
                  const SizedBox(height: 12),
                  _buildInsightContent(insight, isDarkMode),
                  const Spacer(),
                  _buildActionSuggestion(insight, isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighPriorityGlow(Color color) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: RadialGradient(
                center: Alignment.topRight,
                colors: [
                  color.withValues(alpha: _glowAnimation.value * 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightHeader(BalanceInsight insight, bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: insight.priority.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: insight.priority.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            insight.icon,
            style: const TextStyle(fontSize: 20),
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
                  color: isDarkMode 
                      ? TugColors.darkTextPrimary 
                      : TugColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      insight.priority.color.withValues(alpha: 0.2),
                      insight.priority.color.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  insight.priority.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    color: insight.priority.color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (insight.priority == BalanceInsightPriority.high)
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: _glowAnimation.value * 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.priority_high,
                  color: Colors.red,
                  size: 16,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInsightContent(BalanceInsight insight, bool isDarkMode) {
    return Text(
      insight.description,
      style: TextStyle(
        fontSize: 14,
        color: isDarkMode 
            ? TugColors.darkTextSecondary 
            : TugColors.lightTextSecondary,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionSuggestion(BalanceInsight insight, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            insight.priority.color.withValues(alpha: 0.08),
            insight.priority.color.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: insight.priority.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: insight.priority.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.lightbulb,
              size: 16,
              color: insight.priority.color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insight.actionSuggestion,
              style: TextStyle(
                fontSize: 12,
                color: insight.priority.color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightIndicators(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.insights.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentInsight == index ? 24 : 10,
          height: 10,
          decoration: BoxDecoration(
            gradient: _currentInsight == index 
                ? LinearGradient(
                    colors: [
                      widget.insights[index].priority.color,
                      widget.insights[index].priority.color.withValues(alpha: 0.7),
                    ],
                  )
                : null,
            color: _currentInsight == index
                ? null
                : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
            borderRadius: BorderRadius.circular(5),
            boxShadow: _currentInsight == index ? [
              BoxShadow(
                color: widget.insights[index].priority.color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
        ),
      ),
    );
  }

  Widget _buildActionableButtons(bool isDarkMode) {
    if (widget.insights.isEmpty) return const SizedBox.shrink();
    
    final currentInsight = widget.insights[_currentInsight];
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to relevant section based on insight type
              String route = '/activities/new';
              switch (currentInsight.type) {
                case BalanceInsightType.moodCorrelation:
                case BalanceInsightType.timePattern:
                  route = '/activities/new';
                  break;
                case BalanceInsightType.streak:
                case BalanceInsightType.balance:
                  route = '/progress';
                  break;
                case BalanceInsightType.prediction:
                case BalanceInsightType.weeklyPattern:
                  route = '/social';
                  break;
              }
              
              if (context.mounted) {
                context.go(route);
              }
            },
            icon: const Icon(Icons.psychology, size: 18),
            label: const Text('act on insight'),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentInsight.priority.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
              shadowColor: currentInsight.priority.color.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () {
            if (_currentInsight < widget.insights.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          style: IconButton.styleFrom(
            backgroundColor: currentInsight.priority.color.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(12),
          ),
          icon: Icon(
            Icons.arrow_forward,
            color: currentInsight.priority.color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDarkMode ? TugColors.darkSurface : Colors.grey.shade50,
            isDarkMode ? TugColors.darkSurface.withValues(alpha: 0.8) : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode 
              ? Colors.grey.shade700 
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _aiPulse,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.2),
                    Colors.purple.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 48,
                color: Colors.purple.withValues(alpha: 0.7),
              ),
            ),
            builder: (context, child) => Transform.scale(
              scale: _aiPulse.value,
              child: child,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ai coach is learning',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode 
                  ? TugColors.darkTextPrimary 
                  : TugColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'track more activities and indulgences to unlock personalized insights from your ai coach. the more data you provide, the smarter your insights become!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode 
                  ? TugColors.darkTextSecondary 
                  : TugColors.lightTextSecondary,
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
            icon: const Icon(Icons.add),
            label: const Text('start tracking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}