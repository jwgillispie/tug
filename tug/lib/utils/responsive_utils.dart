// Enhanced responsive utilities for consistent UI across all device sizes
import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Device breakpoint constants
  static const double kMobileBreakpoint = 600;
  static const double kTabletBreakpoint = 900;
  static const double kDesktopBreakpoint = 1200;
  
  // Calculate if the device is in portrait or landscape mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  // Get the safe area padding
  static EdgeInsets getSafePadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  // Enhanced responsive grid count calculator with more granular control
  static int getGridCount(BuildContext context, {
    int? mobileCols, 
    int? tabletCols, 
    int? desktopCols,
    int? widescreenCols,
  }) {
    double width = MediaQuery.of(context).size.width;
    
    if (width < kMobileBreakpoint) return mobileCols ?? 2;
    if (width < kTabletBreakpoint) return tabletCols ?? 3;
    if (width < kDesktopBreakpoint) return desktopCols ?? 4;
    return widescreenCols ?? 5; // Extra large displays
  }
  
  // Get device type for conditional layouts
  static DeviceType getDeviceType(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    
    if (width < kMobileBreakpoint) return DeviceType.mobile;
    if (width < kTabletBreakpoint) return DeviceType.tablet;
    if (width < kDesktopBreakpoint) return DeviceType.desktop;
    return DeviceType.widescreen;
  }
  
  // Calculate responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double baseValue = 16.0,
    double? mobileFactor,
    double? tabletFactor,
    double? desktopFactor,
  }) {
    final deviceType = getDeviceType(context);
    double factor = 1.0;
    
    switch (deviceType) {
      case DeviceType.mobile:
        factor = mobileFactor ?? 1.0;
        break;
      case DeviceType.tablet:
        factor = tabletFactor ?? 1.2;
        break;
      case DeviceType.desktop:
        factor = desktopFactor ?? 1.5;
        break;
      case DeviceType.widescreen:
        factor = desktopFactor ?? 2.0;
        break;
    }
    
    return EdgeInsets.all(baseValue * factor);
  }
  
  // Get responsive font size based on screen size
  static double getResponsiveFontSize(BuildContext context, {
    required double baseFontSize,
    double mobileScaleFactor = 1.0,
    double tabletScaleFactor = 1.1,
    double desktopScaleFactor = 1.2,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return baseFontSize * mobileScaleFactor;
      case DeviceType.tablet:
        return baseFontSize * tabletScaleFactor;
      case DeviceType.desktop:
      case DeviceType.widescreen:
        return baseFontSize * desktopScaleFactor;
    }
  }
  
  // Calculate content width with max width constraints
  static double getContentWidth(BuildContext context, {double maxWidth = 1200}) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > maxWidth ? maxWidth : screenWidth;
  }
  
  // Get appropriate widget size based on screen size
  static double getResponsiveSize(BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileSize;
      case DeviceType.tablet:
        return tabletSize ?? (mobileSize * 1.3);
      case DeviceType.desktop:
      case DeviceType.widescreen:
        return desktopSize ?? (mobileSize * 1.5);
    }
  }
  
  // Helper method to add responsive spacing
  static Widget verticalSpace(BuildContext context, {double mobileFactor = 1.0}) {
    final deviceType = getDeviceType(context);
    double baseSize = 16.0;
    
    switch (deviceType) {
      case DeviceType.mobile:
        return SizedBox(height: baseSize * mobileFactor);
      case DeviceType.tablet:
        return SizedBox(height: baseSize * mobileFactor * 1.2);
      case DeviceType.desktop:
      case DeviceType.widescreen:
        return SizedBox(height: baseSize * mobileFactor * 1.5);
    }
  }
  
  // Create a responsive layout builder with conditional widget rendering
  static Widget responsiveBuilder({
    required BuildContext context,
    required Widget Function(BuildContext, DeviceType) builder,
    Widget? mobileWidget,
    Widget? tabletWidget,
    Widget? desktopWidget,
    Widget? widescreenWidget,
  }) {
    final deviceType = getDeviceType(context);
    
    // If specific widgets are provided for device types, use them
    switch (deviceType) {
      case DeviceType.mobile:
        if (mobileWidget != null) return mobileWidget;
        break;
      case DeviceType.tablet:
        if (tabletWidget != null) return tabletWidget;
        break;
      case DeviceType.desktop:
        if (desktopWidget != null) return desktopWidget;
        break;
      case DeviceType.widescreen:
        if (widescreenWidget != null) return widescreenWidget;
        break;
    }
    
    // Otherwise use the builder function
    return builder(context, deviceType);
  }
}

// Device type enum for responsive design
enum DeviceType {
  mobile,
  tablet,
  desktop,
  widescreen,
}