import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/text_styles.dart';
import '../../utils/theme/buttons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: "Welcome to Tug",
      description: "Your personal companion for building positive habits and overcoming challenges. Let's get started on your journey to a better you.",
      icon: Icons.waving_hand,
      primaryColor: TugColors.primaryPurple,
    ),
    OnboardingSlide(
      title: "Track Your Values",
      description: "Define what matters most to you and track activities that align with your values. Build meaningful habits that reflect who you want to become.",
      icon: Icons.favorite,
      primaryColor: TugColors.primaryPurple,
    ),
    OnboardingSlide(
      title: "Overcome Your Vices",
      description: "Acknowledge your challenges with compassion. Track your progress in overcoming vices and celebrate every step forward on your journey.",
      icon: Icons.psychology,
      primaryColor: TugColors.viceGreen,
    ),
    OnboardingSlide(
      title: "Stay Motivated",
      description: "Monitor your progress, earn achievements, and connect with others on similar journeys. Your growth starts now.",
      icon: Icons.trending_up,
      primaryColor: TugColors.success,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (mounted) {
      context.go('/values-input');
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: TugColors.getBackgroundColor(isDark, false),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _slideController.reset();
                  _slideController.forward();
                },
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildSlide(_slides[index], isDark),
                    ),
                  );
                },
              ),
            ),
            _buildPageIndicator(isDark),
            _buildNavigationButtons(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tug',
            style: TugTextStyles.displaySmall.copyWith(
              color: TugColors.getTextColor(isDark, false),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: _skipOnboarding,
            style: TugButtons.tertiaryButtonStyle(isDark: isDark),
            child: Text('Skip'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  slide.primaryColor.withValues(alpha: 0.2),
                  slide.primaryColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: slide.primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              slide.icon,
              size: 60,
              color: slide.primaryColor,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            slide.title,
            style: TugTextStyles.displayMedium.copyWith(
              color: TugColors.getTextColor(isDark, false),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            slide.description,
            style: TugTextStyles.bodyLarge.copyWith(
              color: TugColors.getTextColor(isDark, false, isSecondary: true),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _totalPages,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: _currentPage == index ? 24.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: _currentPage == index
                  ? _slides[_currentPage].primaryColor
                  : TugColors.getTextColor(isDark, false, isSecondary: true).withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: TugButtons.secondaryButtonStyle(isDark: isDark),
                child: const Text('Back'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentPage == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: TugButtons.primaryButtonStyle(isDark: isDark),
              child: Text(_currentPage == _totalPages - 1 ? 'Get Started' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color primaryColor;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.primaryColor,
  });
}