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
        
        // Check subscription state
        if (state is SubscriptionsLoaded) {
          isPremium = state.isPremium;
        }
        
        // If user has premium, simply return the child
        if (isPremium) {
          return child;
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
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.4),
            isDarkMode
                ? TugColors.primaryPurpleDark.withOpacity(0.7)
                : TugColors.primaryPurple.withOpacity(0.6),
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
                      colors: TugColors.holographicGradient,
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
                    glowColor: TugColors.tertiaryGold,
                    glowIntensity: 0.7,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            TugColors.gradientGoldStart,
                            TugColors.gradientGoldEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: TugColors.getNeonGlow(
                          TugColors.tertiaryGold,
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
                          splashColor: Colors.white.withOpacity(0.3),
                          highlightColor: Colors.white.withOpacity(0.1),
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
}