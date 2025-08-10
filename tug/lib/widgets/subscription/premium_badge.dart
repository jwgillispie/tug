// lib/widgets/subscription/premium_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/subscription/subscription_bloc.dart';
import 'package:tug/utils/animations.dart';
import 'package:tug/utils/theme/colors.dart';

/// Premium badges and indicators to show throughout the app
class PremiumBadge extends StatelessWidget {
  final PremiumBadgeSize size;
  final PremiumBadgeStyle style;
  final bool showTooltip;
  final String? customText;
  final VoidCallback? onTap;

  const PremiumBadge({
    super.key,
    this.size = PremiumBadgeSize.small,
    this.style = PremiumBadgeStyle.gradient,
    this.showTooltip = true,
    this.customText,
    this.onTap,
  });

  /// Factory for locked feature indicators
  factory PremiumBadge.locked({
    PremiumBadgeSize size = PremiumBadgeSize.medium,
    VoidCallback? onTap,
  }) {
    return PremiumBadge(
      size: size,
      style: PremiumBadgeStyle.outlined,
      customText: 'LOCKED',
      onTap: onTap,
    );
  }

  /// Factory for coming soon features
  factory PremiumBadge.comingSoon({
    PremiumBadgeSize size = PremiumBadgeSize.small,
  }) {
    return PremiumBadge(
      size: size,
      style: PremiumBadgeStyle.outlined,
      customText: 'SOON',
      showTooltip: false,
    );
  }

  /// Factory for premium user indicators
  factory PremiumBadge.user({
    PremiumBadgeSize size = PremiumBadgeSize.small,
  }) {
    return PremiumBadge(
      size: size,
      style: PremiumBadgeStyle.solid,
      customText: 'PRO',
      showTooltip: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        // Don't show "locked" badges if user is premium
        if (customText == 'LOCKED' && 
            state is SubscriptionsLoaded && 
            state.isPremium) {
          return const SizedBox.shrink();
        }

        final badge = _buildBadge(context);
        
        if (showTooltip && customText != 'PRO') {
          return Tooltip(
            message: 'Upgrade to Tug Pro to unlock this feature',
            child: badge,
          );
        }
        
        return badge;
      },
    );
  }

  Widget _buildBadge(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final badgeSize = _getBadgeSize();
    final textStyle = _getTextStyle();
    final effectiveText = customText ?? 'PRO';

    Widget badge = TugAnimations.pulsate(
      minScale: 0.95,
      maxScale: 1.05,
      duration: Duration(milliseconds: customText == 'LOCKED' ? 2000 : 3000),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: badgeSize.width * 0.15,
          vertical: badgeSize.height * 0.1,
        ),
        constraints: BoxConstraints(
          minWidth: badgeSize.width,
          minHeight: badgeSize.height,
        ),
        decoration: _getDecoration(isDarkMode),
        child: Center(
          child: Text(
            effectiveText,
            style: textStyle,
          ),
        ),
      ),
    );

    if (onTap != null) {
      badge = GestureDetector(
        onTap: onTap ?? () => context.push('/subscription'),
        child: badge,
      );
    }

    return badge;
  }

  Size _getBadgeSize() {
    switch (size) {
      case PremiumBadgeSize.tiny:
        return const Size(24, 12);
      case PremiumBadgeSize.small:
        return const Size(32, 16);
      case PremiumBadgeSize.medium:
        return const Size(48, 24);
      case PremiumBadgeSize.large:
        return const Size(64, 32);
    }
  }

  TextStyle _getTextStyle() {
    final fontSize = switch (size) {
      PremiumBadgeSize.tiny => 8.0,
      PremiumBadgeSize.small => 10.0,
      PremiumBadgeSize.medium => 12.0,
      PremiumBadgeSize.large => 14.0,
    };

    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: style == PremiumBadgeStyle.outlined 
          ? TugColors.primaryPurple
          : Colors.white,
      letterSpacing: 1,
    );
  }

  BoxDecoration _getDecoration(bool isDarkMode) {
    switch (style) {
      case PremiumBadgeStyle.gradient:
        return BoxDecoration(
          gradient: TugColors.getPrimaryGradient(),
          borderRadius: BorderRadius.circular(12),
          boxShadow: TugColors.getNeonGlow(
            TugColors.primaryPurple,
            intensity: 0.3,
          ),
        );
      case PremiumBadgeStyle.solid:
        return BoxDecoration(
          color: TugColors.primaryPurple,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: TugColors.primaryPurple.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case PremiumBadgeStyle.outlined:
        return BoxDecoration(
          color: customText == 'LOCKED'
              ? Colors.grey.withValues(alpha: 0.1)
              : TugColors.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: customText == 'LOCKED'
                ? Colors.grey
                : TugColors.primaryPurple,
            width: 1.5,
          ),
        );
      case PremiumBadgeStyle.minimal:
        return BoxDecoration(
          color: TugColors.primaryPurple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        );
    }
  }
}

/// Premium feature indicator with action capability
class PremiumFeatureIndicator extends StatelessWidget {
  final Widget child;
  final String featureName;
  final String description;
  final bool isEnabled;
  final VoidCallback? onUpgradeRequested;

  const PremiumFeatureIndicator({
    super.key,
    required this.child,
    required this.featureName,
    required this.description,
    this.isEnabled = false,
    this.onUpgradeRequested,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        final isPremium = state is SubscriptionsLoaded && state.isPremium;
        
        if (isPremium || isEnabled) {
          return child;
        }

        return Stack(
          children: [
            // Disabled/dimmed content
            Opacity(
              opacity: 0.5,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.saturation,
                ),
                child: AbsorbPointer(child: child),
              ),
            ),
            
            // Premium overlay
            Positioned.fill(
              child: _buildPremiumOverlay(context),
            ),
            
            // Premium badge in top right
            Positioned(
              top: 8,
              right: 8,
              child: PremiumBadge.locked(
                onTap: onUpgradeRequested ?? () => context.push('/subscription'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumOverlay(BuildContext context) {
    return GestureDetector(
      onTap: onUpgradeRequested ?? () => context.push('/subscription'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: TugColors.getPrimaryGradient(),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                featureName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to upgrade',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium feature preview that shows a glimpse of what's possible
class PremiumFeaturePreview extends StatelessWidget {
  final Widget previewChild;
  final String title;
  final String description;
  final List<String> benefits;
  final VoidCallback? onUpgrade;

  const PremiumFeaturePreview({
    super.key,
    required this.previewChild,
    required this.title,
    required this.description,
    required this.benefits,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        final isPremium = state is SubscriptionsLoaded && state.isPremium;
        
        if (isPremium) {
          return previewChild;
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDarkMode
                    ? Colors.black.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.9),
                isDarkMode
                    ? TugColors.primaryPurple.withValues(alpha: 0.1)
                    : TugColors.primaryPurple.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: TugColors.primaryPurple.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Preview with blur effect
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Blurred preview
                      Opacity(
                        opacity: 0.6,
                        child: previewChild,
                      ),
                      
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              TugColors.primaryPurple.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                      
                      // Premium badge
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: PremiumBadge(),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Benefits
                    ...benefits.map((benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              benefit,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 20),
                    
                    // Upgrade button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: TugColors.getPrimaryGradient(),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: TugColors.getNeonGlow(
                            TugColors.primaryPurple,
                            intensity: 0.3,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onUpgrade ?? () => context.push('/subscription'),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upgrade,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Unlock This Feature',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Enums for badge customization
enum PremiumBadgeSize { tiny, small, medium, large }

enum PremiumBadgeStyle { gradient, solid, outlined, minimal }