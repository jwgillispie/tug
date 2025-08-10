// lib/widgets/subscription/premium_feature.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/subscription/subscription_bloc.dart';
import 'package:tug/utils/animations.dart';
import 'package:tug/utils/theme/colors.dart';

/// Widget wrapper for premium features that can either show the feature
/// or a premium gate to encourage subscription.
class PremiumFeature extends StatelessWidget {
  /// The premium content to show for subscribers
  final Widget child;
  
  /// Text to display on the premium gate
  final String title;
  
  /// Description of the premium feature
  final String description;
  
  /// Icon to display in the premium gate
  final IconData icon;
  
  /// Whether to use a blur effect on the child when not premium
  final bool useBlur;
  
  /// Whether to show a preview of the feature (blurred/disabled) or hide completely
  final bool showPreview;
  
  /// Optional additional button text
  final String? buttonText;
  
  /// Amount of blur to apply to the content when useBlur is true
  final double blurAmount;
  
  /// Whether to show a cosmic particle effect in the premium overlay
  final bool showParticles;
  
  const PremiumFeature({
    super.key,
    required this.child,
    this.title = 'Premium Feature',
    this.description = 'This feature is available with a premium subscription',
    this.icon = Icons.workspace_premium,
    this.useBlur = true,
    this.showPreview = true,
    this.buttonText,
    this.blurAmount = 10.0,
    this.showParticles = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        bool isPremium = false;
        bool isDataStale = false;
        bool isOnline = true;
        
        // Check subscription state
        if (state is SubscriptionsLoaded) {
          isPremium = state.isPremium;
          isDataStale = state.isDataStale;
          isOnline = state.isOnline;
        }
        
        // If user has premium, return the child, but show warning if data is stale
        if (isPremium) {
          if (isDataStale && !isOnline) {
            // Show premium content with offline warning
            return Stack(
              children: [
                child,
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return child;
        }
        
        // If we can't verify premium status due to network issues, show a different gate
        if (isDataStale && !isOnline) {
          return _buildNetworkErrorGate(context);
        }
        
        // Otherwise show premium gate
        return _buildPremiumGate(context);
      },
    );
  }
  
  Widget _buildPremiumGate(BuildContext context) {
    if (showPreview && useBlur) {
      return Stack(
        children: [
          // Show blurred child as background
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurAmount,
              sigmaY: blurAmount,
            ),
            child: Opacity(
              opacity: 0.7,
              child: child,
            ),
          ),
          
          // Overlay with premium gate
          _buildPremiumPrompt(context),
        ],
      );
    } else if (showPreview) {
      // Show disabled child
      return Stack(
        children: [
          // Show grayscale child
          Opacity(
            opacity: 0.3,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.grey, 
                BlendMode.saturation,
              ),
              child: AbsorbPointer(child: child),
            ),
          ),
          
          // Overlay with premium gate
          _buildPremiumPrompt(context),
        ],
      );
    } else {
      // Hide child completely and show premium prompt
      return _buildPremiumPrompt(context);
    }
  }
  
  Widget _buildPremiumPrompt(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDarkMode 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.4),
            isDarkMode
                ? TugColors.primaryPurpleDark.withValues(alpha: 0.7)
                : TugColors.primaryPurple.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Premium icon with animation
            TugAnimations.pulsate(
              minScale: 0.95,
              maxScale: 1.05,
              duration: const Duration(milliseconds: 2000),
              addGlow: true,
              glowColor: TugColors.primaryPurple,
              glowIntensity: 1.0,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: TugColors.getPrimaryGradient(),
                  shape: BoxShape.circle,
                  boxShadow: TugColors.getNeonGlow(
                    TugColors.primaryPurple,
                    intensity: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Premium text with animation
            TugAnimations.fadeSlideIn(
              beginOffset: const Offset(0, 20),
              child: Column(
                children: [
                  // Title with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Upgrade button
                  TugAnimations.pulsate(
                    minScale: 0.98,
                    maxScale: 1.02,
                    duration: const Duration(milliseconds: 1800),
                    addGlow: true,
                    glowColor: TugColors.warning,
                    glowIntensity: 0.7,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            TugColors.gradientPurpleStart,
                            TugColors.gradientPurpleEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: TugColors.getNeonGlow(
                          TugColors.warning,
                          intensity: 0.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Navigate to subscription screen
                            context.push('/subscription');
                          },
                          borderRadius: BorderRadius.circular(16),
                          // Removed deprecated splashColor and highlightColor
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  buttonText ?? 'Upgrade to Premium',
                                  style: const TextStyle(
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
      ),
    );
  }
  
  Widget _buildNetworkErrorGate(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.black.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Network error icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.orange,
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.wifi_off,
                color: Colors.orange,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Error title
          const Text(
            'Connection Error',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Error description
          Text(
            'Unable to verify your subscription status. Please check your internet connection and try again.',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Retry button
          Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Trigger subscription refresh
                  context.read<SubscriptionBloc>().add(const RefreshSubscriptionStatus());
                },
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Try Again',
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
        ],
      ),
    );
  }
}