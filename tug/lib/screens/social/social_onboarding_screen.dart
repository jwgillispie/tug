import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/theme/colors.dart';
import '../../services/app_mode_service.dart';
import 'user_search_screen.dart';

class SocialOnboardingScreen extends StatefulWidget {
  const SocialOnboardingScreen({super.key});

  @override
  State<SocialOnboardingScreen> createState() => _SocialOnboardingScreenState();
}

class _SocialOnboardingScreenState extends State<SocialOnboardingScreen> {
  final AppModeService _appModeService = AppModeService();
  final PageController _pageController = PageController();
  
  AppMode _currentMode = AppMode.valuesMode;
  int _currentPage = 0;
  StreamSubscription<AppMode>? _modeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeMode();
  }

  void _initializeMode() async {
    await _appModeService.initialize();
    _modeSubscription = _appModeService.modeStream.listen((mode) {
      if (mounted) {
        setState(() {
          _currentMode = mode;
        });
      }
    });
    if (mounted) {
      setState(() {
        _currentMode = _appModeService.currentMode;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    Navigator.of(context).pop();
  }

  void _completeOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const UserSearchScreen()),
    );
  }

  @override
  void dispose() {
    _modeSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;

    return Scaffold(
      backgroundColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skipOnboarding,
            child: Text(
              'Skip',
              style: TextStyle(
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? TugColors.getPrimaryColor(isViceMode)
                        : TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          
          // Content pages
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildWelcomePage(isDarkMode, isViceMode),
                _buildFeaturesPage(isDarkMode, isViceMode),
                _buildGetStartedPage(isDarkMode, isViceMode),
              ],
            ),
          ),
          
          // Bottom navigation
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(
                      'Back',
                      style: TextStyle(
                        color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 60),
                
                ElevatedButton(
                  onPressed: _currentPage == 2 ? _completeOnboarding : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TugColors.getPrimaryColor(isViceMode),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(_currentPage == 2 ? 'Get Started' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(bool isDarkMode, bool isViceMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people,
              size: 60,
              color: TugColors.getPrimaryColor(isViceMode),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Social',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: TugColors.getTextColor(isDarkMode, isViceMode),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Connect with others on their journey of growth and transformation. Share progress, celebrate milestones, and find motivation together.',
            style: TextStyle(
              fontSize: 16,
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage(bool isDarkMode, bool isViceMode) {
    final features = [
      {
        'icon': Icons.auto_awesome,
        'title': 'Automatic Posts',
        'description': 'Your activities and milestones are automatically shared with friends',
      },
      {
        'icon': Icons.comment,
        'title': 'Engage & Support',
        'description': 'Like and comment on friends\' posts to show your support',
      },
      {
        'icon': Icons.emoji_events,
        'title': 'Celebrate Milestones',
        'description': 'Celebrate when friends hit 7, 30, 100+ days clean from vices',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Strava for Vices & Values',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: TugColors.getTextColor(isDarkMode, isViceMode),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...features.map((feature) => _buildFeatureItem(
            feature['icon'] as IconData,
            feature['title'] as String,
            feature['description'] as String,
            isDarkMode,
            isViceMode,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, bool isDarkMode, bool isViceMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: TugColors.getPrimaryColor(isViceMode),
              size: 24,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TugColors.getTextColor(isDarkMode, isViceMode),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedPage(bool isDarkMode, bool isViceMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add,
              size: 60,
              color: TugColors.getPrimaryColor(isViceMode),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Find Your Community',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: TugColors.getTextColor(isDarkMode, isViceMode),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Start by finding friends who are on similar journeys. Search by username or email to connect with people you know.',
            style: TextStyle(
              fontSize: 16,
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: TugColors.getPrimaryColor(isViceMode),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your posts are automatically created when you log activities or hit milestones!',
                    style: TextStyle(
                      fontSize: 14,
                      color: TugColors.getTextColor(isDarkMode, isViceMode),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}