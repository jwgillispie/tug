// lib/utils/mobile_ux_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// Mobile-first UX utilities for professional touch interactions
class MobileUXUtils {
  // Minimum touch target size (44dp for iOS, 48dp for Material)
  static const double minTouchTarget = 44.0;
  
  // Thumb-zone safe areas (bottom 1/3 of screen is most reachable)
  static const double thumbZoneHeight = 0.33;
  
  // Gesture thresholds
  static const double swipeThreshold = 100.0;
  static const double longPressThreshold = 500.0; // milliseconds
  
  /// Check if device is iOS
  static bool get isIOS => Platform.isIOS;
  
  /// Check if device is Android
  static bool get isAndroid => Platform.isAndroid;
  
  /// Get platform-appropriate haptic feedback
  static void provideLightHaptic() {
    HapticFeedback.lightImpact();
  }
  
  static void provideMediumHaptic() {
    HapticFeedback.mediumImpact();
  }
  
  static void provideHeavyHaptic() {
    HapticFeedback.heavyImpact();
  }
  
  static void provideSelectionHaptic() {
    HapticFeedback.selectionClick();
  }
  
  /// Get safe area padding for bottom navigation
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }
  
  /// Check if position is in thumb-friendly zone
  static bool isInThumbZone(BuildContext context, double yPosition) {
    final screenHeight = MediaQuery.of(context).size.height;
    final thumbZoneStart = screenHeight * (1 - thumbZoneHeight);
    return yPosition >= thumbZoneStart;
  }
  
  /// Get thumb-friendly positioning for elements
  static double getThumbFriendlyPosition(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * (1 - thumbZoneHeight + 0.1); // 10% into thumb zone
  }
  
  /// Wrap widget with minimum touch target
  static Widget ensureTouchTarget(Widget child, {double? size}) {
    final targetSize = size ?? minTouchTarget;
    return SizedBox(
      width: targetSize,
      height: targetSize,
      child: Center(child: child),
    );
  }
  
  /// Create mobile-optimized button with proper touch targets
  static Widget mobileButton({
    required Widget child,
    required VoidCallback onPressed,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    bool enableHaptics = true,
  }) {
    return Semantics(
      button: true,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            if (enableHaptics) provideLightHaptic();
            onPressed();
          },
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: minTouchTarget,
              minHeight: minTouchTarget,
            ),
            padding: padding ?? const EdgeInsets.all(12),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
  
  /// Create swipe-enabled list item
  static Widget swipeableListItem({
    required Widget child,
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    String? leftSwipeLabel,
    String? rightSwipeLabel,
    Color? leftSwipeColor,
    Color? rightSwipeColor,
    IconData? leftSwipeIcon,
    IconData? rightSwipeIcon,
  }) {
    return Dismissible(
      key: UniqueKey(),
      background: leftSwipeColor != null ? Container(
        color: leftSwipeColor,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leftSwipeIcon != null)
              Icon(leftSwipeIcon, color: Colors.white),
            if (leftSwipeLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                leftSwipeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ) : null,
      secondaryBackground: rightSwipeColor != null ? Container(
        color: rightSwipeColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (rightSwipeLabel != null) ...[
              Text(
                rightSwipeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (rightSwipeIcon != null)
              Icon(rightSwipeIcon, color: Colors.white),
          ],
        ),
      ) : null,
      onDismissed: (direction) {
        provideMediumHaptic();
        if (direction == DismissDirection.startToEnd && onSwipeLeft != null) {
          onSwipeLeft();
        } else if (direction == DismissDirection.endToStart && onSwipeRight != null) {
          onSwipeRight();
        }
      },
      child: child,
    );
  }
  
  /// Create pull-to-refresh wrapper
  static Widget pullToRefresh({
    required Widget child,
    required Future<void> Function() onRefresh,
    Color? color,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        provideLightHaptic();
        await onRefresh();
      },
      color: color,
      child: child,
    );
  }
  
  /// Handle keyboard avoidance for forms
  static Widget keyboardAwareScroll({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return SingleChildScrollView(
      padding: padding,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: child,
    );
  }
  
  /// Create context menu with haptic feedback
  static Future<void> showContextMenu({
    required BuildContext context,
    required List<ContextMenuItem> items,
    Offset? position,
  }) async {
    provideSelectionHaptic();
    
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final RelativeRect positionRect = position != null && overlay != null
        ? RelativeRect.fromRect(
            Rect.fromPoints(position, position),
            Offset.zero & overlay.size,
          )
        : const RelativeRect.fromLTRB(0, 0, 0, 0);
    
    final result = await showMenu<String>(
      context: context,
      position: positionRect,
      items: items.map((item) => PopupMenuItem<String>(
        value: item.value,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.icon != null) ...[
              Icon(item.icon, size: 20),
              const SizedBox(width: 12),
            ],
            Text(item.title),
          ],
        ),
      )).toList(),
    );
    
    if (result != null) {
      provideLightHaptic();
      final selectedItem = items.firstWhere((item) => item.value == result);
      selectedItem.onTap();
    }
  }
}

/// Context menu item model
class ContextMenuItem {
  final String title;
  final IconData? icon;
  final VoidCallback onTap;
  final String value;
  
  const ContextMenuItem({
    required this.title,
    required this.onTap,
    required this.value,
    this.icon,
  });
}