// lib/widgets/subscription/contextual_upgrade_prompt.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/subscription/subscription_bloc.dart';
import 'package:tug/services/api_service.dart';
import 'package:tug/utils/animations.dart';
import 'package:tug/utils/theme/colors.dart';

/// Contextual upgrade prompts that appear at strategic moments to encourage
/// premium subscriptions without being intrusive.
class ContextualUpgradePrompt extends StatelessWidget {
  final String promptType;
  final String title;
  final String description;
  final String ctaText;
  final IconData icon;
  final Color? accentColor;
  final String? benefitsList;
  final VoidCallback? onDismiss;
  final bool showDismiss;
  final String? source; // For analytics tracking

  const ContextualUpgradePrompt({
    super.key,
    required this.promptType,
    required this.title,
    required this.description,
    required this.ctaText,
    required this.icon,
    this.accentColor,
    this.benefitsList,
    this.onDismiss,
    this.showDismiss = true,
    this.source,
  });

  /// Factory constructor for leaderboard upgrade prompt
  factory ContextualUpgradePrompt.leaderboard({
    VoidCallback? onDismiss,
    String? source,
  }) {
    return ContextualUpgradePrompt(
      promptType: 'leaderboard',
      title: 'Unlock Full Leaderboard!',
      description: 'See your rank among all users and compete for the top spot.',
      ctaText: 'See My Ranking',
      icon: Icons.emoji_events,
      accentColor: Colors.amber.shade600,
      benefitsList: 'Global rankings • Friend comparisons • Achievement badges',
      onDismiss: onDismiss,
      source: source ?? 'leaderboard_view',
    );
  }

  /// Factory constructor for analytics upgrade prompt
  factory ContextualUpgradePrompt.analytics({
    VoidCallback? onDismiss,
    String? source,
  }) {
    return ContextualUpgradePrompt(
      promptType: 'analytics',
      title: 'Unlock Advanced Analytics!',
      description: 'Get detailed insights and progress tracking to optimize your habits.',
      ctaText: 'View My Analytics',
      icon: Icons.analytics,
      accentColor: Colors.blue.shade600,
      benefitsList: 'Progress charts • Habit insights • Data export • Weekly reports',
      onDismiss: onDismiss,
      source: source ?? 'analytics_view',
    );
  }

  /// Factory constructor for achievement milestone prompt
  factory ContextualUpgradePrompt.achievement({
    VoidCallback? onDismiss,
    String? source,
  }) {
    return ContextualUpgradePrompt(
      promptType: 'achievement_milestone',
      title: 'You\'re on Fire! 🔥',
      description: 'Celebrate your success with premium features designed for achievers like you.',
      ctaText: 'Unlock Pro Features',
      icon: Icons.celebration,
      accentColor: Colors.orange.shade600,
      benefitsList: 'Share achievements • Advanced tracking • AI coaching • Priority support',
      onDismiss: onDismiss,
      source: source ?? 'achievement_milestone',
    );
  }

  /// Factory constructor for streak milestone prompt
  factory ContextualUpgradePrompt.streakMilestone({
    required int streakDays,
    VoidCallback? onDismiss,
    String? source,
  }) {
    return ContextualUpgradePrompt(
      promptType: 'streak_milestone',
      title: '$streakDays Day Streak! 🎉',
      description: 'Amazing consistency! Pro features will help you maintain and extend your streaks.',
      ctaText: 'Keep the Streak Going',
      icon: Icons.local_fire_department,
      accentColor: Colors.red.shade600,
      benefitsList: 'Streak analytics • Habit insights • Motivation coaching • Community support',
      onDismiss: onDismiss,
      source: source ?? 'streak_$streakDays',
    );
  }

