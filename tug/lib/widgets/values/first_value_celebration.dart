// lib/widgets/values/first_value_celebration.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/theme/colors.dart';

class FirstValueCelebration extends StatefulWidget {
  final String valueName;
  final VoidCallback onDismiss;

  const FirstValueCelebration({
    Key? key,
    required this.valueName,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<FirstValueCelebration> createState() => _FirstValueCelebrationState();
}

class _FirstValueCelebrationState extends State<FirstValueCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  // For sparkle effect
  final List<Offset> _sparkles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Generate random sparkle positions
    for (int i = 0; i < 50; i++) {
      _sparkles.add(Offset(
        _random.nextDouble() * 400 - 200, 
        _random.nextDouble() * 400 - 200
      ));
    }
    
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
      begin:
      0.0,
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
  
  // Helper method to create a sparkle animation
  Widget _buildSparkle(Color color, double scale) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Stagger the sparkle animations
        final delay = scale * 0.2;
        final sparkleProgress = (_animationController.value - delay).clamp(0.0, 1.0);
        
        // Create growing and fading effect
        final opacity = sparkleProgress < 0.2 
            ? sparkleProgress * 5 // fade in
            : 1.0 - ((sparkleProgress - 0.2) / 0.8); // fade out
        
        // Size animation grows then shrinks
        final sizeFactor = sparkleProgress < 0.3 
            ? sparkleProgress * 3.33 // grow
            : 1.0 - ((sparkleProgress - 0.3) * 0.5); // shrink slowly
        
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: sizeFactor * scale,
            child: Icon(
              Icons.star,
              color: color,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: Colors.black54,
      child: Stack(
        children: [
          // Simpler sparkle effect using just a few positioned containers
          Positioned(
            left: MediaQuery.of(context).size.width * 0.3,
            top: MediaQuery.of(context).size.height * 0.3,
            child: _buildSparkle(Colors.yellow, 1.0),
          ),
          Positioned(
            right: MediaQuery.of(context).size.width * 0.25,
            top: MediaQuery.of(context).size.height * 0.4,
            child: _buildSparkle(Colors.pink, 0.8),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.2,
            bottom: MediaQuery.of(context).size.height * 0.25,
            child: _buildSparkle(TugColors.primaryPurple, 1.2),
          ),
          Positioned(
            right: MediaQuery.of(context).size.width * 0.3,
            bottom: MediaQuery.of(context).size.height * 0.3,
            child: _buildSparkle(TugColors.secondaryTeal, 0.9),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.5,
            top: MediaQuery.of(context).size.height * 0.2,
            child: _buildSparkle(Colors.blue, 1.3),
          ),
          Positioned(
            right: MediaQuery.of(context).size.width * 0.4,
            top: MediaQuery.of(context).size.height * 0.5,
            child: _buildSparkle(TugColors.primaryPurple, 1.1),
          ),
          
          // Celebration card with animation
          Center(
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
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  padding: const EdgeInsets.all(20),
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
                      const Icon(
                        Icons.celebration,
                        color: TugColors.primaryPurple,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Congratulations!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: TugColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TugColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: widget.onDismiss,
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}