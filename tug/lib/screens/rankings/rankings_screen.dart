// lib/screens/rankings/rankings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tug/blocs/subscription/subscription_bloc.dart';
import 'package:tug/models/ranking_model.dart';
import 'package:tug/services/rankings_service.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/animations.dart';
import 'package:tug/utils/loading_messages.dart';
import 'package:tug/widgets/subscription/premium_feature.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  final RankingsService _rankingsService = RankingsService();
  
  bool _isLoading = true;
  bool _isRefreshing = false; // For background refresh
  String? _errorMessage;
  RankingsListModel? _rankings;
  int _selectedPeriod = 30; // Default to 30 days
  
  final List<int> _periodOptions = [7, 30, 90, 365]; // Days options
  
  @override
  void initState() {
    super.initState();
    
    // Check if we should load all rankings or just current user
    final subscriptionState = context.read<SubscriptionBloc>().state;
    bool isPremium = false;
    
    if (subscriptionState is SubscriptionsLoaded) {
      isPremium = subscriptionState.isPremium;
    }
    
    // Always load rankings, as we'll show the current user's rank even for non-premium users
    _loadRankings();
  }
  
  // Refresh rankings data
  Future<void> _loadRankings({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    final hasExistingData = _rankings != null;
    
    // Determine loading state based on whether we have data
    setState(() {
      if (hasExistingData && !forceRefresh) {
        _isRefreshing = true; // Background refresh with existing data
      } else {
        _isLoading = true; // Full loading state with spinner
      }
      _errorMessage = null;
    });
    
    try {
      // Load new data (either from cache or API based on forceRefresh)
      final rankings = await _rankingsService.getTopUsers(
        days: _selectedPeriod,
        limit: 50, // Get up to 50 users
        rankBy: 'activities',
        forceRefresh: forceRefresh,
      );
      
      if (mounted) {
        setState(() {
          _rankings = rankings;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load rankings: $e';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }
  
  void _changePeriod(int days) {
    if (_selectedPeriod != days) {
      setState(() {
        _selectedPeriod = days;
        
        // Clear existing data when period changes
        _rankings = null;
      });
      
      // Load rankings with new period
      _loadRankings();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'leaderboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _isRefreshing
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _loadRankings(forceRefresh: true),
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
                    Color.lerp(TugColors.darkBackground, TugColors.primaryPurple, 0.1) ?? TugColors.darkBackground,
                    Color.lerp(TugColors.darkBackground, Colors.indigo.shade900, 0.15) ?? TugColors.darkBackground,
                  ] 
                : [
                    Colors.white,
                    Color.lerp(Colors.white, TugColors.primaryPurple.withOpacity(0.05), 0.5) ?? Colors.white,
                    Color.lerp(Colors.white, Colors.indigo.withOpacity(0.05), 0.8) ?? Colors.white,
                  ],
          ),
        ),
        child: Column(
          children: [
            // Spacer for the AppBar
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 16),
            
            // Time period selector (always visible)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'time period',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.3,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode 
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: SegmentedButton<int>(
                      segments: _periodOptions.map((days) {
                        final label = days == 365 ? '1 Year' : '$days Days';
                        return ButtonSegment<int>(
                          value: days,
                          label: Text(
                            label,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      selected: {_selectedPeriod},
                      onSelectionChanged: (Set<int> selection) {
                        if (selection.isNotEmpty) {
                          _changePeriod(selection.first);
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return TugColors.primaryPurple;
                            }
                            return null;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return isDarkMode ? Colors.white70 : Colors.black87;
                          },
                        ),
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            return TugColors.primaryPurple.withOpacity(0.1);
                          },
                        ),
                        side: WidgetStateProperty.resolveWith<BorderSide?>(
                          (Set<WidgetState> states) {
                            return BorderSide.none;
                          },
                        ),
                        shape: WidgetStateProperty.resolveWith<OutlinedBorder?>(
                          (Set<WidgetState> states) {
                            return RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Rankings content - wrapped with PremiumFeature
            Expanded(
              child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
                builder: (context, state) {
                  bool isPremium = false;
                  
                  // Check if user has premium access
                  if (state is SubscriptionsLoaded) {
                    isPremium = state.isPremium;
                  }
                  
                  // Show current user card before premium gate
                  if (!isPremium && _rankings != null && _rankings!.currentUserRank != null) {
                    // Find the current user and display their rank outside the premium gate
                    final currentUser = _rankings!.rankings.firstWhere(
                      (user) => user.isCurrentUser,
                      orElse: () => UserRankingModel(
                        rank: _rankings!.currentUserRank,
                        userId: '',
                        displayName: 'your ranking',
                        totalActivities: _rankings!.rankings.isNotEmpty 
                            ? _rankings!.rankings.first.totalActivities 
                            : 0,
                        totalDuration: _rankings!.rankings.isNotEmpty 
                            ? _rankings!.rankings.first.totalDuration 
                            : 0,
                        uniqueActivityDays: _rankings!.rankings.isNotEmpty 
                            ? _rankings!.rankings.first.uniqueActivityDays 
                            : 0,
                        avgDurationPerActivity: _rankings!.rankings.isNotEmpty 
                            ? _rankings!.rankings.first.avgDurationPerActivity 
                            : 0,
                        streak: _rankings!.rankings.isNotEmpty 
                            ? _rankings!.rankings.first.streak 
                            : 0,
                        rankingType: 'activities',
                        isCurrentUser: true,
                      ),
                    );
                    
                    return Column(
                      children: [
                        // Current user rank card (always visible) with highlight animation
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: TugAnimations.pulsate(
                            minScale: 0.98,
                            maxScale: 1.02,
                            duration: const Duration(milliseconds: 2000),
                            addGlow: true,
                            glowColor: TugColors.primaryPurple,
                            glowIntensity: 0.5,
                            child: TugAnimations.fadeSlideIn(
                              child: Stack(
                                children: [
                                  // Enhanced current user card
                                  _buildUserRankCard(
                                    currentUser,
                                    isDarkMode,
                                    isCurrentUserCard: true,
                                  ),
                                  
                                  // "Your Rank" banner on top
                                  Positioned(
                                    top: 0,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            TugColors.primaryPurple,
                                            TugColors.primaryPurpleDark,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: TugColors.primaryPurple.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'your rank',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Other rankings behind premium gate
                        Expanded(
                          child: PremiumFeature(
                            title: 'premium leaderboard',
                            description: 'See how you stack up against others and compete for the top position!',
                            buttonText: 'Unlock Full Rankings',
                            icon: Icons.emoji_events,
                            blurAmount: 6.0,
                            useBlur: true,
                            showPreview: true,
                            showParticles: true,
                            child: ConstrainedBox(
                              // Ensure minimum height so content is visible
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height * 0.5,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: _buildRankingsContent(isDarkMode, skipCurrentUser: true),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  // For premium users, show the full rankings
                  return _buildRankingsContent(isDarkMode);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRankingsContent(bool isDarkMode, {bool skipCurrentUser = false}) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy icon with shimmer effect
            TugAnimations.fadeSlideIn(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    TugColors.primaryPurple.withOpacity(0.7),
                    Colors.amber.shade600.withOpacity(0.8),
                    TugColors.primaryPurple.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Animated loading indicator
            Container(
              width: 200,
              height: 8,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  TugAnimations.shimmer(
                    child: Container(
                      width: 60,
                      height: 8,
                      decoration: BoxDecoration(
                        color: TugColors.primaryPurple.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Loading text
            TugAnimations.fadeSlideIn(
              beginOffset: const Offset(0, 10),
              delay: const Duration(milliseconds: 300),
              child: Text(
                LoadingMessages.getRankings(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: () => _loadRankings(forceRefresh: true),
        backgroundColor: isDarkMode ? TugColors.darkSurface : Colors.white,
        color: TugColors.primaryPurple,
        displacement: 30,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 88),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: TugAnimations.fadeSlideIn(
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode
                                ? [
                                    Colors.black.withOpacity(0.5),
                                    Colors.black.withOpacity(0.3),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.6),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.red.withOpacity(0.2)
                                : Colors.red.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Error icon with gradient
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.red.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  size: 64,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'connection error',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Retry button with gradient
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        TugColors.primaryPurple,
                                        Color(0xFF7D4DFF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: TugColors.primaryPurple.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _loadRankings(forceRefresh: true),
                                      borderRadius: BorderRadius.circular(30),
                                      splashColor: Colors.white.withOpacity(0.1),
                                      highlightColor: Colors.white.withOpacity(0.2),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.refresh_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'retry',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Pull indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.05),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.swipe_down_alt,
                                        size: 18,
                                        color: isDarkMode ? Colors.white70 : Colors.black54,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Pull to refresh',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
      );
    }
    
    if (_rankings == null || _rankings!.rankings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadRankings(forceRefresh: true),
        backgroundColor: isDarkMode ? TugColors.darkSurface : Colors.white,
        color: TugColors.primaryPurple,
        displacement: 30,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 88),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: TugAnimations.fadeSlideIn(
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode
                                ? [
                                    Colors.black.withOpacity(0.5),
                                    Colors.black.withOpacity(0.3),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.6),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Decorative trophy image
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  TugColors.primaryPurple.withOpacity(0.7),
                                  Colors.pink.withOpacity(0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Icon(
                                Icons.emoji_events_outlined,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'no rankings yet',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Be the first to log activities and claim the champion position on the leaderboard!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    TugColors.primaryPurple.withOpacity(0.8),
                                    Colors.purple.withOpacity(0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: TugColors.primaryPurple.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swipe_down_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Pull to refresh',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
      );
    }
    
    // Filter users with zero activities
    final List<UserRankingModel> activeUsers = _rankings!.rankings
        .where((user) => user.totalActivities > 0)
        .toList();
    
    return Column(
      children: [
        // Current user ranking card (if available and not skipped)
        if (_rankings!.currentUserRank != null && !skipCurrentUser)
          Builder(
            builder: (context) {
              // Find the current user in the rankings
              final currentUser = _rankings!.rankings
                  .firstWhere((user) => user.isCurrentUser, 
                    orElse: () => UserRankingModel(
                      rank: _rankings!.currentUserRank,
                      userId: '',
                      displayName: 'your ranking',
                      totalActivities: 0,
                      totalDuration: 0,
                      uniqueActivityDays: 0,
                      avgDurationPerActivity: 0,
                      streak: 0,
                      rankingType: 'activities',
                      isCurrentUser: true,
                    ),
                  );
              
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TugAnimations.fadeSlideIn(
                  child: _buildUserRankCard(
                    currentUser,
                    isDarkMode,
                    isCurrentUserCard: true,
                  ),
                ),
              );
            }
          ),
          
        // Top user winner podium
        if (activeUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildWinnerPodium(activeUsers, isDarkMode),
          ),
          
        // Full ranking list with pull-to-refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadRankings(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
              child: Column(
                children: activeUsers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final user = entry.value;
                  return TugAnimations.staggeredListItem(
                    index: index,
                    type: StaggeredAnimationType.fadeSlideUp,
                    child: _buildUserRankCard(user, isDarkMode),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWinnerPodium(List<UserRankingModel> users, bool isDarkMode) {
    // Only show the #1 user
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final topUser = users[0];
    
    // Enhanced gold gradient for champion
    final LinearGradient goldGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.amber.shade300, Colors.amber.shade600, Colors.amber.shade700],
    );
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      // Reduced size by 35% - from 260 to 169
      constraints: const BoxConstraints(minHeight: 169),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.1),
                ]
              : [
                  Colors.white.withOpacity(0.75),
                  Colors.white.withOpacity(0.5),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background trophy shape decoration
          Positioned(
            right: 10,
            top: 10,
            child: Opacity(
              opacity: 0.05,
              child: Icon(
                Icons.emoji_events_outlined,
                size: 200,
                color: Colors.amber.shade700,
              ),
            ),
          ),
          
          // Champion ribbon banner - top
          Positioned(
            top: 16,
            child: TugAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 50),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  gradient: goldGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      topUser.isCurrentUser ? '🏆 YOU\'RE #1!' : 'champion',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Main content (user info)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: TugAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 150),
              beginOffset: const Offset(0, 30),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Use minimum space needed
                  children: [
                  // Crown icon above the avatar
                  ShaderMask(
                    shaderCallback: (bounds) => goldGradient.createShader(bounds),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  
                  // User name with overflow handling
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5, // Limit width for long names
                    child: Text(
                      topUser.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Stats row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildChampionStat(
                        Icons.fitness_center,
                        '${topUser.totalActivities}',
                        'Activities',
                        isDarkMode,
                        iconColor: TugColors.primaryPurple,
                      ),
                      Container(
                        height: 20,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: isDarkMode ? Colors.white30 : Colors.black12,
                      ),
                      _buildChampionStat(
                        Icons.calendar_today,
                        '${topUser.uniqueActivityDays}',
                        'Days',
                        isDarkMode,
                      ),
                      if (topUser.streak > 0) ...[
                        Container(
                          height: 20,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: isDarkMode ? Colors.white30 : Colors.black12,
                        ),
                        _buildChampionStat(
                          Icons.local_fire_department,
                          '${topUser.streak}',
                          'Streak',
                          isDarkMode,
                          iconColor: Colors.redAccent.shade400,
                          valueColor: Colors.redAccent.shade400,
                        ),
                      ],
                    ],
                  ),
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChampionStat(
    IconData icon,
    String value,
    String label,
    bool isDarkMode, {
    Color? iconColor,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: iconColor ?? (isDarkMode ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? (isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPodiumPlatform(double height, Color color, bool isDarkMode, {required String label}) {
    return Container(
      width: 80,
      height: height,
      decoration: BoxDecoration(
        color: isDarkMode ? TugColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.7),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPodiumUser(UserRankingModel user, Color color, double platformHeight, bool isDarkMode, {bool isFirst = false}) {
    return Column(
      children: [
        // User avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TugColors.primaryPurple.withOpacity(0.1),
            border: Border.all(
              color: color,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: isFirst
                ? const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 32,
                  )
                : Icon(
                    Icons.person,
                    size: 28,
                    color: TugColors.primaryPurple,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        // User name
        SizedBox(
          width: 80,
          child: Text(
            user.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        
        // Activities count
        Text(
          '${user.totalActivities} activities',
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        
        // Display streak if it exists
        if (user.streak > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department,
                size: 10,
                color: Colors.redAccent.shade400,
              ),
              const SizedBox(width: 2),
              Text(
                '${user.streak} day streak',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent.shade400,
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildUserRankCard(UserRankingModel user, bool isDarkMode, {bool isCurrentUserCard = false}) {
    // Define medal properties based on rank
    Color rankColor;
    LinearGradient? rankGradient;
    String? medalIconPath;
    IconData rankIcon = Icons.emoji_events;
    double elevation = 1;
    
    // Current user card
    if (isCurrentUserCard) {
      rankColor = TugColors.primaryPurple;
      rankGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          TugColors.primaryPurple.withOpacity(0.9),
          TugColors.primaryPurple,
        ],
      );
      elevation = 8;
    } 
    // Top 3 rankings
    else if (user.rank == 1) {
      // Gold for first place
      rankColor = Colors.amber.shade600;
      rankGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.amber.shade300, Colors.amber.shade700],
      );
      rankIcon = Icons.emoji_events;
      elevation = 5;
    } else if (user.rank == 2) {
      // Silver for second place
      rankColor = Colors.grey.shade400;
      rankGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey.shade300, Colors.grey.shade500],
      );
      rankIcon = Icons.emoji_events;
      elevation = 4;
    } else if (user.rank == 3) {
      // Bronze for third place
      rankColor = Colors.brown.shade400;
      rankGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.brown.shade300, Colors.brown.shade500],
      );
      rankIcon = Icons.emoji_events;
      elevation = 3;
    } else {
      // Regular users
      rankColor = isDarkMode ? Colors.white60 : Colors.black54;
      rankIcon = Icons.person;
      elevation = 2;
    }
    
    // Override for current user in list (not at the top)
    if (user.isCurrentUser && !isCurrentUserCard) {
      elevation = 6;
    }
    
    // Card background
    final Color cardColor = isCurrentUserCard
        ? (isDarkMode 
            ? Color.lerp(TugColors.darkBackground, TugColors.primaryPurple, 0.15) ?? TugColors.darkBackground
            : Color.lerp(Colors.white, TugColors.primaryPurple, 0.05) ?? Colors.white)
        : (isDarkMode
            ? Colors.black.withOpacity(0.4)
            : Colors.white.withOpacity(0.9));
    
    // Advanced styles for the card border
    BoxDecoration boxDecoration;
    
    // Special styling for top 3 and current user
    if ((user.rank != null && user.rank! <= 3) || isCurrentUserCard || user.isCurrentUser) {
      boxDecoration = BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: user.isCurrentUser || isCurrentUserCard
                ? TugColors.primaryPurple.withOpacity(isDarkMode ? 0.3 : 0.2)
                : user.rank == 1
                    ? Colors.amber.withOpacity(isDarkMode ? 0.3 : 0.2)
                    : user.rank == 2
                        ? Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.15)
                        : user.rank == 3
                            ? Colors.brown.withOpacity(isDarkMode ? 0.3 : 0.15)
                            : Colors.transparent,
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: user.isCurrentUser || isCurrentUserCard
              ? TugColors.primaryPurple.withOpacity(0.6)
              : user.rank == 1
                  ? Colors.amber.withOpacity(0.6)
                  : user.rank == 2
                      ? Colors.grey.withOpacity(0.6)
                      : user.rank == 3
                          ? Colors.brown.withOpacity(0.6)
                          : Colors.transparent,
          width: 1.5,
        ),
      );
    } else {
      // Regular cards
      boxDecoration = BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
    
    return TugAnimations.fadeSlideIn(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        decoration: boxDecoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              // Rank number/medal
              if (user.rank != null)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Badge background
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: (user.rank != null && user.rank! <= 3) || isCurrentUserCard
                            ? rankGradient
                            : null,
                        color: (user.rank != null && user.rank! <= 3) || isCurrentUserCard
                            ? null
                            : isDarkMode
                                ? Colors.black38
                                : Colors.grey.shade200,
                        boxShadow: (user.rank != null && user.rank! <= 3) || isCurrentUserCard
                            ? [
                                BoxShadow(
                                  color: rankColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: user.rank! <= 3
                          ? Center(
                              child: Icon(
                                rankIcon,
                                color: Colors.white,
                                size: 20,
                              ),
                            )
                          : Center(
                              child: Text(
                                '${user.rank}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                
              const SizedBox(width: 12),
              
              // User name and stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Text(
                              isCurrentUserCard ? 'your ranking' : user.displayName,
                              style: TextStyle(
                                fontSize: isCurrentUserCard ? 16 : 15,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            // Show rank number prominently
                            if (user.rank != null)
                              Text(
                                '#${user.rank} Position',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: TugColors.primaryPurple,
                                ),
                              ),
                            // Add congratulatory messages for top 3
                            if (user.rank != null && user.rank! <= 3 && (user.isCurrentUser || isCurrentUserCard))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _getTopRankMessage(user.rank!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _getTopRankColor(user.rank!),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (user.isCurrentUser && !isCurrentUserCard) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: TugColors.primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: TugColors.primaryPurple.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: TugColors.primaryPurple,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Only show stats for regular leaderboard cards, not for current user card
                    if (!isCurrentUserCard) ...[
                      const SizedBox(height: 6),
                      
                      // Stats display
                      Row(
                        children: [
                          // Activities count
                          _buildRankCardStat(
                            Icons.fitness_center, 
                            '${user.totalActivities}',
                            isDarkMode,
                            iconColor: TugColors.primaryPurple.withOpacity(0.8),
                            textColor: TugColors.primaryPurple.withOpacity(0.8),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Show duration and activity days for all cards
                          _buildRankCardStat(
                            Icons.hourglass_bottom, 
                            '${(user.totalDuration / 60).toStringAsFixed(1)}h',
                            isDarkMode,
                          ),
                          const SizedBox(width: 12),
                          _buildRankCardStat(
                            Icons.calendar_today, 
                            '${user.uniqueActivityDays}d',
                            isDarkMode,
                          ),
                          
                          // Show streak if available
                          if (user.streak > 0) ...[
                            const SizedBox(width: 12),
                            _buildRankCardStat(
                              Icons.local_fire_department,
                              '${user.streak}🔥',
                              isDarkMode,
                              iconColor: Colors.redAccent.shade400,
                              textColor: Colors.redAccent.shade400,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRankCardStat(
    IconData icon, 
    String text, 
    bool isDarkMode, {
    Color? iconColor,
    Color? textColor
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (iconColor ?? TugColors.primaryPurple).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? (isDarkMode ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor ?? (isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatIcon(
    IconData icon, 
    String text, 
    {Color? iconColor, Color? textColor}
  ) {
    final effectiveIconColor = iconColor ?? TugColors.primaryPurple.withOpacity(0.8);
    final effectiveTextColor = textColor ?? TugColors.primaryPurple.withOpacity(0.8);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: effectiveIconColor,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: effectiveTextColor,
          ),
        ),
      ],
    );
  }
  
  // Helper methods for top rank messages
  String _getTopRankMessage(int rank) {
    switch (rank) {
      case 1:
        return '🏆 BIG CHAMP! you\'re the definition of superior!';
      case 2:
        return '🥈 OH?? you\'re a beast #1 better be scared!';
      case 3:
        return '🥉 when did you get so AWESOME? don\'t stop ';
      default:
        return '';
    }
  }
  
  Color _getTopRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade600;
      case 2:
        return Colors.grey.shade500;
      case 3:
        return Colors.brown.shade400;
      default:
        return TugColors.primaryPurple;
    }
  }
}