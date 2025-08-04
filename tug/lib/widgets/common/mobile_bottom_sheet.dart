// lib/widgets/common/mobile_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../../utils/mobile_ux_utils.dart';
import '../../utils/theme/colors.dart';

class MobileBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<MobileBottomSheetItem> items;
  final bool isViceMode;
  final bool isDismissible;
  final VoidCallback? onDismiss;
  
  const MobileBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    required this.isViceMode,
    this.isDismissible = true,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final safeArea = MediaQuery.of(context).padding.bottom;
    
    return Semantics(
      label: '$title bottom sheet with ${items.length} options',
      child: Container(
        decoration: BoxDecoration(
          color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24), // More rounded for mobile
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle for better mobile UX
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24, // Larger for mobile
                      color: TugColors.getTextColor(isDarkMode, isViceMode),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 16, // Larger for mobile
                        color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Items list
            ...items.map((item) => _buildItem(context, item, isDarkMode)),
            
            // Bottom safe area padding
            SizedBox(height: safeArea + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, MobileBottomSheetItem item, bool isDarkMode) {
    return Semantics(
      label: '${item.title}, ${item.description}',
      button: true,
      child: MobileUXUtils.mobileButton(
        onPressed: () {
          if (onDismiss != null) onDismiss!();
          item.onTap();
        },
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Icon with gradient background
            Container(
              width: 56, // Larger for mobile
              height: 56,
              decoration: BoxDecoration(
                gradient: item.gradient ?? LinearGradient(
                  colors: [
                    TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
                    TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (item.gradient?.colors.first ?? TugColors.getPrimaryColor(isViceMode))
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                item.icon,
                color: item.gradient?.colors.first ?? TugColors.getPrimaryColor(isViceMode),
                size: 28, // Larger icon
              ),
            ),
            const SizedBox(width: 20), // Increased spacing
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18, // Larger for mobile
                      color: TugColors.getTextColor(isDarkMode, isViceMode),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 15, // Larger for mobile
                      color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow indicator
            Icon(
              Icons.arrow_forward_ios,
              size: 18, // Larger for mobile
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            ),
          ],
        ),
      ),
    );
  }

  /// Show mobile-optimized bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required List<MobileBottomSheetItem> items,
    required bool isViceMode,
    bool isDismissible = true,
  }) {
    MobileUXUtils.provideLightHaptic();
    
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: true,
      isScrollControlled: true,
      builder: (context) => MobileBottomSheet(
        title: title,
        subtitle: subtitle,
        items: items,
        isViceMode: isViceMode,
        isDismissible: isDismissible,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class MobileBottomSheetItem {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final LinearGradient? gradient;
  
  const MobileBottomSheetItem({
    required this.icon,
    required this.title,  
    required this.description,
    required this.onTap,
    this.gradient,
  });
}