// Enhanced futuristic animations utility with fluid transitions and advanced effects
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:math' as math;
import 'dart:ui'; // For ImageFilter
import 'theme/colors.dart';

class TugAnimations {
  // Improved fade-in animation with configurable delay and easing
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutCubic,
    double beginOpacity = 0.0,
    bool animateOnce = false,
    bool repeat = false,
  }) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Opacity(opacity: beginOpacity, child: child);
        }

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: beginOpacity, end: 1.0),
          duration: duration,
          curve: curve,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }

  // Enhanced slide animation with configurable axis and physics
  static Widget slideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutQuint,
    Offset beginOffset = const Offset(0.0, 30.0),
    bool animateOnce = false,
    bool useSpringPhysics = false,
  }) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Transform.translate(offset: beginOffset, child: child);
        }

        if (useSpringPhysics) {
          return TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(begin: beginOffset, end: Offset.zero),
            duration: duration,
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: value,
                child: child,
              );
            },
            child: child,
          );
        }

        return TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(begin: beginOffset, end: Offset.zero),
          duration: duration,
          curve: curve,
          builder: (context, value, child) {
            return Transform.translate(
              offset: value,
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }

  // Improved fade-slide combo with staggered option and futuristic movement
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutQuint,
    Offset beginOffset = const Offset(0.0, 30.0),
    double beginOpacity = 0.0,
    bool animateOnce = false,
    bool useSpringPhysics = false,
  }) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Opacity(
            opacity: beginOpacity,
            child: Transform.translate(offset: beginOffset, child: child)
          );
        }

        final effectiveCurve = useSpringPhysics 
            ? Curves.elasticOut
            : curve;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: duration,
          curve: effectiveCurve,
          builder: (context, value, child) {
            // Apply subtle acceleration easing for more modern feel
            final adjustedValue = Curves.easeOutExpo.transform(value);
            
            return Opacity(
              opacity: beginOpacity + (1.0 - beginOpacity) * adjustedValue,
              child: Transform.translate(
                offset: Offset(
                  beginOffset.dx * (1 - adjustedValue),
                  beginOffset.dy * (1 - adjustedValue),
                ),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
    );
  }

  // Enhanced scale animation with spring physics option and improved dynamics
  static Widget scaleIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutBack,
    double beginScale = 0.9,
    bool useSpringPhysics = false,
    bool animateOnce = false,
    double springStiffness = 400.0, // Higher for tighter spring
    double springDamping = 20.0, // Lower for more bounce
  }) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Transform.scale(scale: beginScale, child: child);
        }

        if (useSpringPhysics) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: beginScale, end: 1.0),
            duration: duration,
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: child,
          );
        }

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: beginScale, end: 1.0),
          duration: duration,
          curve: curve,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }
  
  // New: 3D perspective animation for futuristic depth
  static Widget perspectiveTransform({
    required Widget child,
    Duration duration = const Duration(milliseconds: 700),
    Duration delay = Duration.zero,
    double rotationX = 0.0, // Rotation around X axis in radians
    double rotationY = 0.2, // Rotation around Y axis in radians 
    double rotationZ = 0.0, // Rotation around Z axis in radians
    double scale = 0.9,    // Starting scale
    double perspective = 0.002, // Perspective distortion amount
    bool addDepthShadow = true,
  }) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Starting transform state
          final transform = Matrix4.identity()
            ..setEntry(3, 2, perspective) // Add perspective
            ..rotateX(rotationX)
            ..rotateY(rotationY)
            ..rotateZ(rotationZ)
            ..scale(scale);
          
          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: Opacity(
              opacity: 0.6,
              child: child,
            ),
          );
        }
        
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            // Create a perspective transform that animates to default
            final transform = Matrix4.identity()
              ..setEntry(3, 2, perspective * (1.0 - value)) // Animate perspective
              ..rotateX(rotationX * (1.0 - value))
              ..rotateY(rotationY * (1.0 - value))
              ..rotateZ(rotationZ * (1.0 - value))
              ..scale(scale + ((1.0 - scale) * value));
            
            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: Opacity(
                opacity: 0.6 + (0.4 * value),
                child: addDepthShadow 
                  ? Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2 * value),
                            blurRadius: 12 * value,
                            spreadRadius: 2 * value,
                            offset: Offset(0, 4 * value),
                          ),
                        ],
                      ),
                      child: child,
                    )
                  : child,
              ),
            );
          },
          child: child,
        );
      },
    );
  }

  // Improved staggered list animation with customizable futuristic effects
  static Widget staggeredListItem({
    required Widget child,
    required int index,
    Duration baseDelay = const Duration(milliseconds: 50),
    Duration itemDelay = const Duration(milliseconds: 20), // Additional delay per item
    Duration animationDuration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutQuint,
    StaggeredAnimationType type = StaggeredAnimationType.fadeSlideUp,
    double slideDistance = 20.0,
    bool useSpringPhysics = false,
    bool animateOnce = false,
  }) {
    final delay = Duration(
      milliseconds: baseDelay.inMilliseconds + (itemDelay.inMilliseconds * index),
    );

    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          switch (type) {
            case StaggeredAnimationType.fadeSlideUp:
            case StaggeredAnimationType.fadeSlideLeft:
            case StaggeredAnimationType.scale:
            case StaggeredAnimationType.fadeIn:
            case StaggeredAnimationType.perspectiveRight:
            case StaggeredAnimationType.perspectiveUp:
              return Opacity(opacity: 0, child: child);
            case StaggeredAnimationType.neonFlicker:
              return Opacity(opacity: 0, child: child);
          }
        }

        switch (type) {
          case StaggeredAnimationType.fadeSlideUp:
            return fadeSlideIn(
              child: child,
              duration: animationDuration,
              curve: curve,
              beginOffset: Offset(0, slideDistance),
              useSpringPhysics: useSpringPhysics,
            );
          case StaggeredAnimationType.fadeSlideLeft:
            return fadeSlideIn(
              child: child,
              duration: animationDuration,
              curve: curve,
              beginOffset: Offset(slideDistance, 0),
              useSpringPhysics: useSpringPhysics,
            );
          case StaggeredAnimationType.scale:
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: animationDuration,
              curve: useSpringPhysics ? Curves.elasticOut : curve,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: useSpringPhysics 
                        ? 0.7 + (0.3 * Curves.elasticOut.transform(value))
                        : 0.8 + (0.2 * value),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          case StaggeredAnimationType.fadeIn:
            return fadeIn(
              child: child,
              duration: animationDuration,
              curve: curve,
            );
          case StaggeredAnimationType.perspectiveRight:
            // 3D perspective animation coming from right
            return perspectiveTransform(
              child: child,
              duration: animationDuration,
              rotationY: -0.2,
              scale: 0.9,
              perspective: 0.002,
            );
          case StaggeredAnimationType.perspectiveUp:
            // 3D perspective animation coming from below
            return perspectiveTransform(
              child: child,
              duration: animationDuration,
              rotationX: 0.2,
              scale: 0.9,
              perspective: 0.001,
            );
          case StaggeredAnimationType.neonFlicker:
            // Futuristic neon flickering entrance effect
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: animationDuration,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                // Create a flicker effect that stabilizes over time
                final flickerIntensity = (1.0 - value) * 0.5;
                final random = math.Random(index);
                final flicker = value < 0.8
                    ? 1.0 - (flickerIntensity * random.nextDouble())
                    : 1.0;
                
                return Opacity(
                  opacity: flicker * value,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: TugColors.primaryPurple.withOpacity(0.08 * value * flicker),
                          blurRadius: 10 * value,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: child,
            );
        }
      },
    );
  }

  // Enhanced pulsate animation with glow effect and configurable parameters
  static Widget pulsate({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1800),
    double minScale = 0.97,
    double maxScale = 1.03,
    bool repeat = true,
    Curve curve = Curves.easeInOut,
    bool addGlow = false,
    Color? glowColor,
    bool isDark = false,
    double glowIntensity = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 2 * math.pi),
      duration: duration,
      curve: curve,
      onEnd: repeat ? () {} : null,
      builder: (context, value, child) {
        final double animValue = (math.sin(value) + 1) / 2; // Normalized 0.0 to 1.0
        final scale = minScale + (maxScale - minScale) * animValue;
        
        if (!addGlow) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        }
        
        final effectiveGlowColor = glowColor ?? (
          isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurple
        );
        
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: effectiveGlowColor.withOpacity((0.1 + 0.2 * animValue) * glowIntensity),
                blurRadius: (10 + 15 * animValue) * glowIntensity,
                spreadRadius: (1 + 3 * animValue) * glowIntensity,
              ),
            ],
          ),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // New: Holographic glow effect animation
  static Widget holographicGlow({
    required Widget child,
    Duration duration = const Duration(milliseconds: 3000),
    List<Color>? colors,
    double glowIntensity = 1.0,
    bool repeat = true,
    bool isDark = false,
  }) {
    final effectiveColors = colors ?? [
      TugColors.info,
      TugColors.primaryPurple,
      TugColors.primaryPurpleLight, 
      TugColors.success,
    ];
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 2 * math.pi),
      duration: duration,
      curve: Curves.linear,
      onEnd: repeat ? () {} : null,
      builder: (context, value, child) {
        // Create multiple overlapping glows with different phases
        final List<BoxShadow> glows = [];
        
        for (int i = 0; i < effectiveColors.length; i++) {
          // Create offset phase for each color
          final phase = value + (i * math.pi / effectiveColors.length);
          final animValue = (math.sin(phase) + 1) / 2; // 0.0 to 1.0
          
          glows.add(BoxShadow(
            color: effectiveColors[i].withOpacity(0.2 * animValue * glowIntensity),
            blurRadius: 20 * glowIntensity,
            spreadRadius: 2 * animValue * glowIntensity,
          ));
        }
        
        return Container(
          decoration: BoxDecoration(
            boxShadow: glows,
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  // Improved shimmer loading effect with customizable futuristic gradient
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    Color? baseColor,
    Color? highlightColor,
    bool isDark = false,
    bool isLoading = true,
    double angle = 0.0, // Angle in radians
    bool useHolographicColors = false, 
  }) {
    if (!isLoading) return child;

    // Use theme colors if not provided
    final base = baseColor ?? (isDark ? const Color(0xFF232537) : const Color(0xFFEEF1FF));
    final highlight = highlightColor ?? (isDark ? const Color(0xFF3A3D60) : Colors.white);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -1.0, end: 2.0),
      duration: duration,
      curve: Curves.easeInOutSine,
      // Loop the animation
      onEnd: () {
        // This will automatically rebuild with the starting value
      },
      builder: (context, value, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // Calculate gradient bounds based on angle
            final double width = bounds.width;
            final double height = bounds.height;

            // Default horizontal shimmer
            Alignment begin = Alignment(value - 1, 0);
            Alignment end = Alignment(value, 0);

            // Apply custom angle if provided
            if (angle != 0) {
              final double angleRadians = angle;
              final double dx = math.cos(angleRadians);
              final double dy = math.sin(angleRadians);

              begin = Alignment((value - 1) * dx, (value - 1) * dy);
              end = Alignment(value * dx, value * dy);
            }

            // Use holographic colors if requested
            if (useHolographicColors) {
              return LinearGradient(
                begin: begin,
                end: end,
                colors: [
                  base,
                  TugColors.info.withValues(alpha: 0.8),
                  highlight,
                  TugColors.primaryPurpleLight.withValues(alpha: 0.8),
                  base,
                ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ).createShader(bounds);
            }

            return LinearGradient(
              begin: begin,
              end: end,
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  // Enhanced interactive spring physics animation
  static Widget springInteractive({
    required Widget child,
    required void Function() onTap,
    double pressedScale = 0.96,
    Duration duration = const Duration(milliseconds: 180),
    bool useSprings = true, // Use spring physics for more natural feel
    double springStiffness = 500.0,
    double springDamping = 20.0,
    bool addClickEffect = false,
  }) {
    return SpringPressWidget(
      onTap: onTap,
      pressedScale: pressedScale,
      duration: duration,
      useSprings: useSprings,
      springStiffness: springStiffness,
      springDamping: springDamping,
      addClickEffect: addClickEffect,
      child: child,
    );
  }

  // Enhanced hero transition with configurable futuristic effects
  static Widget heroWithFade({
    required Widget child,
    required String tag,
    bool addScale = false,
    bool addRotation = false,
    bool addPerspective = false,
    bool addGlow = false,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final double value = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ).value;

            double scale = 1.0;
            double angle = 0.0;
            double perspectiveValue = 0.0;

            if (addScale) {
              // Enhanced scale effect with slight bounce
              scale = flightDirection == HeroFlightDirection.push
                  ? 0.85 + (0.15 * Curves.easeOutBack.transform(value))
                  : 1.0 - (0.12 * (1 - Curves.easeInOutCubic.transform(value)));
            }

            if (addRotation) {
              // Improved rotation with smoother curve
              angle = flightDirection == HeroFlightDirection.push
                  ? (1 - Curves.easeOutCubic.transform(value)) * 0.08
                  : Curves.easeInCubic.transform(value) * 0.08;
            }
            
            if (addPerspective) {
              // Add subtle perspective shift
              perspectiveValue = flightDirection == HeroFlightDirection.push
                  ? (1 - value) * 0.002
                  : value * 0.002;
            }

            Widget animatedChild = Opacity(
              opacity: flightDirection == HeroFlightDirection.push
                  ? value
                  : 1 - (1 - value) * 0.3, // Faster fade-out
              child: Transform(
                transform: addPerspective
                  ? (Matrix4.identity()
                    ..setEntry(3, 2, perspectiveValue)
                    ..rotateY(angle)
                    ..scale(scale))
                  : (Matrix4.identity()
                    ..rotateY(angle)
                    ..scale(scale)),
                alignment: Alignment.center,
                child: child,
              ),
            );
            
            // Apply glow effect during transition
            if (addGlow) {
              final glowOpacity = flightDirection == HeroFlightDirection.push
                  ? Curves.easeIn.transform(value) * 0.3
                  : (1 - value) * 0.3;
                  
              animatedChild = Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: TugColors.primaryPurple.withOpacity(glowOpacity),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: animatedChild,
              );
            }
            
            return animatedChild;
          },
        );
      },
      transitionOnUserGestures: true,
      child: child,
    );
  }

  // Enhanced card hover effect with configurable futuristic transformations
  static Widget cardHoverEffect({
    required Widget child,
    double liftAmount = 4.0,
    double scaleFactor = 1.03,
    Duration duration = const Duration(milliseconds: 200),
    bool addShadow = true,
    bool addScale = true,
    Color? glowColor,
    bool isDark = false,
    bool add3DTilt = false,
    double tiltIntensity = 0.05,
  }) {
    final hoverGlowColor = glowColor ??
        (isDark ? TugColors.primaryPurpleLight.withOpacity(0.3) : TugColors.primaryPurple.withOpacity(0.2));

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        Offset mousePosition = Offset.zero;

        return MouseRegion(
          onEnter: (event) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          onHover: add3DTilt 
              ? (event) => setState(() => mousePosition = event.localPosition)
              : null,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutQuad,
            transform: isHovered && liftAmount != 0
                ? (Matrix4.identity()..translate(0.0, -liftAmount))
                : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: addShadow ? BoxDecoration(
              boxShadow: [
                if (isHovered) BoxShadow(
                  color: hoverGlowColor,
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ) : null,
            child: AnimatedScale(
              scale: (isHovered && addScale) ? scaleFactor : 1.0,
              duration: duration,
              curve: Curves.easeOutCubic,
              child: add3DTilt && isHovered 
                ? Builder(
                    builder: (context) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return child;
                      
                      final size = box.size;
                      final centerX = size.width / 2;
                      final centerY = size.height / 2;
                      
                      // Calculate tilt based on mouse position
                      final double rotY = (mousePosition.dx - centerX) / centerX * tiltIntensity;
                      final double rotX = (centerY - mousePosition.dy) / centerY * tiltIntensity;
                      
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // Add perspective
                          ..rotateX(rotX)
                          ..rotateY(rotY),
                        child: child,
                      );
                    },
                  ) 
                : child,
            ),
          ),
        );
      },
    );
  }

  // New: Animated badge with neon pulse for notifications
  static Widget animatedBadge({
    required Widget child,
    required bool visible,
    Widget? badge,
    Alignment alignment = Alignment.topRight,
    Duration duration = const Duration(milliseconds: 300),
    bool addBounce = true,
    bool addNeonPulse = false,
    Color? neonColor, 
    bool isDark = false,
  }) {
    final defaultColor = neonColor ?? TugColors.error;
    
    final defaultBadge = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: defaultColor,
        shape: BoxShape.circle,
        boxShadow: addNeonPulse ? [
          BoxShadow(
            color: defaultColor.withOpacity(0.6),
            blurRadius: 6,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: defaultColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ] : null,
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: alignment,
            child: AnimatedSwitcher(
              duration: duration,
              switchInCurve: addBounce ? Curves.elasticOut : Curves.easeOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: visible
                ? addNeonPulse 
                  ? TweenAnimationBuilder<double>(
                      key: const ValueKey('pulse'),
                      tween: Tween<double>(begin: 0.8, end: 1.2),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeInOutSine,
                      builder: (context, value, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: defaultColor.withOpacity(0.3 * ((value - 0.8) / 0.4)),
                                blurRadius: 12 * value,
                                spreadRadius: 1 * value,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: badge ?? defaultBadge,
                    )
                  : badge ?? defaultBadge
                : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  // Improved animated counter with smoother transitions and futuristic formatting
  static Widget animatedCounter({
    required num value,
    TextStyle? style,
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeOutCubic,
    bool addCommas = false,
    String? prefix,
    String? suffix,
    int decimals = 0,
    bool emphasizeChange = false,
    bool addNeonGlow = false,
    Color? glowColor,
    bool isDark = false,
  }) {
    final effectiveGlowColor = glowColor ?? (isDark 
      ? TugColors.primaryPurpleLight 
      : TugColors.primaryPurple);
        
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, animValue, _) {
        // Format with optional decimal places
        String formatted;
        if (decimals > 0) {
          formatted = animValue.toStringAsFixed(decimals);
        } else {
          formatted = animValue.toInt().toString();
        }
        
        // Add commas for thousands separator if requested
        if (addCommas) {
          formatted = formatted.replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
        }
        
        // Add prefix and suffix if provided
        if (prefix != null) formatted = "$prefix$formatted";
        if (suffix != null) formatted = "$formatted$suffix";
        
        final textWidget = emphasizeChange 
          ? TweenAnimationBuilder<double>(
              key: ValueKey(value), // Rebuild on value change
              tween: Tween<double>(begin: 1.2, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Text(formatted),
            )
          : Text(formatted);
          
        return AnimatedDefaultTextStyle(
          style: style ?? const TextStyle(),
          duration: const Duration(milliseconds: 200),
          child: addNeonGlow
            ? Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: effectiveGlowColor.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: textWidget,
              )
            : textWidget,
        );
      },
    );
  }

  // New: Advanced color transition animation with plasma effect
  static Widget colorTransition({
    required Widget child,
    required Color fromColor,
    required Color toColor,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOut,
    bool addPulse = false,
    double pulseIntensity = 0.1,
  }) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: fromColor, end: toColor),
      duration: duration,
      curve: curve,
      builder: (context, color, _) {
        if (!addPulse) {
          return ColorFiltered(
            colorFilter: ColorFilter.mode(
              color ?? toColor,
              BlendMode.srcATop,
            ),
            child: child,
          );
        }
        
        // Add subtle pulse to color transition for more futuristic feel
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 2 * math.pi),
          duration: const Duration(milliseconds: 2000),
          curve: Curves.linear,
          builder: (context, phase, _) {
            final baseColor = color ?? toColor;
            final pulseValue = math.sin(phase) * pulseIntensity;
            
            // Create pulsing effect by brightening/darkening base color
            final adjustedColor = pulseValue > 0
                ? Color.lerp(baseColor, Colors.white, pulseValue) ?? baseColor
                : Color.lerp(baseColor, Colors.black, -pulseValue) ?? baseColor;
            
            return ColorFiltered(
              colorFilter: ColorFilter.mode(
                adjustedColor,
                BlendMode.srcATop,
              ),
              child: child,
            );
          },
        );
      },
    );
  }

  // New: Advanced typewriter text effect with cursor blink
  static Widget typewriter({
    required String text,
    TextStyle? style,
    Duration perCharacterDuration = const Duration(milliseconds: 50),
    Duration startDelay = const Duration(milliseconds: 200),
    Curve curve = Curves.linear,
    bool repeat = false,
    bool showCursor = true,
    Color? cursorColor,
    bool addNeonEffect = false,
    Color? neonColor,
    bool isDark = false,
  }) {
    final duration = Duration(
      milliseconds: perCharacterDuration.inMilliseconds * text.length,
    );
    
    final effectiveCursorColor = cursorColor ?? (isDark 
        ? TugColors.primaryPurpleLight
        : TugColors.primaryPurple);
        
    final effectiveNeonColor = neonColor ?? (isDark 
        ? TugColors.primaryPurpleLight
        : TugColors.primaryPurple);

    return FutureBuilder(
      future: Future.delayed(startDelay),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Text('', style: style);
        }

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: duration,
          curve: curve,
          onEnd: repeat ? () {} : null,
          builder: (context, value, _) {
            final visibleCharacters = (text.length * value).round();
            final visibleText = text.substring(0, visibleCharacters);
            
            // Add blinking cursor
            Widget result = showCursor
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        visibleText,
                        style: style,
                      ),
                      // Only show cursor when typing is complete
                      visibleCharacters >= text.length
                          ? _buildBlinkingCursor(effectiveCursorColor)
                          : Container(
                              height: 16,
                              width: 2,
                              color: effectiveCursorColor,
                            ),
                    ],
                  )
                : Text(
                    visibleText,
                    style: style,
                  );
                  
            // Add neon effect if requested
            if (addNeonEffect) {
              result = Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: effectiveNeonColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: result,
              );
            }
            
            return result;
          },
        );
      },
    );
  }
  
  // Helper to build blinking cursor
  static Widget _buildBlinkingCursor(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 2 * math.pi),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.linear,
      builder: (context, value, _) {
        final blink = math.sin(value) > 0;
        return Container(
          height: 16,
          width: 2,
          color: blink ? color : Colors.transparent,
        );
      },
    );
  }

  // Improved gradient shimmer text effect
  static Widget gradientShimmerText({
    required String text,
    required List<Color> gradientColors,
    TextStyle? style,
    Duration duration = const Duration(milliseconds: 2000),
    bool repeat = true,
    double angle = 0.0,
    bool addNeonGlow = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -0.5, end: 1.5),
      duration: duration,
      curve: Curves.linear,
      onEnd: repeat ? () {} : null,
      builder: (context, value, _) {
        final dx = math.cos(angle);
        final dy = math.sin(angle);

        final begin = Alignment(value - 1.0, (value - 1.0) * dy / dx);
        final end = Alignment(value, value * dy / dx);

        final textWidget = ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: begin,
              end: end,
              colors: gradientColors,
            ).createShader(bounds);
          },
          child: Text(
            text,
            style: style,
          ),
        );
        
        if (!addNeonGlow) return textWidget;
        
        // Add subtle neon glow to text
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              for (var color in gradientColors) 
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: textWidget,
        );
      },
    );
  }
  
  // New: Futuristic background noise/static animation
  static Widget digitalNoise({
    required Widget child,
    Duration cycleDuration = const Duration(milliseconds: 1500),
    double intensity = 0.05,
    Color? noiseColor,
    bool isDark = false,
  }) {
    final effectiveColor = noiseColor ?? (isDark 
      ? Colors.white.withOpacity(0.1)
      : Colors.black.withOpacity(0.05));
    
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: 10), // Use as a timer
            duration: cycleDuration,
            onEnd: () {},
            builder: (context, value, _) {
              // Create a semi-random pattern based on time
              final random = math.Random(DateTime.now().millisecondsSinceEpoch ~/ 100);
              
              return CustomPaint(
                painter: NoisePainter(
                  color: effectiveColor,
                  intensity: intensity,
                  seed: random.nextInt(1000), 
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // New: 3D card flip animation
  static Widget card3DFlip({
    required Widget frontWidget,
    required Widget backWidget,
    required bool showFront,
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeInOutQuart,
    Axis flipAxis = Axis.horizontal,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: showFront ? 0 : math.pi,
        end: showFront ? 0 : math.pi,
      ),
      duration: duration,
      curve: curve,
      builder: (context, value, _) {
        final showBackSide = value >= math.pi / 2;
        
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(flipAxis == Axis.vertical ? value : 0)
            ..rotateY(flipAxis == Axis.horizontal ? value : 0),
          child: showBackSide 
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateX(flipAxis == Axis.vertical ? math.pi : 0)
                  ..rotateY(flipAxis == Axis.horizontal ? math.pi : 0),
                child: backWidget,
              )
            : frontWidget,
        );
      },
    );
  }
  
  // New: Glass morphism backdrop blur effect
  static Widget glassMorphism({
    required Widget child,
    double blurAmount = 10.0,
    Color? tintColor,
    double tintOpacity = 0.1,
    double borderOpacity = 0.3,
    bool isDark = false,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    BoxBorder? border,
  }) {
    final effectiveTintColor = tintColor ?? (isDark
        ? Colors.white.withOpacity(tintOpacity)
        : Colors.white.withOpacity(tintOpacity));
        
    final effectiveBorder = border ?? Border.all(
      color: isDark 
          ? Colors.white.withOpacity(borderOpacity)
          : Colors.black.withOpacity(borderOpacity),
      width: 0.5,
    );
    
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurAmount,
          sigmaY: blurAmount,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: effectiveTintColor,
            borderRadius: borderRadius,
            border: effectiveBorder,
          ),
          child: child,
        ),
      ),
    );
  }
}

