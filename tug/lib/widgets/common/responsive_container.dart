// Futuristic responsive container with advanced glass morphism effects
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tug/utils/responsive_utils.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/animations.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Alignment alignment;
  final double? width;
  final double? height;
  final double? maxWidth;
  final BoxDecoration? decoration;
  final bool centerContent;
  final bool adaptivePadding;
  final bool adaptiveHeight;
  
  // New futuristic styling options
  final bool useGlassMorphism;
  final double? blur;
  final Color? backgroundColor;
  final double borderRadius;
  
  // Advanced visual effects
  final bool addShadow;
  final Color? shadowColor;
  final bool addGlow;
  final Color? glowColor;
  final double glowIntensity;
  
  // Animation effects
  final bool animate;
  final Duration animationDuration;
  final Duration animationDelay;
  final Curve animationCurve;
  final TugAnimationType animationType;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.maxWidth = 1200,
    this.decoration,
    this.centerContent = false,
    this.adaptivePadding = true,
    this.adaptiveHeight = false,
    
    // Futuristic styling defaults
    this.useGlassMorphism = false,
    this.blur,
    this.backgroundColor,
    this.borderRadius = 16,
    
    // Advanced visual effects defaults
    this.addShadow = true,
    this.shadowColor,
    this.addGlow = false,
    this.glowColor,
    this.glowIntensity = 1.0,
    
    // Animation defaults
    this.animate = false,
    this.animationDuration = const Duration(milliseconds: 600),
    this.animationDelay = Duration.zero,
    this.animationCurve = Curves.easeOutCubic,
    this.animationType = TugAnimationType.fadeSlideUp,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate adaptive padding if enabled
    EdgeInsetsGeometry effectivePadding = padding ?? EdgeInsets.zero;
    if (adaptivePadding && padding == null) {
      switch (deviceType) {
        case DeviceType.mobile:
          effectivePadding = const EdgeInsets.all(16);
          break;
        case DeviceType.tablet:
          effectivePadding = const EdgeInsets.all(24);
          break;
        case DeviceType.desktop:
        case DeviceType.widescreen:
          effectivePadding = const EdgeInsets.all(32);
          break;
      }
    }
    
    // Calculate height based on device type if adaptiveHeight is true
    double? effectiveHeight = height;
    if (adaptiveHeight && height != null) {
      switch (deviceType) {
        case DeviceType.mobile:
          effectiveHeight = height;
          break;
        case DeviceType.tablet:
          effectiveHeight = height! * 1.15;
          break;
        case DeviceType.desktop:
          effectiveHeight = height! * 1.3;
          break;
        case DeviceType.widescreen:
          effectiveHeight = height! * 1.4;
          break;
      }
    }
    
    // Create base container with modern styling
    Widget containerWidget;
    
    // For desktop and widescreen, constrain width and center
    if (deviceType == DeviceType.desktop || deviceType == DeviceType.widescreen) {
      containerWidget = Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? double.infinity,
          ),
          width: width,
          height: effectiveHeight,
          margin: margin,
          padding: !useGlassMorphism ? effectivePadding : null,
          decoration: !useGlassMorphism ? _buildDecoration(context) : null,
          alignment: alignment,
          child: centerContent ? Center(child: child) : child,
        ),
      );
    } else {
      // For mobile and tablet, use full width
      containerWidget = Container(
        width: width,
        height: effectiveHeight,
        margin: margin,
        padding: !useGlassMorphism ? effectivePadding : null,
        decoration: !useGlassMorphism ? _buildDecoration(context) : null,
        alignment: alignment,
        child: centerContent ? Center(child: child) : child,
      );
    }
    
    // Apply glass morphism if requested
    if (useGlassMorphism) {
      // Calculate adaptive blur based on device type
      double effectiveBlur = blur ?? 10.0;
      switch (deviceType) {
        case DeviceType.mobile:
          effectiveBlur = blur ?? 10.0;
          break;
        case DeviceType.tablet:
          effectiveBlur = blur != null ? blur! * 1.2 : 12.0;
          break;
        case DeviceType.desktop:
          effectiveBlur = blur != null ? blur! * 1.5 : 15.0;
          break;
        case DeviceType.widescreen:
          effectiveBlur = blur != null ? blur! * 2.0 : 20.0;
          break;
      }
      
      containerWidget = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveBlur,
            sigmaY: effectiveBlur,
          ),
          child: Container(
            width: width,
            height: effectiveHeight,
            padding: effectivePadding,
            margin: margin,
            decoration: BoxDecoration(
              color: backgroundColor ?? (isDark 
                ? Colors.black.withValues(alpha: 0.3) 
                : Colors.white.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : Colors.white.withValues(alpha: 0.3),
                width: 0.5,
              ),
              boxShadow: addShadow ? [
                BoxShadow(
                  color: shadowColor ?? Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: -5,
                ),
              ] : null,
            ),
            alignment: alignment,
            child: centerContent ? Center(child: child) : child,
          ),
        ),
      );
    }
    
    // Apply glow effect if requested
    if (addGlow) {
      containerWidget = TugAnimations.holographicGlow(
        child: containerWidget,
        glowIntensity: glowIntensity,
        colors: glowColor != null ? [glowColor!] : null,
        isDark: isDark,
      );
    }
    
    // Apply animation if requested
    if (animate) {
      containerWidget = _animateWidget(containerWidget);
    }
    
    return containerWidget;
  }
  
  // Build decoration based on the provided parameters
  BoxDecoration _buildDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use provided decoration if available
    if (decoration != null) {
      return decoration!;
    }
    
    // Get effective colors
    final effectiveBackgroundColor = backgroundColor ?? (isDark
      ? TugColors.darkSurface
      : TugColors.lightSurface);
      
    final effectiveShadowColor = shadowColor ?? (isDark
      ? Colors.black.withValues(alpha: 0.3)
      : TugColors.primaryPurple.withValues(alpha: 0.2));
    
    // Create default modern decoration
    return BoxDecoration(
      color: effectiveBackgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark 
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.05),
        width: 0.5,
      ),
      boxShadow: addShadow ? [
        BoxShadow(
          color: effectiveShadowColor,
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        // Subtle secondary shadow for depth
        BoxShadow(
          color: (isDark ? TugColors.primaryPurple : TugColors.primaryPurpleLight)
              .withValues(alpha: 0.08),
          blurRadius: 8,
          spreadRadius: -2,
          offset: const Offset(0, 2),
        ),
      ] : null,
      // Apply gradient if no background color is specified
      gradient: backgroundColor == null && !isDark ? LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Colors.white.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 1.0],
      ) : null,
    );
  }
  
  // Apply the appropriate animation based on the animation type
  Widget _animateWidget(Widget widget) {
    switch (animationType) {
      case TugAnimationType.fadeIn:
        return TugAnimations.fadeIn(
          child: widget,
          duration: animationDuration,
          delay: animationDelay,
          curve: animationCurve,
        );
      case TugAnimationType.fadeSlideUp:
        return TugAnimations.fadeSlideIn(
          child: widget,
          duration: animationDuration,
          delay: animationDelay,
          curve: animationCurve,
          beginOffset: const Offset(0, 30),
        );
      case TugAnimationType.fadeSlideLeft:
        return TugAnimations.fadeSlideIn(
          child: widget,
          duration: animationDuration,
          delay: animationDelay,
          curve: animationCurve,
          beginOffset: const Offset(30, 0),
        );
      case TugAnimationType.scale:
        return TugAnimations.scaleIn(
          child: widget,
          duration: animationDuration,
          delay: animationDelay,
          curve: animationCurve,
        );
      case TugAnimationType.perspective:
        return TugAnimations.perspectiveTransform(
          child: widget,
          duration: animationDuration,
          delay: animationDelay,
          rotationY: 0.1,
          scale: 0.95,
        );
    }
  }
}

