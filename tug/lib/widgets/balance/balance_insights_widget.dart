// lib/widgets/balance/balance_insights_widget.dart
import 'package:flutter/material.dart';
import '../../services/balance_insights_service.dart';
import '../../utils/theme/colors.dart';
import '../../utils/quantum_effects.dart';

class BalanceInsightsWidget extends StatefulWidget {
  final List<BalanceInsight> insights;
  
  const BalanceInsightsWidget({
    super.key,
    required this.insights,
  });

  @override
  State<BalanceInsightsWidget> createState() => _BalanceInsightsWidgetState();
}

class _BalanceInsightsWidgetState extends State<BalanceInsightsWidget>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentInsight = 0;
  late AnimationController _slideController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.insights.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }
    
    return Semantics(
      label: 'AI Insights: ${widget.insights.length} personalized insights about your balance',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDarkMode),
            const SizedBox(height: 16),
            _buildInsightsCarousel(isDarkMode),
            const SizedBox(height: 12),
            _buildInsightIndicators(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        QuantumEffects.floating(
          offset: 2,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.2),
                  Colors.blue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.purple,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                ),
              ),
              Text(
                'Personalized patterns from your balance data',
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
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${widget.insights.length}',
            style: const TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCarousel(bool isDarkMode) {
    return SizedBox(
      height: 160,
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
          return AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _slideController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _slideController,
                    curve: Curves.easeOut,
                  )),
                  child: _buildInsightCard(insight, isDarkMode),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInsightCard(BalanceInsight insight, bool isDarkMode) {
    return Semantics(
      label: '${insight.priority.displayName}: ${insight.title}. ${insight.description}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDarkMode ? TugColors.darkSurface : Colors.white,
              isDarkMode 
                  ? TugColors.darkSurface.withValues(alpha: 0.8)
                  : Colors.grey.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: insight.priority.color.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: insight.priority.color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  insight.icon,
                  style: const TextStyle(fontSize: 24),
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
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: insight.priority.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          insight.priority.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: insight.priority.color,
                            fontWeight: FontWeight.w600,
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
                color: isDarkMode 
                    ? TugColors.darkTextSecondary 
                    : TugColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: insight.priority.color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: insight.priority.color.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: insight.priority.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.actionSuggestion,
                      style: TextStyle(
                        fontSize: 12,
                        color: insight.priority.color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _currentInsight == index ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentInsight == index
                ? widget.insights[index].priority.color
                : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? TugColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
              ? Colors.grey.shade700 
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 48,
            color: isDarkMode 
                ? Colors.grey.shade500 
                : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Insights Coming Soon',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode 
                  ? TugColors.darkTextPrimary 
                  : TugColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track more activities and indulgences to unlock AI-powered insights about your balance patterns.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode 
                  ? TugColors.darkTextSecondary 
                  : TugColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}