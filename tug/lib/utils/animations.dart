// Enhanced animations utility with fluid transitions and modern effects
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:math' as math;
import 'theme/colors.dart';

class TugAnimations {
  // Improved fade-in animation with configurable delay
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

  // Enhanced slide animation with configurable axis
  static Widget slideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutQuint,
    Offset beginOffset = const Offset(0.0, 30.0),
    bool animateOnce = false,
  }) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Transform.translate(offset: beginOffset, child: child);
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

  // Improved fade-slide combo with staggered option
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutQuint,
    Offset beginOffset = const Offset(0.0, 30.0),
    double beginOpacity = 0.0,
    bool animateOnce = false,
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

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: duration,
          curve: curve,
          builder: (context, value, child) {
            return Opacity(
              opacity: beginOpacity + (1.0 - beginOpacity) * value,
              child: Transform.translate(
                offset: Offset(
                  beginOffset.dx * (1 - value),
                  beginOffset.dy * (1 - value),
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

  // Enhanced scale animation with spring physics option
  static Widget scaleIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutBack,
    double beginScale = 0.9,
    bool useSpringPhysics = false,
    bool animateOnce = false,
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

  // Improved staggered list animation with customizable effects
  static Widget staggeredListItem({
    required Widget child,
    required int index,
    Duration baseDelay = const Duration(milliseconds: 50),
    Duration itemDelay = const Duration(milliseconds: 0), // Additional delay per item
    Duration animationDuration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutQuint,
    StaggeredAnimationType type = StaggeredAnimationType.fadeSlideUp,
    double slideDistance = 20.0,
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
              return Opacity(opacity: 0, child: child);
            case StaggeredAnimationType.fadeSlideLeft:
              return Opacity(opacity: 0, child: child);
            case StaggeredAnimationType.scale:
              return Opacity(opacity: 0, child: child);
            case StaggeredAnimationType.fadeIn:
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
            );
          case StaggeredAnimationType.fadeSlideLeft:
            return fadeSlideIn(
              child: child,
              duration: animationDuration,
              curve: curve,
              beginOffset: Offset(slideDistance, 0),
            );
          case StaggeredAnimationType.scale:
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: animationDuration,
              curve: curve,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
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
        }
      },
    );
  }

  // Enhanced pulsate with configurable intensity
  static Widget pulsate({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1800),
    double minScale = 0.97,
    double maxScale = 1.03,
    bool repeat = true,
    Curve curve = Curves.easeInOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 2 * math.pi),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        final scale = minScale + (maxScale - minScale) * ((math.sin(value) + 1) / 2);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }

  // Improved shimmer loading effect with customizable gradient
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    Color? baseColor,
    Color? highlightColor,
    bool isDark = false,
    bool isLoading = true,
    double angle = 0.0, // Angle in radians
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

  // Enhanced spring animation with configurable physics
  static Widget springInteractive({
    required Widget child,
    required void Function() onTap,
    double pressedScale = 0.96,
    Duration duration = const Duration(milliseconds: 180),
    bool useSprings = true, // Use spring physics for more natural feel
  }) {
    return SpringPressWidget(
      onTap: onTap,
      pressedScale: pressedScale,
      duration: duration,
      useSprings: useSprings,
      child: child,
    );
  }

  // Enhanced hero transition with configurable effects
  static Widget heroWithFade({
    required Widget child,
    required String tag,
    bool addScale = false,
    bool addRotation = false,
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

            if (addScale) {
              // Scale up slightly during transition
              scale = flightDirection == HeroFlightDirection.push
                  ? 0.9 + (0.1 * value)
                  : 1.0 - (0.1 * (1 - value));
            }

            if (addRotation) {
              // Slight rotation during transition
              angle = flightDirection == HeroFlightDirection.push
                  ? (1 - value) * 0.05
                  : value * 0.05;
            }

            return Opacity(
              opacity: flightDirection == HeroFlightDirection.push
                  ? value
                  : 1 - (1 - value) * 0.3, // Faster fade-out
              child: Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: angle,
                  child: child,
                ),
              ),
            );
          },
        );
      },
      transitionOnUserGestures: true,
      child: child,
    );
  }

  // Enhanced card hover effect with configurable transformations
  static Widget cardHoverEffect({
    required Widget child,
    double liftAmount = 4.0,
    double scaleFactor = 1.03,
    Duration duration = const Duration(milliseconds: 200),
    bool addShadow = true,
    bool addScale = true,
    Color? glowColor,
    bool isDark = false,
  }) {
    final hoverGlowColor = glowColor ??
        (isDark ? TugColors.primaryPurpleLight.withOpacity(0.3) : TugColors.primaryPurple.withOpacity(0.2));

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
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
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ) : null,
            child: AnimatedScale(
              scale: (isHovered && addScale) ? scaleFactor : 1.0,
              duration: duration,
              curve: Curves.easeOutCubic,
              child: child,
            ),
          ),
        );
      },
    );
  }

  // New: Animated badge for notifications
  static Widget animatedBadge({
    required Widget child,
    required bool visible,
    Widget? badge,
    Alignment alignment = Alignment.topRight,
    Duration duration = const Duration(milliseconds: 300),
    bool addBounce = true,
  }) {
    final defaultBadge = Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: TugColors.error,
        shape: BoxShape.circle,
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
                  ? badge ?? defaultBadge
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  // New: Animated counter for numbers
  static Widget animatedCounter({
    required int value,
    TextStyle? style,
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeOutCubic,
    bool addCommas = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, value, _) {
        final displayValue = value.toInt();
        final text = addCommas
            ? displayValue.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},')
            : displayValue.toString();

        return Text(
          text,
          style: style,
        );
      },
    );
  }

  // New: Color transition animation
  static Widget colorTransition({
    required Widget child,
    required Color fromColor,
    required Color toColor,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOut,
  }) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: fromColor, end: toColor),
      duration: duration,
      curve: curve,
      builder: (context, color, _) {
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            color ?? toColor,
            BlendMode.srcATop,
          ),
          child: child,
        );
      },
    );
  }

  // New: Typewriter text effect
  static Widget typewriter({
    required String text,
    TextStyle? style,
    Duration perCharacterDuration = const Duration(milliseconds: 50),
    Duration startDelay = const Duration(milliseconds:
     200),
    Curve curve = Curves.easeOut,
    bool repeat = false,
  }) {
    final duration = Duration(
      milliseconds: perCharacterDuration.inMilliseconds * text.length,
    );

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

            return Text(
              visibleText,
              style: style,
            );
          },
        );
      },
    );
  }

  // New: Gradient shimmer text effect
  static Widget gradientShimmerText({
    required String text,
    required List<Color> gradientColors,
    TextStyle? style,
    Duration duration = const Duration(milliseconds: 2000),
    bool repeat = true,
    double angle = 0.0,
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

        return ShaderMask(
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
      },
    );
  }
}

// Staggered animation types for list items
enum StaggeredAnimationType {
  fadeSlideUp,
  fadeSlideLeft,
  scale,
  fadeIn,
}

// Enhanced spring press widget with physics-based animation
class SpringPressWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final Duration duration;
  final bool useSprings;

  const SpringPressWidget({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 180),
    this.useSprings = true,
  });

  @override
  SpringPressWidgetState createState() => SpringPressWidgetState();
}

class SpringPressWidgetState extends State<SpringPressWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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
        const SpringDescription(
          mass: 1.0,
          stiffness: 500.0,
          damping: 20.0,
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
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// Enhanced page route transitions with modern effects
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

  // Enhanced fade-slide combo with improved animation curve
  static PageRouteBuilder fadeSlideTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    SlideDirection direction = SlideDirection.right,
    Curve curve = Curves.easeOutCubic,
    bool maintainState = true,
    double slideDistance = 0.2, // How far to slide as fraction of screen
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

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.8).animate(secondaryCurvedAnimation),
              child: child,
            ),
          ),
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

        return ScaleTransition(
          scale: Tween<double>(
            begin: beginScale,
            end: 1.0
          ).animate(CurvedAnimation(
            parent: animation,
            curve: scaleCurve,
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