// lib/widgets/home/components/swipeable_feature_card.dart
import 'package:flutter/material.dart';
import '../../../utils/mobile_ux_utils.dart';
import '../../../utils/theme/colors.dart';

class SwipeableFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final String? leftSwipeLabel;
  final String? rightSwipeLabel;
  final IconData? leftSwipeIcon;
  final IconData? rightSwipeIcon;
  final bool enableLongPress;
  final VoidCallback? onLongPress;
  
  const SwipeableFeatureCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftSwipeLabel,
    this.rightSwipeLabel,
    this.leftSwipeIcon,
    this.rightSwipeIcon,
    this.enableLongPress = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    Widget cardContent = _buildCard(context, isDarkMode);
    
    // Wrap with swipe functionality if swipe callbacks are provided
    if (onSwipeLeft != null || onSwipeRight != null) {
      cardContent = MobileUXUtils.swipeableListItem(
        onSwipeLeft: onSwipeLeft,
        onSwipeRight: onSwipeRight,
        leftSwipeLabel: leftSwipeLabel,
        rightSwipeLabel: rightSwipeLabel,
        leftSwipeColor: onSwipeLeft != null ? Colors.blue : null,
        rightSwipeColor: onSwipeRight != null ? Colors.orange : null,
        leftSwipeIcon: leftSwipeIcon,
        rightSwipeIcon: rightSwipeIcon,
        child: cardContent,
      );
    }
    
    return cardContent;
  }

  Widget _buildCard(BuildContext context, bool isDarkMode) {
    return Semantics(
      label: '$title, $subtitle${enableLongPress ? ', long press for options' : ''}',
      button: onTap != null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? TugColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16), // More rounded for mobile
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.2) 
                  : Colors.black.withOpacity(0.08), // Softer shadow
              blurRadius: 12, // Increased blur
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.08) 
                : Colors.black.withOpacity(0.05),
            width: 0.5,
          ),
        ),
        child: MobileUXUtils.mobileButton(
          onPressed: onTap ?? () {},
          backgroundColor: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onLongPress: enableLongPress && onLongPress != null ? () {
              MobileUXUtils.provideHeavyHaptic();
              onLongPress!();
            } : null,
            child: Padding(
              padding: const EdgeInsets.all(20), // Increased padding for mobile
              child: Row(
                children: [
                  // Icon with better mobile sizing
                  Container(
                    padding: const EdgeInsets.all(16), // Increased padding
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(16), // More rounded
                      border: Border.all(
                        color: iconColor.withOpacity(isDarkMode ? 0.25 : 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 32, // Larger icon for mobile
                    ),
                  ),
                  const SizedBox(width: 20), // Increased spacing
                  // Text content with better mobile typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18, // Larger text for mobile
                            fontWeight: FontWeight.w600,
                            color: isDarkMode 
                                ? TugColors.darkTextPrimary 
                                : TugColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6), // Increased spacing
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 15, // Larger subtitle for mobile
                            color: isDarkMode 
                                ? TugColors.darkTextSecondary 
                                : TugColors.lightTextSecondary,
                            height: 1.4, // Better line height
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Improved arrow with better touch target
                  if (onTap != null)
                    Container(
                      width: MobileUXUtils.minTouchTarget * 0.8,
                      height: MobileUXUtils.minTouchTarget * 0.8,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(isDarkMode ? 0.1 : 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: iconColor.withOpacity(0.7),
                        size: 16,
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