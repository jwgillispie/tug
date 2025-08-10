// lib/widgets/subscription/enhanced_subscription_content.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tug/blocs/subscription/subscription_bloc.dart';
import 'package:tug/models/subscription_model.dart';
import 'package:tug/utils/animations.dart';
import 'package:tug/utils/theme/colors.dart';

/// Enhanced subscription content with improved conversion optimization
class EnhancedSubscriptionContent extends StatelessWidget {
  final List<SubscriptionModel> subscriptions;
  final bool isPremium;
  final String? source; // For tracking conversion sources

  const EnhancedSubscriptionContent({
    super.key,
    required this.subscriptions,
    required this.isPremium,
    this.source,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isPremium) {
      return _buildPremiumContent(context, isDarkMode);
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Section
          _buildHeroSection(context, isDarkMode),
          
          // Social Proof Banner
          _buildSocialProofBanner(context, isDarkMode),
          
          // Features Showcase
          _buildFeaturesShowcase(context, isDarkMode),
          
          // Pricing Section
          if (subscriptions.isNotEmpty)
            _buildPricingSection(context, isDarkMode),
          
          // Testimonials
          _buildTestimonials(context, isDarkMode),
          
          // FAQ Section
          _buildFAQSection(context, isDarkMode),
          
          // Bottom CTA
          _buildBottomCTA(context, isDarkMode),
          
          // Legal Info
          _buildLegalInfo(context, isDarkMode),
          
          const SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDarkMode
                ? TugColors.primaryPurple.withValues(alpha: 0.1)
                : TugColors.primaryPurple.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Premium crown animation
          TugAnimations.pulsate(
            minScale: 0.95,
            maxScale: 1.05,
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
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title with gradient
          ShaderMask(
            shaderCallback: (bounds) => TugColors.getPrimaryGradient()
                .createShader(bounds),
            child: Text(
              'Unlock Your Full Potential',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          
          // Subtitle
          Text(
            'Join thousands of achievers who\'ve transformed their habits with Tug Pro',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Value proposition badges
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildValueBadge('10,000+ Users', Icons.people, Colors.blue),
              _buildValueBadge('4.9★ Rating', Icons.star, Colors.amber),
              _buildValueBadge('30-Day Guarantee', Icons.verified, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialProofBanner(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.1),
            Colors.red.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          TugAnimations.pulsate(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.red.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔥 147 people upgraded in the last 24 hours',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Join the community of high achievers!',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesShowcase(BuildContext context, bool isDarkMode) {
    final features = [
      {
        'icon': Icons.emoji_events,
        'title': 'Global Leaderboard',
        'description': 'Compete with 10,000+ users worldwide and climb to #1',
        'highlight': 'Most Popular',
        'color': Colors.amber.shade600,
      },
      {
        'icon': Icons.analytics,
        'title': 'Advanced Analytics',
        'description': 'Beautiful charts, insights, and progress tracking',
        'highlight': 'Data Driven',
        'color': Colors.blue.shade600,
      },
      {
        'icon': Icons.psychology,
        'title': 'AI Coaching',
        'description': 'Personalized tips and habit optimization',
        'highlight': 'Smart Insights',
        'color': Colors.orange.shade600,
      },
      {
        'icon': Icons.people,
        'title': 'Social Features',
        'description': 'Connect with friends and accountability partners',
        'highlight': 'Community',
        'color': Colors.green.shade600,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What You Get with Tug Pro',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Everything you need to achieve your goals faster',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          
          // Features grid
          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            
            return TugAnimations.staggeredListItem(
              index: index,
              type: StaggeredAnimationType.fadeSlideUp,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (feature['color'] as Color).withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (feature['color'] as Color).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Feature icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            feature['color'] as Color,
                            (feature['color'] as Color).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (feature['color'] as Color).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Feature content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                feature['title'] as String,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      feature['color'] as Color,
                                      (feature['color'] as Color).withValues(alpha: 0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  feature['highlight'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature['description'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Check icon
                    Icon(
                      Icons.check_circle,
                      color: feature['color'] as Color,
                      size: 24,
                    ),
                  ],
                ),
              ),
            );
          }),
          
          // Features overview link
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.push('/premium-features-overview?source=${source ?? "subscription"}'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: TugColors.primaryPurple.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: TugColors.primaryPurple.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Explore All Features',
                    style: TextStyle(
                      color: TugColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: TugColors.primaryPurple,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Plan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start your transformation today',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Pricing cards
          ...subscriptions.map((subscription) => _buildEnhancedPricingCard(
                context, 
                subscription, 
                isDarkMode,
              )),
        ],
      ),
    );
  }

  Widget _buildEnhancedPricingCard(
    BuildContext context, 
    SubscriptionModel subscription, 
    bool isDarkMode,
  ) {
    final isPopular = subscription.isPopular;
    
    return TugAnimations.fadeSlideIn(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: isPopular
              ? LinearGradient(
                  colors: [
                    TugColors.primaryPurple.withValues(alpha: 0.1),
                    TugColors.primaryPurple.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: isPopular 
              ? null 
              : (isDarkMode 
                  ? Colors.black.withValues(alpha: 0.3) 
                  : Colors.white.withValues(alpha: 0.9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPopular 
                ? TugColors.primaryPurple 
                : (isDarkMode ? Colors.white24 : Colors.black12),
            width: isPopular ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPopular 
                  ? TugColors.primaryPurple.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
              blurRadius: isPopular ? 20 : 8,
              offset: Offset(0, isPopular ? 8 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<SubscriptionBloc>().add(
                    PurchaseSubscription(subscription),
                  );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Popular badge
                  if (isPopular) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6, 
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: TugColors.getPrimaryGradient(),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: TugColors.getNeonGlow(
                          TugColors.primaryPurple,
                          intensity: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'MOST POPULAR - SAVE 60%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Plan details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscription.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subscription.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                height: 1.3,
                              ),
                            ),
                            if (subscription.savingsComparedToMonthly != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.savings,
                                      size: 14,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      subscription.savingsComparedToMonthly!,
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            subscription.formattedPrice,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: isPopular 
                                  ? TugColors.primaryPurple
                                  : (isDarkMode ? Colors.white : Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subscription.period,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white60
                                  : Colors.black45,
                            ),
                          ),
                          if (subscription.package.packageType == PackageType.annual) ...[
                            const SizedBox(height: 4),
                            Text(
                              '~\$${(subscription.monthlyEquivalentPrice).toStringAsFixed(2)}/month',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // CTA Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: isPopular
                          ? TugColors.getPrimaryGradient()
                          : LinearGradient(
                              colors: [Colors.grey.shade600, Colors.grey.shade700],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isPopular ? TugColors.primaryPurple : Colors.grey)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          context.read<SubscriptionBloc>().add(
                                PurchaseSubscription(subscription),
                              );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPopular ? Icons.rocket_launch : Icons.upgrade,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPopular ? 'Start Free Trial' : 'Get Started',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonials(BuildContext context, bool isDarkMode) {
    final testimonials = [
      {
        'name': 'Sarah M.',
        'role': 'Fitness Enthusiast',
        'text': 'Tug Pro changed how I track my habits. The leaderboard keeps me motivated every day!',
        'rating': 5,
        'avatar': '👩‍💼',
      },
      {
        'name': 'Alex K.',
        'role': 'Entrepreneur',
        'text': 'The AI coaching insights are incredibly accurate. It\'s like having a personal coach.',
        'rating': 5,
        'avatar': '🧑‍💻',
      },
      {
        'name': 'Jamie L.',
        'role': 'Student',
        'text': 'Best habit tracker I\'ve used. The social features help me stay accountable.',
        'rating': 5,
        'avatar': '👨‍🎓',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Our Users Say',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join thousands of satisfied users',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          
          // Testimonials
          ...testimonials.asMap().entries.map((entry) {
            final index = entry.key;
            final testimonial = entry.value;
            
            return TugAnimations.staggeredListItem(
              index: index,
              type: StaggeredAnimationType.fadeSlideUp,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating stars
                    Row(
                      children: List.generate(5, (starIndex) => Icon(
                        Icons.star,
                        size: 16,
                        color: starIndex < (testimonial['rating'] as int)
                            ? Colors.amber.shade600
                            : Colors.grey.withValues(alpha: 0.3),
                      )),
                    ),
                    const SizedBox(height: 12),
                    
                    // Testimonial text
                    Text(
                      '"${testimonial['text']}"',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // User info
                    Row(
                      children: [
                        Text(
                          testimonial['avatar'] as String,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              testimonial['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              testimonial['role'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          Icons.verified,
                          size: 18,
                          color: Colors.green.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, bool isDarkMode) {
    final faqs = [
      {
        'question': 'Can I cancel anytime?',
        'answer': 'Yes! Cancel your subscription anytime from your device settings. No questions asked.',
      },
      {
        'question': 'Is there a free trial?',
        'answer': 'Most subscriptions come with a free trial period. Start exploring premium features risk-free!',
      },
      {
        'question': 'What makes Tug Pro different?',
        'answer': 'Advanced analytics, AI coaching, global leaderboards, and social features designed to maximize your success.',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          ...faqs.map((faq) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.white24 : Colors.black12,
              ),
            ),
            child: ExpansionTile(
              title: Text(
                faq['question'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faq['answer'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TugColors.primaryPurple.withValues(alpha: 0.9),
            TugColors.primaryPurpleDark.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: TugColors.getNeonGlow(
          TugColors.primaryPurple,
          intensity: 0.5,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '⏰ Limited Time Offer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save 60% on your first year',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Join thousands who\'ve transformed their habits',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Restore purchases button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.read<SubscriptionBloc>().add(RestorePurchases());
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Already purchased? Restore',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalInfo(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Auto-renewable subscription. Cancel anytime in device settings. '
            'Payment charged to your app store account at confirmation. '
            'Subscription automatically renews unless auto-renew is turned off '
            'at least 24 hours before the end of the current period.',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white60 : Colors.black45,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => context.push('/terms'),
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 12,
                    color: TugColors.primaryPurple,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text(' • ', style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () => context.push('/privacy'),
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: TugColors.primaryPurple,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumContent(BuildContext context, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: TugAnimations.fadeSlideIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success animation
              TugAnimations.pulsate(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.3),
                        Colors.green.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.green, Colors.green.shade700],
                ).createShader(bounds),
                child: const Text(
                  'You\'re a Tug Pro Member!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Thank you for supporting Tug! You have access to all premium features.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Feature access indicators
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.1),
                      Colors.green.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Premium Features:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ...['Global Leaderboard', 'Advanced Analytics', 'AI Coaching', 'Social Features']
                        .map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.explore,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Explore Your Pro Features',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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
              
              const SizedBox(height: 16),
              
              // Manage subscription button
              OutlinedButton(
                onPressed: () => context.push('/user-subscription'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  side: BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Manage Subscription',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}