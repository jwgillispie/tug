// lib/widgets/values/first_value_celebration.dart
import 'package:flutter/material.dart';
import '../../utils/theme/colors.dart';

class FirstValueCelebration extends StatefulWidget {
  final String valueName;
  final VoidCallback onDismiss;

  const FirstValueCelebration({
    super.key,
    required this.valueName,
    required this.onDismiss,
  });

  @override
  State<FirstValueCelebration> createState() => _FirstValueCelebrationState();
}

class _FirstValueCelebrationState extends State<FirstValueCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Scale animation for the card
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutQuad),
        ),
        weight: 40,
      ),
    ]).animate(_animationController);
    
    // Opacity animation for the card
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    
    // Start animations after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black54,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? TugColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top icon in a circular container
                  CircleAvatar(
                    backgroundColor: TugColors.primaryPurple.withOpacity(0.2),
                    radius: 36,
                    child: const Icon(
                      Icons.flag_circle,
                      color: TugColors.primaryPurple,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Main title text - explicitly setting all text styles to avoid inheritance
                  DefaultTextStyle(
                    style: const TextStyle(), // Reset any inherited styles
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Congrats on your first value!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : TugColors.primaryPurple,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle with no decoration
                  DefaultTextStyle(
                    style: const TextStyle(), // Reset any inherited styles
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'You just took your first step toward becoming more aligned with your true self. Get tuggin!',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          fontWeight: FontWeight.normal,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Button with custom styles
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TugColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: widget.onDismiss,
                      child: const DefaultTextStyle(
                        style: TextStyle(), // Reset any inherited styles
                        child: Text(
                          'Let\'s Do This!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}