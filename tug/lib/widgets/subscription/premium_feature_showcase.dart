// lib/widgets/subscription/premium_feature_showcase.dart
import 'package:flutter/material.dart';
import 'package:tug/utils/animations.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/screens/subscription/premium_features_overview_screen.dart';

/// Widget for showcasing individual premium features in the overview carousel
class PremiumFeatureShowcase extends StatelessWidget {
  final PremiumFeatureInfo feature;
  final bool isDarkMode;

  const PremiumFeatureShowcase({
    super.key,
    required this.feature,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return TugAnimations.fadeSlideIn(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Feature icon and title
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: TugColors.getPrimaryGradient(),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: TugColors.getNeonGlow(
                        TugColors.primaryPurple,
                        intensity: 0.3,
                      ),
                    ),
                    child: Icon(
                      feature.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: TugColors.getPrimaryGradient(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Description
              Text(
                feature.description,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Preview widget
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: feature.previewWidget,
              ),
              
              const SizedBox(height: 20),
              
              // Benefits list
              Text(
                'What you get:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              ...feature.benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: TugColors.getPrimaryGradient(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        benefit,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}