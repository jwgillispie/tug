import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TugLandingPage extends StatefulWidget {
  const TugLandingPage({Key? key}) : super(key: key);

  @override
  State<TugLandingPage> createState() => _TugLandingPageState();
}

class _TugLandingPageState extends State<TugLandingPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _submitted = false;
  late AnimationController _animationController;
  late Animation<double> _tugAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _tugAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSubscribe() {
    debugPrint('Subscription email: ${_emailController.text}');
    setState(() {
      _submitted = true;
      _emailController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9F5FF), Color(0xFFF0FDFA)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 100,
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildNavigation(),
                collapseMode: CollapseMode.pin,
              ),
              backgroundColor: Colors.white.withOpacity(0.9),
              elevation: 0,
            ),

            // Hero Section
            SliverToBoxAdapter(
              child: _buildHeroSection(),
            ),

            // Features Section
            SliverToBoxAdapter(
              child: _buildFeaturesSection(),
            ),

            // Testimonials
            SliverToBoxAdapter(
              child: _buildTestimonials(),
            ),

            // Pricing/CTA
            SliverToBoxAdapter(
              child: _buildPricing(),
            ),

            // Footer
            SliverToBoxAdapter(
              child: _buildFooter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'T',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'tug',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Align your actions with your values',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tug helps you visualize the pull between what you say matters and how you actually spend your time.',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 32),
              if (!_submitted)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintStyle: const TextStyle(color: Colors.black),
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF7C3AED)),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleSubscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Notify Me',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Be the first to know when we launch.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Text(
                    'Thanks for your interest! We\'ll notify you when the app launches.',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 48),
          _buildAppVisualization(),
        ],
      ),
    );
  }

  Widget _buildAppVisualization() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Tug, like tug of war or tug of time.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 32,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.25,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9D5FF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.25,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFAFFEEC),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SizedBox(
                      width: 2,
                      child: ColoredBox(color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: MediaQuery.of(context).size.width * 0.3,
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      'Stated Values',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      'Actual Behavior',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildActivityCard('Family', 120, const Color(0xFF7C3AED)),
          const SizedBox(height: 16),
          _buildActivityCard('Health', 45, const Color(0xFFEF4444)),
          const SizedBox(height: 24),
          const Text(
            'Coming soon to App Store',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String name, int minutes, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$minutes mins',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          const Text(
            'How Tug Works',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureCard(
                Icons.star_outline,
                'Define Your Values',
                'Identify what truly matters to you and rate their importance.',
              ),
              _buildFeatureCard(
                Icons.access_time,
                'Track Activities',
                'Log time spent on activities related to your values.',
              ),
              _buildFeatureCard(
                Icons.bar_chart,
                'See Your Alignment',
                'Visualize how your daily actions align with your stated values.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              icon,
              size: 32,
              color: const Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Have questions or feedback? We\'d love to hear from you.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              _buildContactItem(
                  Icons.email, 'Email', 'jordangillispie@outlook.com'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF7C3AED),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF7C3AED),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      color: const Color(0xFF1F2937),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'tug',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '© ${DateTime.now().year} Tug App. All rights reserved.',
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Add these methods to your _TugLandingPageState class
Widget _buildTestimonials() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
    color: const Color(0xFFF0FDFA),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Loved by early users',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'See how Tug is helping people align their actions with their values',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF4B5563),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 60),

        // Testimonial cards
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            _buildTestimonialCard(
              'Sarah K.',
              'Product Designer',
              'Tug made me realize I was spending 80% of my time on things I only valued at 20%. The visualization was a wake-up call!',
              Icons.star,
              Icons.star,
              Icons.star,
              Icons.star,
              Icons.star,
              const Color(0xFF7C3AED),
            ),
            _buildTestimonialCard(
              'Michael T.',
              'Startup Founder',
              'As someone who struggles with work-life balance, seeing the literal tug-of-war between my values and actions was transformative.',
              Icons.star,
              Icons.star,
              Icons.star,
              Icons.star,
              Icons.star_half,
              const Color(0xFF0D9488),
            ),
            _buildTestimonialCard(
              'Priya M.',
              'Medical Resident',
              'The simple act of tracking against my stated values created accountability I never got from regular habit trackers.',
              Icons.star,
              Icons.star,
              Icons.star,
              Icons.star,
              Icons.star,
              const Color(0xFFEF4444),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildTestimonialCard(
  String name,
  String role,
  String quote,
  IconData star1,
  IconData star2,
  IconData star3,
  IconData star4,
  IconData star5,
  Color color,
) {
  return Container(
    width: 360,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.deepPurple,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          quote,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF4B5563),
            height: 1.6,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(star1, color: const Color(0xFFF59E0B)),
            Icon(star2, color: const Color(0xFFF59E0B)),
            Icon(star3, color: const Color(0xFFF59E0B)),
            Icon(star4, color: const Color(0xFFF59E0B)),
            Icon(star5, color: const Color(0xFFF59E0B)),
          ],
        ),
      ],
    ),
  );
}

Widget _buildPricing() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF9F5FF), Colors.white],
      ),
    ),
    child: Column(
      children: [
        const Text(
          'Simple, transparent pricing',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Start aligning your life today',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 60),

        // Pricing cards
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            _buildPricingCard(
              'Free',
              '\$0',
              'Forever',
              [
                'Basic value tracking',
                'Limited behavior logging',
                'Weekly alignment reports',
                'Community benchmarks',
              ],
              false,
              const Color(0xFF9CA3AF),
            ),
            _buildPricingCard(
              'Pro',
              '\$4.99',
              'per month',
              [
                'Unlimited values & tracking',
                'Daily insights & notifications',
                'Advanced visualizations',
                'Custom alignment goals',
                'Priority support',
                'Beta feature access',
              ],
              true,
              const Color(0xFF7C3AED),
            ),
            _buildPricingCard(
              'Founder',
              '\$49',
              'one-time',
              [
                'All Pro features',
                'Lifetime access',
                'Exclusive founder badge',
                'Early feature voting',
                'Personalized onboarding',
              ],
              false,
              const Color(0xFF0D9488),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildPricingCard(
  String title,
  String price,
  String period,
  List<String> features,
  bool highlighted,
  Color color,
) {
  return Container(
    width: 320,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: highlighted ? color : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: highlighted ? color : const Color(0xFFE5E7EB),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: highlighted ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          price,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: highlighted ? Colors.white : const Color(0xFF111827),
          ),
        ),
        Text(
          period,
          style: TextStyle(
            fontSize: 16,
            color: highlighted
                ? Colors.white.withOpacity(0.8)
                : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: features
              .map((feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: highlighted
                              ? Colors.white
                              : const Color(0xFF10B981),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          feature,
                          style: TextStyle(
                            color: highlighted
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: highlighted ? Colors.white : color,
            foregroundColor: highlighted ? color : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const SizedBox(
            width: double.infinity,
            child: Center(
              child: Text(
                'Get Started',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSocialIcon(IconData icon) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF1F2937),
    ),
    child: Center(
      child: Icon(
        icon,
        size: 16,
        color: const Color(0xFF9CA3AF),
      ),
    ),
  );
}
