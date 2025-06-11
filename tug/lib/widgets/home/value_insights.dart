// A modern, visual alternative to quotes with meaningful insights
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tug/utils/animations.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/theme/text_styles.dart';
import 'package:tug/utils/responsive_utils.dart';

class ValueInsights extends StatefulWidget {
  final List<ValueInsight> insights;
  final void Function(ValueInsight)? onTap;
  
  const ValueInsights({
    super.key,
    required this.insights,
    this.onTap,
  });

  @override
  State<ValueInsights> createState() => _ValueInsightsState();
}

class _ValueInsightsState extends State<ValueInsights> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: _currentPage,
    );
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = ResponsiveUtils.getDeviceType(context);
    
    // Adapt height based on device type
    double cardHeight;
    switch (deviceType) {
      case DeviceType.mobile:
        cardHeight = 140;
        break;
      case DeviceType.tablet:
        cardHeight = 160;
        break;
      case DeviceType.desktop:
      case DeviceType.widescreen:
        cardHeight = 180;
        break;
    }
    
    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.insights.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
                _animationController.forward(from: 0.0);
              });
            },
            itemBuilder: (context, index) {
              final insight = widget.insights[index];
              
              return TugAnimations.fadeSlideIn(
                // Use staggered animations for a more dynamic feel
                delay: Duration(milliseconds: 100 * index),
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = _pageController.page! - index;
                      value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                    }
                    
                    return Transform.scale(
                      scale: value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: InsightCard(
                          insight: insight,
                          isDark: isDark,
                          onTap: widget.onTap != null ? () => widget.onTap!(insight) : null,
                          animation: _animationController,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        
        if (widget.insights.length > 1) ...[
          const SizedBox(height: 12),
          // Page indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.insights.length,
              (index) => _buildPageIndicator(index, isDark),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildPageIndicator(int index, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: index == _currentPage ? 20 : 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: index == _currentPage
            ? TugColors.primaryPurple
            : TugColors.primaryPurple.withOpacity(isDark ? 0.3 : 0.2),
        boxShadow: index == _currentPage
            ? [
                BoxShadow(
                  color: TugColors.primaryPurple.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class InsightCard extends StatelessWidget {
  final ValueInsight insight;
  final bool isDark;
  final VoidCallback? onTap;
  final Animation<double> animation;

  const InsightCard({
    super.key,
    required this.insight,
    required this.isDark,
    this.onTap,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              insight.color.withOpacity(isDark ? 0.3 : 0.1),
              insight.color.withOpacity(isDark ? 0.15 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: insight.color.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: insight.color.withOpacity(isDark ? 0.2 : 0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: _buildBackgroundPattern(insight.category),
              ),
              
              // Main content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Visual indicator
                    _buildVisualIndicator(insight),
                    
                    const SizedBox(width: 16),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Category label
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: insight.color.withOpacity(isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              insight.category.name,
                              style: TugTextStyles.label.copyWith(
                                color: insight.color,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 6),
                          
                          // Title with animation
                          Flexible(
                            child: AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: animation.value,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - animation.value) * 10),
                                    child: Text(
                                      insight.title,
                                      style: TugTextStyles.titleMedium.copyWith(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }
                            ),
                          ),
                          
                          const SizedBox(height: 2),
                          
                          // Short message
                          Flexible(
                            child: AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: Curves.easeOut.transform(animation.value),
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - animation.value) * 15),
                                    child: Text(
                                      insight.message,
                                      style: TugTextStyles.bodySmall.copyWith(
                                        color: isDark 
                                          ? Colors.white70 
                                          : Colors.black54,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Subtle indicator for interaction
                    Icon(
                      Icons.keyboard_arrow_right_rounded,
                      color: insight.color.withOpacity(0.5),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildVisualIndicator(ValueInsight insight) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return TugAnimations.pulsate(
          minScale: 0.95,
          maxScale: 1.05,
          addGlow: true,
          glowColor: insight.color,
          isDark: isDark,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color.lerp(insight.color, Colors.white, 0.3) ?? insight.color,
                  insight.color,
                ],
                stops: const [0.0, 1.0],
                radius: 0.8,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: insight.color.withOpacity(isDark ? 0.5 : 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(insight.category),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      }
    );
  }
  
  Widget _buildBackgroundPattern(InsightCategory category) {
    // Create a custom pattern based on category
    switch (category) {
      case InsightCategory.balance:
        return CustomPaint(
          painter: BalancePatternPainter(
            color: insight.color.withOpacity(isDark ? 0.07 : 0.04),
          ),
        );
      case InsightCategory.progress:
        return CustomPaint(
          painter: ProgressPatternPainter(
            color: insight.color.withOpacity(isDark ? 0.07 : 0.04),
          ),
        );
      case InsightCategory.achievement:
        return CustomPaint(
          painter: AchievementPatternPainter(
            color: insight.color.withOpacity(isDark ? 0.07 : 0.04),
          ),
        );
      default:
        return CustomPaint(
          painter: DefaultPatternPainter(
            color: insight.color.withOpacity(isDark ? 0.07 : 0.04),
          ),
        );
    }
  }
  
  IconData _getCategoryIcon(InsightCategory category) {
    switch (category) {
      case InsightCategory.balance:
        return Icons.balance_rounded;
      case InsightCategory.progress:
        return Icons.trending_up_rounded;
      case InsightCategory.achievement:
        return Icons.emoji_events_rounded;
      case InsightCategory.focus:
        return Icons.center_focus_strong_rounded;
      case InsightCategory.reflection:
        return Icons.psychology_rounded;
    }
  }
}

class ValueInsight {
  final String title;
  final String message;
  final Color color;
  final InsightCategory category;
  final dynamic data; // Optional data for more complex insights
  
  const ValueInsight({
    required this.title,
    required this.message,
    required this.color,
    required this.category,
    this.data,
  });
  
  // Factory method to create insights from different types of data
  factory ValueInsight.fromValue({
    required String valueName,
    required int statedImportance,
    required int actualMinutes,
    required int averageMinutes,
    required Color valueColor,
  }) {
    // Calculate balance score
    final statedPercent = statedImportance * 20; // 1-5 → 20-100%
    final actualPercent = (actualMinutes / averageMinutes) * 100;
    final difference = (actualPercent - statedPercent).abs();
    
    // Create insight based on difference
    if (difference <= 20) {
      return ValueInsight(
        title: "Good Balance: $valueName",
        message: "your actions align well with how important $valueName is to you.",
        color: valueColor,
        category: InsightCategory.balance,
      );
    } else if (actualPercent > statedPercent) {
      return ValueInsight(
        title: "Investing More In: $valueName",
        message: "You're spending more time on $valueName than its stated importance.",
        color: valueColor,
        category: InsightCategory.focus,
      );
    } else {
      return ValueInsight(
        title: "Opportunity: $valueName",
        message: "Consider if you want to spend more time on $valueName given its importance.",
        color: valueColor,
        category: InsightCategory.reflection,
      );
    }
  }
  
  factory ValueInsight.fromStreak({
    required String valueName,
    required int streakDays,
    required Color valueColor,
  }) {
    String title;
    String message;
    InsightCategory category;
    
    if (streakDays >= 30) {
      title = "Amazing Streak: $valueName";
      message = "$streakDays days consistent with $valueName. Outstanding commitment!";
      category = InsightCategory.achievement;
    } else if (streakDays >= 7) {
      title = "Building Momentum: $valueName";
      message = "You've been consistent with $valueName for $streakDays days!";
      category = InsightCategory.progress;
    } else {
      title = "Getting Started: $valueName";
      message = "You're building consistency with $valueName. Keep it up!";
      category = InsightCategory.progress;
    }
    
    return ValueInsight(
      title: title,
      message: message,
      color: valueColor,
      category: category,
      data: streakDays,
    );
  }
}

enum InsightCategory {
  balance,
  progress,
  achievement,
  focus,
  reflection,
}

// BACKGROUND PATTERN PAINTERS

class BalancePatternPainter extends CustomPainter {
  final Color color;
  
  BalancePatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    // Draw horizontal balance lines
    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.2 + i * 0.15);
      final startX = size.width * 0.1;
      final endX = size.width * 0.9;
      
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y),
        paint,
      );
    }
    
    // Draw vertical lines
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.9),
      paint,
    );
    
    // Draw circles at intersections
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.2 + i * 0.15);
      canvas.drawCircle(
        Offset(size.width * 0.5, y),
        3.0,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProgressPatternPainter extends CustomPainter {
  final Color color;
  
  ProgressPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    final path = Path();
    
    // Create a zig-zag upward trending line
    path.moveTo(size.width * 0.1, size.height * 0.8);
    
    for (int i = 1; i <= 8; i++) {
      final x = size.width * (0.1 + i * 0.1);
      final y = i.isEven
          ? size.height * (0.8 - i * 0.08)
          : size.height * (0.7 - i * 0.08);
      
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
    
    // Draw small circles at the points
    paint.style = PaintingStyle.fill;
    path.computeMetrics().forEach((metric) {
      final length = metric.length;
      for (int i = 0; i <= 8; i++) {
        final point = metric.getTangentForOffset(length * i / 8)?.position;
        if (point != null) {
          canvas.drawCircle(point, 2.0, paint);
        }
      }
    });
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AchievementPatternPainter extends CustomPainter {
  final Color color;
  
  AchievementPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw star shapes in background
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        final x = size.width * (0.2 + j * 0.3);
        final y = size.height * (0.2 + i * 0.2);
        
        _drawStar(canvas, Offset(x, y), 5 + (i % 3) * 3, paint);
      }
    }
  }
  
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final double rotation = math.pi / 2; // rotate 90 degrees
    
    for (int i = 0; i < 5; i++) {
      final double outerX = center.dx + radius * math.cos(rotation + i * math.pi * 2 / 5);
      final double outerY = center.dy + radius * math.sin(rotation + i * math.pi * 2 / 5);
      
      final double innerX = center.dx + radius * 0.4 * math.cos(rotation + (i + 0.5) * math.pi * 2 / 5);
      final double innerY = center.dy + radius * 0.4 * math.sin(rotation + (i + 0.5) * math.pi * 2 / 5);
      
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      
      path.lineTo(innerX, innerY);
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DefaultPatternPainter extends CustomPainter {
  final Color color;
  
  DefaultPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw a simple grid pattern
    for (int i = 0; i < 10; i++) {
      final position = size.width * i / 10;
      
      // Vertical lines
      canvas.drawLine(
        Offset(position, 0),
        Offset(position, size.height),
        paint,
      );
      
      // Horizontal lines
      canvas.drawLine(
        Offset(0, position * size.height / size.width),
        Offset(size.width, position * size.height / size.width),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}