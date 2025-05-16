// lib/widgets/subscription/premium_feature.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/subscription/subscription_bloc.dart';
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
  
  const PremiumFeature({
    super.key,
    required this.child,
    this.title = 'Premium Feature',
    this.description = 'This feature is available with a premium subscription',
    this.icon = Icons.workspace_premium,
    this.useBlur = true,
    this.showPreview = true,
    this.buttonText,
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
          Opacity(
            opacity: 0.2,
            child: ImageFiltered(
              imageFilter: ColorFilter.mode(
                Colors.grey.withOpacity(0.8), 
                BlendMode.modulate,
              ),
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
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: TugColors.primaryPurple,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade300
                  : Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TugColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            onPressed: () {
              context.push('/subscription');
            },
            child: Text(buttonText ?? 'Upgrade to Premium'),
          ),
        ],
      ),
    );
  }
}