// Expanded staggered animation types for futuristic list items
enum StaggeredAnimationType {
  fadeSlideUp,
  fadeSlideLeft,
  scale,
  fadeIn,
  perspectiveRight, // 3D perspective transformation from right
  perspectiveUp,    // 3D perspective transformation from below
  neonFlicker,      // Cyberpunk-style flickering entrance
}

// Advanced spring press widget with rich haptic physics and micro-animations
class SpringPressWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final Duration duration;
  final bool useSprings;
  final double springStiffness;
  final double springDamping;
  final bool addClickEffect;

  const SpringPressWidget({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 180),
    this.useSprings = true,
    this.springStiffness = 500.0,
    this.springDamping = 20.0,
    this.addClickEffect = false,
  });

  @override
  SpringPressWidgetState createState() => SpringPressWidgetState();
}

class SpringPressWidgetState extends State<SpringPressWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showClickEffect = false;
  Offset _clickPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Use spring simulation for more realistic animation
    if (widget.useSprings) {
      final simulation = SpringSimulation(
        SpringDescription(
          mass: 1.0,
          stiffness: widget.springStiffness,
          damping: widget.springDamping,
        ),
        0.0, // starting point (not pressed)
        1.0, // end point (fully pressed)
        1.0, // initial velocity
      );

      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: widget.pressedScale,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );
    } else {
      // Use regular animation
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: widget.pressedScale,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        _controller.forward();
        if (widget.addClickEffect) {
          setState(() {
            _showClickEffect = true;
            _clickPosition = details.localPosition;
          });
          
          // Auto-hide click effect
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _showClickEffect = false;
              });
            }
          });
        }
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: widget.child,
          ),
          
          // Click ripple effect
          if (widget.addClickEffect && _showClickEffect)
            Positioned(
              left: _clickPosition.dx - 20,
              top: _clickPosition.dy - 20,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, value, _) {
                  return Container(
                    width: 40 * value,
                    height: 40 * value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3 * (1 - value)),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for digital noise effect
class NoisePainter extends CustomPainter {
  final Color color;
  final double intensity;
  final int seed;
  
  NoisePainter({
    required this.color,
    required this.intensity,
    required this.seed,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
      
    // Draw random noise points
    final pointCount = (size.width * size.height * 0.01 * intensity).toInt();
    
    for (int i = 0; i < pointCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      
      // Vary the noise pattern
      if (random.nextDouble() < 0.7) {
        // Points
        canvas.drawCircle(
          Offset(x, y),
          random.nextDouble() * 1.5,
          paint,
        );
      } else {
        // Short lines
        final endX = x + random.nextDouble() * 3 - 1.5;
        final endY = y + random.nextDouble() * 3 - 1.5;
        canvas.drawLine(
          Offset(x, y),
          Offset(endX, endY),
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(NoisePainter oldDelegate) {
    return oldDelegate.seed != seed || 
           oldDelegate.color != color ||
           oldDelegate.intensity != intensity;
  }
}

// Enhanced page route transitions with modern futuristic effects
class TugPageTransitions {
  // Enhanced fade transition
  static PageRouteBuilder fadeTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
    bool maintainState = true,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.7).round()),
      maintainState: maintainState,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        );
      },
    );
  }

  // Enhanced slide transition with better physics
  static PageRouteBuilder slideTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    SlideDirection direction = SlideDirection.right,
    Curve curve = Curves.easeOutQuint,
    bool maintainState = true,
  }) {
    Offset beginOffset;
    switch (direction) {
      case SlideDirection.right:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideDirection.left:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.up:
        beginOffset = const Offset(0.0, -1.0);
        break;
      case SlideDirection.down:
        beginOffset = const Offset(0.0, 1.0);
        break;
    }

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.7).round()),
      maintainState: maintainState,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      },
    );
  }

  // Ultra-smooth fade-slide combo with parallax effect and improved animation curve
  static PageRouteBuilder fadeSlideTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    SlideDirection direction = SlideDirection.right,
    Curve curve = Curves.easeOutCubic,
    bool maintainState = true,
    double slideDistance = 0.2, // How far to slide as fraction of screen
    bool addParallax = false, // Enable subtle parallax effect for depth
    bool addBlur = false, // Add slight blur during transition
  }) {
    Offset beginOffset;
    switch (direction) {
      case SlideDirection.right:
        beginOffset = Offset(slideDistance, 0.0);
        break;
      case SlideDirection.left:
        beginOffset = Offset(-slideDistance, 0.0);
        break;
      case SlideDirection.up:
        beginOffset = Offset(0.0, -slideDistance);
        break;
      case SlideDirection.down:
        beginOffset = Offset(0.0, slideDistance);
        break;
    }

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.7).round()),
      maintainState: maintainState,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        // Handle secondaryAnimation for better feeling when popping back
        final secondaryCurvedAnimation = CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        );

        // Page exit effect (when pushing new page on top)
        final double fadeValue = Curves.easeOut.transform(
            1.0 - secondaryCurvedAnimation.value
        );

        // Create staggered animations for more dynamic feel
        final fadeAnim = CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 0.8, curve: curve),
        );
        
        final slideAnim = CurvedAnimation(
          parent: animation,
          curve: Interval(0.1, 1.0, curve: curve),
        );
        
        Widget result = FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(fadeAnim),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(slideAnim),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.8).animate(secondaryCurvedAnimation),
              child: addParallax
                ? AnimatedBuilder(
                    animation: curvedAnimation,
                    builder: (context, child) {
                      // Create subtle parallax effect
                      return Transform.translate(
                        offset: Offset(
                          direction == SlideDirection.left || direction == SlideDirection.right
                              ? 10 * (1 - curvedAnimation.value) * (direction == SlideDirection.right ? -1 : 1)
                              : 0,
                          direction == SlideDirection.up || direction == SlideDirection.down
                              ? 10 * (1 - curvedAnimation.value) * (direction == SlideDirection.down ? -1 : 1)
                              : 0,
                        ),
                        child: child,
                      );
                    },
                    child: child,
                  )
                : child,
            ),
          ),
        );
        
        // Add optional blur effect during transition
        if (addBlur) {
          result = AnimatedBuilder(
            animation: Tween<double>(begin: 4.0, end: 0.0).animate(curvedAnimation),
            builder: (context, child) {
              return ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: curvedAnimation.value < 0.8 ? (1 - curvedAnimation.value) * 4.0 : 0.0,
                  sigmaY: curvedAnimation.value < 0.8 ? (1 - curvedAnimation.value) * 4.0 : 0.0,
                ),
                child: child,
              );
            },
            child: result,
          );
        }
        
        return result;
      },
    );
  }
  
  // New: Futuristic 3D perspective transition
  static PageRouteBuilder perspective3DTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.easeOutCubic,
    bool maintainState = true,
    SlideDirection direction = SlideDirection.right,
    double perspective = 0.002,
    bool addShadow = true,
  }) {
    // Determine rotation axis and angle based on direction
    double rotationX = 0.0;
    double rotationY = 0.0;
    
    switch (direction) {
      case SlideDirection.right:
        rotationY = -math.pi / 4; // Rotate from right
        break;
      case SlideDirection.left:
        rotationY = math.pi / 4; // Rotate from left
        break;
      case SlideDirection.up:
        rotationX = math.pi / 4; // Rotate from bottom
        break;
      case SlideDirection.down:
        rotationX = -math.pi / 4; // Rotate from top
        break;
    }
    
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.8).round()),
      maintainState: maintainState,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );
        
        final secondaryCurvedAnimation = CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        );
        
        return Stack(
          children: [
            // Handle exit animation of current page
            if (secondaryAnimation.value > 0)
              AnimatedBuilder(
                animation: secondaryAnimation,
                builder: (context, child) {
                  // Create mirror of incoming animation for outgoing page
                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, perspective * secondaryCurvedAnimation.value)
                    ..rotateX(rotationX * secondaryCurvedAnimation.value)
                    ..rotateY(rotationY * secondaryCurvedAnimation.value)
                    ..scale(1.0 - (0.15 * secondaryCurvedAnimation.value));
                  
                  return Opacity(
                    opacity: 1.0 - (0.6 * secondaryCurvedAnimation.value),
                    child: Transform(
                      alignment: direction == SlideDirection.right
                          ? Alignment.centerLeft
                          : (direction == SlideDirection.left
                              ? Alignment.centerRight
                              : (direction == SlideDirection.up
                                  ? Alignment.bottomCenter
                                  : Alignment.topCenter)),
                      transform: transform,
                      child: child,
                    ),
                  );
                },
                child: child,
              ),
            
            // Handle entry animation of new page
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final transform = Matrix4.identity()
                  ..setEntry(3, 2, perspective * (1.0 - curvedAnimation.value))
                  ..rotateX(rotationX * (1.0 - curvedAnimation.value))
                  ..rotateY(rotationY * (1.0 - curvedAnimation.value))
                  ..scale(0.85 + (0.15 * curvedAnimation.value));
                
                return Opacity(
                  opacity: curvedAnimation.value,
                  child: Transform(
                    alignment: direction == SlideDirection.right
                        ? Alignment.centerRight
                        : (direction == SlideDirection.left
                            ? Alignment.centerLeft
                            : (direction == SlideDirection.up
                                ? Alignment.topCenter
                                : Alignment.bottomCenter)),
                    transform: transform,
                    child: addShadow
                        ? Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2 * curvedAnimation.value),
                                  blurRadius: 20 * curvedAnimation.value,
                                  spreadRadius: 5 * curvedAnimation.value,
                                ),
                              ],
                            ),
                            child: page,
                          )
                        : page,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Enhanced scale transition with better curve control
  static PageRouteBuilder scaleTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    Curve scaleCurve = Curves.easeOutCubic,
    Curve fadeCurve = Curves.easeOutCubic,
    double beginScale = 0.92,
    bool maintainState = true,
    bool useSpringPhysics = false,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.7).round()),
      maintainState: maintainState,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Handle secondary animation for better feeling when popping
        final secondaryCurvedAnimation = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
        );
        
        final effectiveScaleCurve = useSpringPhysics
            ? Curves.elasticOut
            : scaleCurve;

        return ScaleTransition(
          scale: Tween<double>(
            begin: beginScale,
            end: 1.0
          ).animate(CurvedAnimation(
            parent: animation,
            curve: effectiveScaleCurve,
          )),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0
            ).animate(CurvedAnimation(
              parent: animation,
              curve: fadeCurve,
            )),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.6).animate(secondaryCurvedAnimation),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.05).animate(secondaryCurvedAnimation),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  // New: Futuristic glitch transition effect
  static PageRouteBuilder glitchTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 600),
    bool maintainState = true,
    int glitchSteps = 4, // Number of glitch displacement steps
    double maxDisplacement = 8.0, // Maximum glitch shift amount
    bool addColorShift = true, // Apply RGB shift effect
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      maintainState: maintainState,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Create a sharp stepping curve for glitch effect
        final glitchCurve = CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 0.7, curve: Curves.easeOutQuint),
        );
        
        // Smooth curve for fade-in
        final fadeCurve = CurvedAnimation(
          parent: animation,
          curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic),
        );
        
        return Stack(
          children: [
            // Existing page fading out
            FadeTransition(
              opacity: ReverseAnimation(CurvedAnimation(
                parent: animation,
                curve: Interval(0.0, 0.3, curve: Curves.easeInCubic),
              )),
              child: child,
            ),
            
            // New page with glitch effect
            AnimatedBuilder(
              animation: Listenable.merge([glitchCurve, fadeCurve]),
              builder: (context, _) {
                // Generate glitch intensity that peaks in the middle
                final glitchProgress = Curves.easeInOut.transform(
                  glitchCurve.value < 0.7 ? glitchCurve.value / 0.7 : 0.0
                );
                final intensity = glitchProgress < 0.5 
                    ? glitchProgress * 2
                    : (1.0 - glitchProgress) * 2;
                
                // Random offset based on animation progress
                final random = math.Random(
                  (glitchCurve.value * 10).toInt() + 1
                );
                
                return Stack(
                  children: [
                    // Base layer
                    Opacity(
                      opacity: fadeCurve.value,
                      child: page,
                    ),
                    
                    // Generate glitch layers if animation is in progress
                    if (intensity > 0.1)
                      ...List.generate(glitchSteps, (i) {
                        // Generate random displacements
                        final xOffset = (random.nextDouble() * 2 - 1) * 
                                      maxDisplacement * intensity;
                        final yOffset = (random.nextDouble() * 2 - 1) * 
                                      maxDisplacement * intensity * 0.5;
                        
                        final layerIntensity = (i + 1) / glitchSteps * intensity;
                        
                        // Determine which channel to shift
                        Widget glitchLayer = Opacity(
                          opacity: layerIntensity * 0.7,
                          child: Transform.translate(
                            offset: Offset(xOffset, yOffset),
                            child: page,
                          ),
                        );
                        
                        // Apply color channel separation if requested
                        if (addColorShift && i < 3) {
                          // Create RGB channel shifts
                          final channelColors = [
                            ColorFilter.mode(Colors.red.withOpacity(0.6), BlendMode.srcATop),
                            ColorFilter.mode(Colors.green.withOpacity(0.6), BlendMode.srcATop),
                            ColorFilter.mode(Colors.blue.withOpacity(0.6), BlendMode.srcATop),
                          ];
                          
                          // Apply different channel filter to each layer
                          glitchLayer = ColorFiltered(
                            colorFilter: channelColors[i % 3],
                            child: glitchLayer,
                          );
                        }
                        
                        return glitchLayer;
                      }),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  // New: Material shared axis transition (3D rotation effect)
  static PageRouteBuilder materialSharedAxisTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 500),
    MaterialAxisDirection axisDirection = MaterialAxisDirection.horizontal,
    bool maintainState = true,
  }) {
    // Implementation inspired by material shared axis transition
    final Curve curve = Curves.fastOutSlowIn;
    final Curve reverseCurve = Curves.fastOutSlowIn.flipped;

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      maintainState: maintainState,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Create primary animation curves
        final fadeIn = CurvedAnimation(
          parent: animation,
          curve: Interval(0.3, 1.0, curve: curve),
        );

        final fadeOut = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Interval(0.0, 0.7, curve: curve),
        );

        final rotationAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        final reverseRotationAnimation = CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        );

        switch (axisDirection) {
          case MaterialAxisDirection.horizontal:
            // X-axis rotation for horizontal transition
            return Stack(
              children: [
                FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(fadeOut),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspective
                      ..rotateY(0.5 * math.pi * reverseRotationAnimation.value),
                    child: secondaryAnimation.value < 0.7 ? child : const SizedBox.shrink(),
                  ),
                ),
                FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(fadeIn),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspective
                      ..rotateY(-0.5 * math.pi * (1 - rotationAnimation.value)),
                    child: animation.value > 0.3 ? page : const SizedBox.shrink(),
                  ),
                ),
              ],
            );

          case MaterialAxisDirection.vertical:
            // Y-axis rotation for vertical transition
            return Stack(
              children: [
                FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(fadeOut),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspective
                      ..rotateX(-0.5 * math.pi * reverseRotationAnimation.value),
                    child: secondaryAnimation.value < 0.7 ? child : const SizedBox.shrink(),
                  ),
                ),
                FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(fadeIn),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspective
                      ..rotateX(0.5 * math.pi * (1 - rotationAnimation.value)),
                    child: animation.value > 0.3 ? page : const SizedBox.shrink(),
                  ),
                ),
              ],
            );
        }
      },
    );
  }
}

// Direction enum for slide transitions
enum SlideDirection {
  right,
  left,
  up,
  down,
}

// Material-style axis direction for shared axis transitions
enum MaterialAxisDirection {
  horizontal,
  vertical,
}