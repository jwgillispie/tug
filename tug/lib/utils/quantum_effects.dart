import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'theme/colors.dart';

class QuantumEffects {
  // Mesmerizing particle system for backgrounds
  static Widget quantumParticleField({
    required Widget child,
    int particleCount = 50,
    bool isDark = false,
  }) {
    return Stack(
      children: [
        // Animated particle field
        ...List.generate(particleCount, (index) {
          return _QuantumParticle(
            key: ValueKey('particle_$index'),
            isDark: isDark,
            delay: Duration(milliseconds: index * 100),
          );
        }),
        child,
      ],
    );
  }

  // Spectacular glassmorphism container
  static Widget glassContainer({
    required Widget child,
    double blur = 15,
    double opacity = 0.15,
    Color? borderColor,
    BorderRadius? borderRadius,
    List<Color>? gradientColors,
    bool isDark = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors ?? [
            (isDark ? TugColors.darkSurface : Colors.white).withValues(alpha: opacity),
            (isDark ? TugColors.darkSurfaceVariant : TugColors.lightSurfaceVariant).withValues(alpha: opacity * 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.3)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : TugColors.primaryPurple).withValues(alpha: 0.1),
            blurRadius: blur,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: TugColors.primaryPurple.withValues(alpha: 0.05),
            blurRadius: blur * 2,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  // Mind-blowing holographic shimmer effect
  static Widget holographicShimmer({
    required Widget child,
    Duration duration = const Duration(seconds: 3),
  }) {
    return _HolographicShimmer(
      duration: duration,
      child: child,
    );
  }

  // Cosmic breathing animation
  static Widget cosmicBreath({
    required Widget child,
    Duration duration = const Duration(seconds: 4),
    double intensity = 0.05,
  }) {
    return _CosmicBreath(
      duration: duration,
      intensity: intensity,
      child: child,
    );
  }

  // Quantum glow border
  static Widget quantumBorder({
    required Widget child,
    Color glowColor = TugColors.primaryPurple,
    double intensity = 1.0,
    Duration duration = const Duration(seconds: 2),
  }) {
    return _QuantumBorder(
      glowColor: glowColor,
      intensity: intensity,
      duration: duration,
      child: child,
    );
  }

  // Spectacular gradient text
  static Widget gradientText(
    String text, {
    required TextStyle style,
    List<Color>? colors,
    Alignment begin = Alignment.centerLeft,
    Alignment end = Alignment.centerRight,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors ?? [
          TugColors.primaryPurple,
          TugColors.primaryPurpleLight,
        ],
        begin: begin,
        end: end,
      ).createShader(bounds),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }

  // Floating animation
  static Widget floating({
    required Widget child,
    Duration duration = const Duration(seconds: 3),
    double offset = 10.0,
  }) {
    return _FloatingWidget(
      duration: duration,
      offset: offset,
      child: child,
    );
  }
}

// Quantum particle widget
class _QuantumParticle extends StatefulWidget {
  final bool isDark;
  final Duration delay;

  const _QuantumParticle({
    required this.isDark,
    required this.delay,
    super.key,
  });

  @override
  State<_QuantumParticle> createState() => _QuantumParticleState();
}

class _QuantumParticleState extends State<_QuantumParticle>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _pulseController;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _moveController = AnimationController(
      duration: Duration(seconds: 8 + math.Random().nextInt(12)),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: Duration(seconds: 2 + math.Random().nextInt(3)),
      vsync: this,
    );

    final random = math.Random();
    _moveAnimation = Tween<Offset>(
      begin: Offset(random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1),
      end: Offset(random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1),
    ).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _moveController.repeat(reverse: true);
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final random = math.Random();
    final purpleShades = [
      TugColors.primaryPurple,
      TugColors.primaryPurpleLight,
      TugColors.primaryPurpleDark,
    ];
    final color = purpleShades[random.nextInt(purpleShades.length)];

    return AnimatedBuilder(
      animation: Listenable.merge([_moveController, _pulseController]),
      builder: (context, child) {
        return Positioned(
          left: size.width * 0.1 + (size.width * 0.8 * (_moveAnimation.value.dx + 1) / 2),
          top: size.height * 0.1 + (size.height * 0.8 * (_moveAnimation.value.dy + 1) / 2),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 4 + random.nextDouble() * 6,
              height: 4 + random.nextDouble() * 6,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Holographic shimmer effect
class _HolographicShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _HolographicShimmer({
    required this.child,
    required this.duration,
  });

  @override
  State<_HolographicShimmer> createState() => _HolographicShimmerState();
}

class _HolographicShimmerState extends State<_HolographicShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

// Cosmic breathing animation
class _CosmicBreath extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double intensity;

  const _CosmicBreath({
    required this.child,
    required this.duration,
    required this.intensity,
  });

  @override
  State<_CosmicBreath> createState() => _CosmicBreathState();
}

class _CosmicBreathState extends State<_CosmicBreath>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 1.0 - widget.intensity,
      end: 1.0 + widget.intensity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

// Quantum border glow
class _QuantumBorder extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double intensity;
  final Duration duration;

  const _QuantumBorder({
    required this.child,
    required this.glowColor,
    required this.intensity,
    required this.duration,
  });

  @override
  State<_QuantumBorder> createState() => _QuantumBorderState();
}

class _QuantumBorderState extends State<_QuantumBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: TugColors.getNeonGlow(
              widget.glowColor,
              intensity: _animation.value * widget.intensity,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

// Floating animation widget
class _FloatingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;

  const _FloatingWidget({
    required this.child,
    required this.duration,
    required this.offset,
  });

  @override
  State<_FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<_FloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: -widget.offset,
      end: widget.offset,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }
}