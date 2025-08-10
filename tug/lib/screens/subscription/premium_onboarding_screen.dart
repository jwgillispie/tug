// lib/screens/subscription/premium_onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/services/api_service.dart';
import 'package:tug/utils/animations.dart';
import 'package:tug/utils/theme/colors.dart';

/// Premium onboarding screen that welcomes new premium users and guides them
/// through their premium features. Designed to increase feature adoption
/// and user satisfaction.
class PremiumOnboardingScreen extends StatefulWidget {
  const PremiumOnboardingScreen({super.key});

  @override
  State<PremiumOnboardingScreen> createState() => _PremiumOnboardingScreenState();
}

class _PremiumOnboardingScreenState extends State<PremiumOnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _progressController;
  late Animation<double> _celebrationScale;
  late Animation<double> _progressValue;
  
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final List<bool> _completedSteps = [false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _celebrationScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    
    // Start celebration animation
    _celebrationController.forward();
    _updateProgress();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final progress = (_currentStep + 1) / _getOnboardingSteps().length;
    _progressController.animateTo(progress);
  }

  void _nextStep() {
    if (_currentStep < _getOnboardingSteps().length - 1) {
      setState(() {
        _completedSteps[_currentStep] = true;
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    } else {
      _finishOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() {
      _completedSteps[_currentStep] = true;
    });
    
    try {
      // Mark onboarding as completed in backend
      final apiService = ApiService();
      await apiService.put('/users/premium-onboarding-completed');
    } catch (e) {
      debugPrint('Failed to mark premium onboarding as completed: $e');
    }
    
    // Show completion celebration
    await _showCompletionCelebration();
    
    // Navigate to main app
    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _showCompletionCelebration() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TugAnimations.fadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  TugColors.primaryPurple.withValues(alpha: 0.9),
                  TugColors.primaryPurpleDark.withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: TugColors.getNeonGlow(
                TugColors.primaryPurple,
                intensity: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration icon
                TugAnimations.pulsate(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration,
                      size: 40,
                      color: TugColors.primaryPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  '🎉 Welcome to Tug Pro! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'You\'re all set up and ready to achieve amazing things!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: TugColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Let\'s Go!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final steps = _getOnboardingSteps();
    
    return Scaffold(
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
                    Color.lerp(Colors.white, TugColors.primaryPurple.withValues(alpha: 0.05), 0.5)!,
                    Color.lerp(Colors.white, Colors.indigo.withValues(alpha: 0.05), 0.8)!,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress
              _buildHeader(isDarkMode),
              
              // Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentStep = page;
                    });
                    _updateProgress();
                  },
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildStepContent(steps[index], isDarkMode),
                    );
                  },
                ),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Welcome animation
          AnimatedBuilder(
            animation: _celebrationScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _celebrationScale.value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: TugColors.getPrimaryGradient(),
                        shape: BoxShape.circle,
                        boxShadow: TugColors.getNeonGlow(
                          TugColors.primaryPurple,
                          intensity: 0.6,
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => TugColors.getPrimaryGradient()
                          .createShader(bounds),
                      child: const Text(
                        'Welcome to Tug Pro!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Progress bar
          AnimatedBuilder(
            animation: _progressValue,
            builder: (context, child) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Setup Progress',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Text(
                        '${_currentStep + 1} of ${_getOnboardingSteps().length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: TugColors.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressValue.value,
                      backgroundColor: isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        TugColors.primaryPurple,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(OnboardingStep step, bool isDarkMode) {
    return TugAnimations.fadeSlideIn(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Step icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  step.color.withValues(alpha: 0.2),
                  step.color.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: step.color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              step.icon,
              size: 48,
              color: step.color,
            ),
          ),
          const SizedBox(height: 32),
          
          // Title
          Text(
            step.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            step.description,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Interactive content
          if (step.interactiveWidget != null)
            step.interactiveWidget!,
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDarkMode) {
    final isLastStep = _currentStep == _getOnboardingSteps().length - 1;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Previous button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: TugColors.primaryPurple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          // Next/Finish button
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: TugColors.getPrimaryGradient(),
                borderRadius: BorderRadius.circular(16),
                boxShadow: TugColors.getNeonGlow(
                  TugColors.primaryPurple,
                  intensity: 0.3,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _nextStep,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'Get Started!' : 'Continue',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLastStep ? Icons.rocket_launch : Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
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
    );
  }

  List<OnboardingStep> _getOnboardingSteps() {
    return [
      OnboardingStep(
        icon: Icons.celebration,
        title: 'Welcome to Premium!',
        description: 'Thank you for upgrading to Tug Pro! You now have access to all our premium features designed to supercharge your habit tracking journey.',
        color: TugColors.primaryPurple,
      ),
      OnboardingStep(
        icon: Icons.emoji_events,
        title: 'Compete Globally',
        description: 'See how you rank against users worldwide on our leaderboard. Climb to the top and earn bragging rights!',
        color: Colors.amber.shade600,
        interactiveWidget: _buildLeaderboardDemo(),
      ),
      OnboardingStep(
        icon: Icons.analytics,
        title: 'Advanced Analytics',
        description: 'Get detailed insights into your habits with beautiful charts, progress tracking, and personalized recommendations.',
        color: Colors.blue.shade600,
        interactiveWidget: _buildAnalyticsDemo(),
      ),
      OnboardingStep(
        icon: Icons.psychology,
        title: 'AI Coaching',
        description: 'Receive personalized coaching tips and habit recommendations powered by AI to optimize your success.',
        color: Colors.orange.shade600,
        interactiveWidget: _buildAIDemo(),
      ),
      OnboardingStep(
        icon: Icons.workspace_premium,
        title: 'You\'re All Set!',
        description: 'Explore all the premium features at your own pace. We\'re here to help you achieve your goals!',
        color: Colors.green.shade600,
      ),
    ];
  }

  Widget _buildLeaderboardDemo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '🏆 Your Current Ranking',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade300, Colors.amber.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '#42',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'out of 10,000+ users',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsDemo() {
    return Container(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Column(
        children: [
          Text(
            '📊 Your Progress This Week',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '85%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Completion',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '12',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Day Streak',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '2.3x',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'Improvement',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIDemo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'AI Coaching Tip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '"Based on your patterns, try scheduling your workouts for 7 AM - you\'re 73% more likely to complete them at this time!"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class for onboarding steps
class OnboardingStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Widget? interactiveWidget;

  const OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.interactiveWidget,
  });
}