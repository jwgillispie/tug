// Animations utility file with reusable animations
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:math' as math;

class TugAnimations {
  // Fade-in animation widget
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOut,
    double beginOpacity = 0.0,
    bool animateOnce = false,
  }) {
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
  }

  // Slide animation widget
  static Widget slideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutQuint,
    Offset beginOffset = const Offset(0.0, 30.0),
    bool animateOnce = false,
  }) {
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
  }

  // Combined fade and slide animation
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeOutQuint,
    Offset beginOffset = const Offset(0.0, 30.0),
    double beginOpacity = 0.0,
    bool animateOnce = false,
  }) {
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
  }

  // Scale animation widget
  static Widget scaleIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutBack,
    double beginScale = 0.9,
    bool animateOnce = false,
  }) {
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
  }

  // Staggered list item animation
  static Widget staggeredListItem({
    required Widget child,
    required int index,
    Duration baseDelay = const Duration(milliseconds: 50),
    Duration fadeDuration = const Duration(milliseconds: 400),
    Duration slideDuration = const Duration(milliseconds: 400),
    bool animateOnce = false,
  }) {
    final delay = Duration(milliseconds: baseDelay.inMilliseconds * index);
    
    return AnimatedBuilder(
      animation: AlwaysStoppedAnimation(0), // dummy animation for delayed execution
      builder: (context, _) {
        return FutureBuilder(
          future: Future.delayed(delay),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Opacity(opacity: 0, child: child);
            }
            return fadeSlideIn(
              child: child,
              duration: fadeDuration,
              beginOffset: Offset(0, 20),
            );
          },
        );
      },
    );
  }

  // Pulsating effect
  static Widget pulsate({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 2 * math.pi),
      duration: duration,
      curve: Curves.linear,
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

  // Shimmer loading effect
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    bool isLoading = true,
  }) {
    if (!isLoading) return child;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -1.0, end: 2.0),
      duration: duration,
      curve: Curves.easeInOutSine,
      builder: (context, value, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(value - 1, 0),
              end: Alignment(value, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  // Spring animation for interactive elements
  static Widget springInteractive({
    required Widget child,
    required void Function() onTap,
    double pressedScale = 0.95,
  }) {
    return SpringPressWidget(
      onTap: onTap,
      pressedScale: pressedScale,
      child: child,
    );
  }
  
  // Hero transition with fade
  static Widget heroWithFade({
    required Widget child,
    required String tag,
    Duration createRectTween = const Duration(milliseconds: 300),
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
            return Opacity(
              opacity: flightDirection == HeroFlightDirection.push
                  ? animation.value
                  : 1 - animation.value,
              child: child,
            );
          },
        );
      },
      child: child,
    );
  }
  
  // Card hover effect
  static Widget cardHoverEffect({
    required Widget child,
    double elevation = 4.0,
    double hoverElevation = 8.0,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutQuad,
            transform: isHovered
                ? (Matrix4.identity()..translate(0.0, -4.0))
                : Matrix4.identity(),
            child: child,
          ),
        );
      },
    );
  }
}

// Spring press animation widget for interactive elements
class SpringPressWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  
  const SpringPressWidget({
    Key? key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.95,
  }) : super(key: key);

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
      duration: const Duration(milliseconds: 150),
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

// Page route transitions
class TugPageTransitions {
  // Fade transition
  static PageRouteBuilder fadeTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
  
  // Slide transition
  static PageRouteBuilder slideTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    SlideDirection direction = SlideDirection.right,
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
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuint,
          )),
          child: child,
        );
      },
    );
  }
  
  // Combined fade and slide transition
  static PageRouteBuilder fadeSlideTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    SlideDirection direction = SlideDirection.right,
    Curve curve = Curves.easeOutQuint,
  }) {
    Offset beginOffset;
    switch (direction) {
      case SlideDirection.right:
        beginOffset = const Offset(0.2, 0.0);
        break;
      case SlideDirection.left:
        beginOffset = const Offset(-0.2, 0.0);
        break;
      case SlideDirection.up:
        beginOffset = const Offset(0.0, -0.2);
        break;
      case SlideDirection.down:
        beginOffset = const Offset(0.0, 0.2);
        break;
    }
    
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );
        
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
  
  // Scale transition
  static PageRouteBuilder scaleTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutQuad,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
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