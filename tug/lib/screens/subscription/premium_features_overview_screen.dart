// lib/screens/subscription/premium_features_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/subscription/subscription_bloc.dart';
import 'package:tug/utils/animations.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/widgets/subscription/premium_feature_showcase.dart';

/// Comprehensive overview of all premium features with detailed explanations
/// and contextual upgrade prompts designed to increase conversion rates.
class PremiumFeaturesOverviewScreen extends StatefulWidget {
  final String? source; // Track where users came from for analytics
  
  const PremiumFeaturesOverviewScreen({
    super.key,
    this.source,
  });

  @override
  State<PremiumFeaturesOverviewScreen> createState() => _PremiumFeaturesOverviewScreenState();
}

class _PremiumFeaturesOverviewScreenState extends State<PremiumFeaturesOverviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _contentController;
  late Animation<double> _heroScale;
  late Animation<double> _contentOpacity;
  
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _heroScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.elasticOut),
    );
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeInOut),
    );
    
    // Start animations
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, state) {
              if (state is SubscriptionsLoaded && !state.isPremium) {
                return TextButton(
                  onPressed: () => context.push('/subscription'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: TugColors.getPrimaryGradient(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Upgrade',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    TugColors.darkBackground,
                    Color.lerp(TugColors.darkBackground, TugColors.primaryPurple, 0.1)!,
                    Color.lerp(TugColors.darkBackground, Colors.indigo.shade900, 0.15)!,
                  ]
                : [
                    Colors.white,
                    Color.lerp(Colors.white, TugColors.primaryPurple.withOpacity(0.05), 0.5)!,
                    Color.lerp(Colors.white, Colors.indigo.withOpacity(0.05), 0.8)!,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Hero Section
              _buildHeroSection(isDarkMode),
              
              // Features Carousel
              Expanded(
                child: _buildFeaturesCarousel(isDarkMode),
              ),
              
              // Bottom CTA Section
              _buildBottomCTASection(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _heroScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _heroScale.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Premium crown icon
                Container(
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
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title with shimmer effect
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      TugColors.primaryPurple,
                      TugColors.primaryPurpleLight,
                      TugColors.primaryPurpleDark,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'Tug Pro Features',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Unlock your full potential with premium features',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesCarousel(bool isDarkMode) {
    final features = _getPremiumFeatures();
    
    return FadeTransition(
      opacity: _contentOpacity,
      child: Column(
        children: [
          // Feature cards carousel
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: features.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: PremiumFeatureShowcase(
                    feature: features[index],
                    isDarkMode: isDarkMode,
                  ),
                );
              },
            ),
          ),
          
          // Page indicators
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                features.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? TugColors.primaryPurple
                        : TugColors.primaryPurple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTASection(bool isDarkMode) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        if (state is SubscriptionsLoaded && state.isPremium) {
          return _buildAlreadyPremiumSection(isDarkMode);
        }
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Value proposition
              Text(
                'Ready to unlock your potential?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Join thousands of users achieving their goals with Tug Pro',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // CTA Button
              TugAnimations.pulsate(
                minScale: 0.98,
                maxScale: 1.02,
                duration: const Duration(milliseconds: 2000),
                addGlow: true,
                glowColor: TugColors.warning,
                glowIntensity: 0.6,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          TugColors.gradientPurpleStart,
                          TugColors.gradientPurpleEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: TugColors.getNeonGlow(
                        TugColors.primaryPurple,
                        intensity: 0.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Track conversion event
                          _trackFeatureOverviewConversion();
                          context.push('/subscription');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rocket_launch,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Start Your Premium Journey',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Social proof
              Text(
                '⭐⭐⭐⭐⭐ Loved by 10,000+ users worldwide',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white60 : Colors.black45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlreadyPremiumSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re already a Pro!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have access to all these amazing features. Enjoy!',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<PremiumFeatureInfo> _getPremiumFeatures() {
    return [
      PremiumFeatureInfo(
        icon: Icons.emoji_events,
        title: 'Full Leaderboard Access',
        description: 'See where you rank among all users and compete for the top position. Track your progress against friends and the global community.',
        benefits: [
          'Global rankings visibility',
          'Friend comparisons',
          'Historical rank tracking',
          'Achievement badges',
        ],
        previewWidget: _buildLeaderboardPreview(),
        ctaText: 'Climb the Leaderboard',
      ),
      PremiumFeatureInfo(
        icon: Icons.analytics,
        title: 'Advanced Analytics',
        description: 'Get detailed insights into your habits, progress patterns, and optimization opportunities with comprehensive data visualization.',
        benefits: [
          'Detailed progress charts',
          'Habit correlation analysis',
          'Export your data',
          'Weekly insights reports',
        ],
        previewWidget: _buildAnalyticsPreview(),
        ctaText: 'Unlock Insights',
      ),
      PremiumFeatureInfo(
        icon: Icons.group,
        title: 'Social Features',
        description: 'Connect with friends, share achievements, and get accountability support from the Tug community.',
        benefits: [
          'Friend activity feeds',
          'Achievement sharing',
          'Accountability partners',
          'Group challenges',
        ],
        previewWidget: _buildSocialPreview(),
        ctaText: 'Join the Community',
      ),
      PremiumFeatureInfo(
        icon: Icons.psychology,
        title: 'AI Coaching & Insights',
        description: 'Get personalized recommendations and coaching based on your activity patterns and goals.',
        benefits: [
          'Personalized recommendations',
          'Habit optimization tips',
          'Progress predictions',
          'Smart goal suggestions',
        ],
        previewWidget: _buildAICoachingPreview(),
        ctaText: 'Get AI Coaching',
      ),
      PremiumFeatureInfo(
        icon: Icons.workspace_premium,
        title: 'Exclusive Features',
        description: 'Access premium themes, custom goals, priority support, and early access to new features.',
        benefits: [
          'Premium themes & customization',
          'Priority customer support',
          'Early access to features',
          'No ads experience',
        ],
        previewWidget: _buildExclusivePreview(),
        ctaText: 'Go Premium',
      ),
    ];
  }

  // Preview widgets for each feature
  Widget _buildLeaderboardPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TugColors.primaryPurple.withOpacity(0.1),
            TugColors.primaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                final names = ['You', 'Sarah M.', 'Alex K.'];
                final scores = ['1,247', '1,156', '998'];
                final ranks = ['#${index + 1}', '#${index + 2}', '#${index + 3}'];
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: index == 0 ? TugColors.primaryPurple.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: index == 0 ? Border.all(color: TugColors.primaryPurple, width: 1) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: index == 0 ? TugColors.primaryPurple : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            ranks[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          names[index],
                          style: TextStyle(
                            fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                            color: index == 0 ? TugColors.primaryPurple : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        scores[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'Detailed Charts & Insights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              'Track trends, patterns & optimize',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Connect & Share',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              'Friends, achievements, challenges',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAICoachingPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 64,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'AI Personal Coach',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Text(
              'Smart tips & recommendations',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExclusivePreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TugColors.primaryPurple.withOpacity(0.1),
            TugColors.primaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.diamond,
              size: 64,
              color: TugColors.primaryPurple,
            ),
            const SizedBox(height: 16),
            Text(
              'Premium Experience',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TugColors.primaryPurple,
              ),
            ),
            const Text(
              'Themes, support & more',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _trackFeatureOverviewConversion() {
    // Track conversion from features overview
    // This would integrate with your analytics service
    debugPrint('Feature overview conversion tracked from source: ${widget.source}');
  }
}

/// Data class for premium feature information
class PremiumFeatureInfo {
  final IconData icon;
  final String title;
  final String description;
  final List<String> benefits;
  final Widget previewWidget;
  final String ctaText;

  const PremiumFeatureInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.benefits,
    required this.previewWidget,
    required this.ctaText,
  });
}