// Enhanced glass container with futuristic effects
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double? blur;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final bool adaptivePadding;
  final bool adaptiveBlur;
  
  // Advanced visual effects
  final bool addShadow;
  final Color? shadowColor;
  final bool addGlow;
  final Color? glowColor;
  final double glowIntensity;
  final List<Color>? gradientColors;
  
  // Animation effects
  final bool animate;
  final Duration animationDuration;
  final Duration animationDelay;
  final TugAnimationType animationType;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blur,
    this.color,
    this.borderColor,
    this.borderRadius = 16,
    this.adaptivePadding = true,
    this.adaptiveBlur = true,
    
    // Advanced effects
    this.addShadow = true,
    this.shadowColor,
    this.addGlow = false,
    this.glowColor,
    this.glowIntensity = 0.8,
    this.gradientColors,
    
    // Animation
    this.animate = false,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationDelay = Duration.zero,
    this.animationType = TugAnimationType.fadeIn,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate adaptive padding if enabled
    EdgeInsetsGeometry effectivePadding = padding ?? EdgeInsets.zero;
    if (adaptivePadding && padding == null) {
      switch (deviceType) {
        case DeviceType.mobile:
          effectivePadding = const EdgeInsets.all(16);
          break;
        case DeviceType.tablet:
          effectivePadding = const EdgeInsets.all(24);
          break;
        case DeviceType.desktop:
        case DeviceType.widescreen:
          effectivePadding = const EdgeInsets.all(32);
          break;
      }
    }
    
    // Calculate blur based on device type if adaptiveBlur is true
    double effectiveBlur = blur ?? 10.0;
    if (adaptiveBlur) {
      switch (deviceType) {
        case DeviceType.mobile:
          effectiveBlur = blur ?? 10.0;
          break;
        case DeviceType.tablet:
          effectiveBlur = blur != null ? blur! * 1.2 : 12.0;
          break;
        case DeviceType.desktop:
          effectiveBlur = blur != null ? blur! * 1.5 : 15.0;
          break;
        case DeviceType.widescreen:
          effectiveBlur = blur != null ? blur! * 2.0 : 20.0;
          break;
      }
    }
    
    // Create base glass container widget
    Widget containerWidget = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: effectiveBlur,
          sigmaY: effectiveBlur,
        ),
        child: Container(
          width: width,
          height: height,
          padding: effectivePadding,
          margin: margin,
          decoration: BoxDecoration(
            color: color ?? (isDark 
                ? Colors.black.withValues(alpha: 0.3) 
                : Colors.white.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? (isDark 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : Colors.white.withValues(alpha: 0.3)),
              width: 0.5,
            ),
            boxShadow: addShadow ? [
              BoxShadow(
                color: shadowColor ?? (isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1)),
                blurRadius: 10,
                spreadRadius: -5,
              ),
            ] : null,
            gradient: gradientColors != null ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors!.map((color) => color.withValues(alpha: isDark ? 0.15 : 0.1)).toList(),
            ) : null,
          ),
          child: child,
        ),
      ),
    );
    
    // Apply glow effect if requested
    if (addGlow) {
      containerWidget = TugAnimations.holographicGlow(
        child: containerWidget,
        glowIntensity: glowIntensity,
        colors: glowColor != null ? [glowColor!] : null,
        isDark: isDark,
      );
    }
    
    // Apply animation if requested
    if (animate) {
      switch (animationType) {
        case TugAnimationType.fadeIn:
          containerWidget = TugAnimations.fadeIn(
            child: containerWidget,
            duration: animationDuration,
            delay: animationDelay,
          );
          break;
        case TugAnimationType.fadeSlideUp:
          containerWidget = TugAnimations.fadeSlideIn(
            child: containerWidget,
            duration: animationDuration,
            delay: animationDelay,
            beginOffset: const Offset(0, 30),
          );
          break;
        case TugAnimationType.fadeSlideLeft:
          containerWidget = TugAnimations.fadeSlideIn(
            child: containerWidget,
            duration: animationDuration,
            delay: animationDelay,
            beginOffset: const Offset(30, 0),
          );
          break;
        case TugAnimationType.scale:
          containerWidget = TugAnimations.scaleIn(
            child: containerWidget,
            duration: animationDuration,
            delay: animationDelay,
          );
          break;
        case TugAnimationType.perspective:
          containerWidget = TugAnimations.perspectiveTransform(
            child: containerWidget,
            duration: animationDuration,
            delay: animationDelay,
            rotationY: 0.1,
            scale: 0.95,
          );
          break;
      }
    }
    
    return containerWidget;
  }
}

// Animation types for responsive containers
enum TugAnimationType {
  fadeIn,
  fadeSlideUp,
  fadeSlideLeft,
  scale,
  perspective,
}