  /// Factory constructor for social features prompt
  factory ContextualUpgradePrompt.social({
    VoidCallback? onDismiss,
    String? source,
  }) {
    return ContextualUpgradePrompt(
      promptType: 'social',
      title: 'Connect with Friends!',
      description: 'Share your progress and get accountability support from the community.',
      ctaText: 'Join the Community',
      icon: Icons.people,
      accentColor: Colors.green.shade600,
      benefitsList: 'Friend feeds • Achievement sharing • Group challenges • Accountability',
      onDismiss: onDismiss,
      source: source ?? 'social_prompt',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        // Don't show if user is already premium
        if (state is SubscriptionsLoaded && state.isPremium) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<bool>(
          future: _shouldShowPrompt(context),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!) {
              return const SizedBox.shrink();
            }

            return _buildPrompt(context);
          },
        );
      },
    );
  }

  Widget _buildPrompt(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final effectiveAccentColor = accentColor ?? TugColors.primaryPurple;

    return TugAnimations.fadeSlideIn(
      beginOffset: const Offset(0, 50),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDarkMode
                  ? Colors.black.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.95),
              isDarkMode
                  ? effectiveAccentColor.withValues(alpha: 0.1)
                  : effectiveAccentColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: effectiveAccentColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveAccentColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      TugAnimations.pulsate(
                        minScale: 0.95,
                        maxScale: 1.05,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                effectiveAccentColor,
                                effectiveAccentColor.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: effectiveAccentColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    effectiveAccentColor.withValues(alpha: 0.8),
                                    effectiveAccentColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
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
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  
                  // Benefits list
                  if (benefitsList != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: effectiveAccentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: effectiveAccentColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: effectiveAccentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              benefitsList!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            effectiveAccentColor,
                            effectiveAccentColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: effectiveAccentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _handleUpgradeClick(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.rocket_launch,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  ctaText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
            
            // Dismiss button
            if (showDismiss)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => _handleDismiss(context),
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _shouldShowPrompt(BuildContext context) async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/subscription/should-show-prompt/$promptType');
      return response.data['should_show'] ?? false;
    } catch (e) {
      debugPrint('Error checking if prompt should be shown: $e');
      return false;
    }
  }

  Future<void> _trackPromptInteraction(String action, [Map<String, dynamic>? context]) async {
    try {
      final apiService = ApiService();
      await apiService.post('/subscription/upgrade-prompt', data: {
        'prompt_type': promptType,
        'action': action,
        'context': {
          ...?context,
          'source': source,
        },
      });
    } catch (e) {
      debugPrint('Error tracking prompt interaction: $e');
    }
  }

  void _handleUpgradeClick(BuildContext context) {
    _trackPromptInteraction('clicked');
    context.push('/subscription?source=$source&prompt=$promptType');
  }

  void _handleDismiss(BuildContext context) {
    _trackPromptInteraction('dismissed');
    onDismiss?.call();
  }
}

/// Smart upgrade prompt manager that shows contextual prompts based on user behavior
class SmartUpgradePromptManager extends StatefulWidget {
  final Widget child;

  const SmartUpgradePromptManager({
    super.key,
    required this.child,
  });

  @override
  State<SmartUpgradePromptManager> createState() => _SmartUpgradePromptManagerState();
}

class _SmartUpgradePromptManagerState extends State<SmartUpgradePromptManager> {
  ContextualUpgradePrompt? _currentPrompt;
  bool _isPromptVisible = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state is SubscriptionsLoaded && !state.isPremium) {
          _checkForPromptOpportunities();
        }
      },
      child: Stack(
        children: [
          widget.child,
          
          // Overlay prompt
          if (_isPromptVisible && _currentPrompt != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _currentPrompt!,
            ),
        ],
      ),
    );
  }

  void _checkForPromptOpportunities() {
    // This would be called based on user actions
    // For now, we'll show prompts based on navigation or specific triggers
    // In a real implementation, this would check various conditions
    
    // Example: Show leaderboard prompt when user views rankings
    if (ModalRoute.of(context)?.settings.name?.contains('rankings') == true) {
      _showPrompt(ContextualUpgradePrompt.leaderboard(
        onDismiss: _dismissPrompt,
        source: 'rankings_screen',
      ));
    }
  }

  void _showPrompt(ContextualUpgradePrompt prompt) {
    if (!_isPromptVisible) {
      setState(() {
        _currentPrompt = prompt;
        _isPromptVisible = true;
      });
      
      // Auto-dismiss after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isPromptVisible) {
          _dismissPrompt();
        }
      });
    }
  }

  void _dismissPrompt() {
    if (_isPromptVisible) {
      setState(() {
        _isPromptVisible = false;
        _currentPrompt = null;
      });
    }
  }
}

/// Extension methods for easy prompt triggering
extension ContextualUpgradePromptExtensions on BuildContext {
  void showAchievementMilestonePrompt() {
    final manager = findAncestorStateOfType<_SmartUpgradePromptManagerState>();
    manager?._showPrompt(ContextualUpgradePrompt.achievement(
      onDismiss: manager._dismissPrompt,
      source: 'achievement_milestone',
    ));
  }

  void showStreakMilestonePrompt(int streakDays) {
    final manager = findAncestorStateOfType<_SmartUpgradePromptManagerState>();
    manager?._showPrompt(ContextualUpgradePrompt.streakMilestone(
      streakDays: streakDays,
      onDismiss: manager._dismissPrompt,
      source: 'streak_milestone',
    ));
  }

  void showAnalyticsPrompt() {
    final manager = findAncestorStateOfType<_SmartUpgradePromptManagerState>();
    manager?._showPrompt(ContextualUpgradePrompt.analytics(
      onDismiss: manager._dismissPrompt,
      source: 'analytics_prompt',
    ));
  }
}