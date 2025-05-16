// lib/screens/rankings/rankings_screen.dart
import 'package:flutter/material.dart';
import 'package:tug/models/ranking_model.dart';
import 'package:tug/services/rankings_service.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/animations.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> with SingleTickerProviderStateMixin {
  final RankingsService _rankingsService = RankingsService();
  
  bool _isLoading = true;
  String? _errorMessage;
  RankingsListModel? _activityRankings;
  RankingsListModel? _streakRankings;
  int _selectedPeriod = 30; // Default to 30 days
  
  late TabController _tabController;
  final List<int> _periodOptions = [7, 30, 90, 365]; // Days options
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadRankings();
      }
    });
    _loadRankings();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRankings() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final currentTab = _tabController.index;
      final rankBy = currentTab == 0 ? 'activities' : 'streak';
      
      final rankings = await _rankingsService.getTopUsers(
        days: _selectedPeriod,
        limit: 50, // Get up to 50 users
        rankBy: rankBy,
      );
      
      if (mounted) {
        setState(() {
          if (currentTab == 0) {
            _activityRankings = rankings;
          } else {
            _streakRankings = rankings;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load rankings: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  void _changePeriod(int days) {
    if (_selectedPeriod != days) {
      setState(() {
        _selectedPeriod = days;
      });
      _loadRankings();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRankings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.local_fire_department),
              text: 'Activities',
            ),
            Tab(
              icon: Icon(Icons.timeline),
              text: 'Streaks',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
                ? [
                    TugColors.darkBackground,
                    Color.lerp(TugColors.darkBackground, TugColors.primaryPurple, 0.05) ?? TugColors.darkBackground,
                  ] 
                : [
                    TugColors.lightBackground,
                    Color.lerp(TugColors.lightBackground, TugColors.primaryPurple, 0.03) ?? TugColors.lightBackground,
                  ],
          ),
        ),
        child: Column(
          children: [
            // Time period selector
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time Period',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? TugColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SegmentedButton<int>(
                      segments: _periodOptions.map((days) {
                        return ButtonSegment<int>(
                          value: days,
                          label: Text(days == 365 ? '1 Year' : '$days Days'),
                        );
                      }).toList(),
                      selected: {_selectedPeriod},
                      onSelectionChanged: (Set<int> selection) {
                        if (selection.isNotEmpty) {
                          _changePeriod(selection.first);
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return TugColors.primaryPurple;
                            }
                            return null;
                          },
                        ),
                        foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.white;
                            }
                            return TugColors.primaryPurple;
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Rankings content in tab view
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Activities tab
                  _buildRankingsContent(isDarkMode, isActivitiesTab: true),
                  
                  // Streaks tab
                  _buildRankingsContent(isDarkMode, isActivitiesTab: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRankingsContent(bool isDarkMode, {bool isActivitiesTab = true}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: TugColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadRankings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Determine which rankings to use based on the tab
    final rankings = isActivitiesTab ? _activityRankings : _streakRankings;
    
    if (rankings == null || rankings.rankings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActivitiesTab ? Icons.local_fire_department_outlined : Icons.timeline_outlined,
                size: 64,
                color: TugColors.primaryPurple.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No rankings available yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isActivitiesTab
                    ? 'Be the first to log some activities and get on the leaderboard!'
                    : 'Build your streak by logging activities daily to appear here!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Filter users appropriately based on tab
    final List<UserRankingModel> activeUsers = isActivitiesTab
        ? rankings.rankings.where((user) => user.totalActivities > 0).toList()
        : rankings.rankings.where((user) => user.streak > 0).toList();
    
    return Column(
      children: [
        // Current user ranking card (if available)
        if (rankings.currentUserRank != null)
          Builder(
            builder: (context) {
              // Find the current user in the rankings
              final currentUser = rankings.rankings
                  .firstWhere((user) => user.isCurrentUser, 
                    orElse: () => UserRankingModel(
                      rank: rankings.currentUserRank,
                      userId: '',
                      displayName: 'Your Ranking',
                      totalActivities: 0,
                      totalDuration: 0,
                      uniqueActivityDays: 0,
                      avgDurationPerActivity: 0,
                      streak: 0,
                      rankingType: isActivitiesTab ? 'activities' : 'streak',
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
                    isActivitiesTab: isActivitiesTab,
                  ),
                ),
              );
            }
          ),
          
        // Top user winner podium
        if (activeUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildWinnerPodium(activeUsers, isDarkMode, isActivitiesTab: isActivitiesTab),
          ),
          
        // Full ranking list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: activeUsers.length,
            itemBuilder: (context, index) {
              final user = activeUsers[index];
              return TugAnimations.staggeredListItem(
                index: index,
                type: StaggeredAnimationType.fadeSlideUp,
                child: _buildUserRankCard(user, isDarkMode, isActivitiesTab: isActivitiesTab),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildWinnerPodium(List<UserRankingModel> users, bool isDarkMode, {bool isActivitiesTab = true}) {
    // Only show the #1 user
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final topUser = users[0];
    
    // Color for medal
    final Color goldColor = Colors.amber.shade600;
    
    return SizedBox(
      height: 180, // Fixed height for the podium section
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Podium platform
          TugAnimations.fadeSlideIn(
            child: _buildPodiumPlatform(
              130.0, // Height for winner platform
              goldColor, 
              isDarkMode,
              label: '1',
            ),
          ),
          
          // Winner avatar and name
          Positioned(
            bottom: 40, // Bottom padding for name
            child: TugAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 100),
              beginOffset: const Offset(0, 40),
              child: Column(
                children: [
                  // Crown icon above the avatar
                  const Icon(
                    Icons.workspace_premium,
                    color: Colors.amber,
                    size: 32,
                  ),
                  const SizedBox(height: 6),
                  
                  // User avatar
                  _buildPodiumUser(
                    topUser,
                    goldColor,
                    130.0,
                    isDarkMode,
                    isFirst: true,
                    isActivitiesTab: isActivitiesTab,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
  
  Widget _buildPodiumUser(UserRankingModel user, Color color, double platformHeight, bool isDarkMode, {bool isFirst = false, bool isActivitiesTab = true}) {
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
                : Text(
                    user.displayName.characters.first.toUpperCase(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: TugColors.primaryPurple,
                    ),
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
        
        // Primary statistic based on tab
        if (isActivitiesTab)
          Text(
            '${user.totalActivities} activities',
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          )
        else
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
        
        // Secondary statistic based on tab
        if (isActivitiesTab && user.streak > 0)
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
          )
        else if (!isActivitiesTab && user.totalActivities > 0)
          Text(
            '${user.totalActivities} activities',
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
      ],
    );
  }
  
  Widget _buildUserRankCard(UserRankingModel user, bool isDarkMode, {bool isCurrentUserCard = false, bool isActivitiesTab = true}) {
    // Background color based on rank
    Color cardColor;
    Color rankTextColor;
    
    if (isCurrentUserCard) {
      // Current user special card
      cardColor = TugColors.primaryPurple.withOpacity(isDarkMode ? 0.2 : 0.1);
      rankTextColor = TugColors.primaryPurple;
    } else if (user.rank == 1) {
      // Gold for first place
      cardColor = Colors.amber.withOpacity(isDarkMode ? 0.2 : 0.1);
      rankTextColor = Colors.amber.shade700;
    } else if (user.rank == 2) {
      // Silver for second place
      cardColor = Colors.grey.shade300.withOpacity(isDarkMode ? 0.2 : 0.15);
      rankTextColor = Colors.grey.shade600;
    } else if (user.rank == 3) {
      // Bronze for third place
      cardColor = Colors.brown.shade300.withOpacity(isDarkMode ? 0.2 : 0.1);
      rankTextColor = Colors.brown.shade400;
    } else {
      // Regular cards
      cardColor = isDarkMode ? TugColors.darkSurface : Colors.white;
      rankTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    }
    
    if (user.isCurrentUser && !isCurrentUserCard) {
      // Highlight current user in the list
      cardColor = TugColors.primaryPurple.withOpacity(isDarkMode ? 0.15 : 0.05);
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      elevation: user.isCurrentUser || user.rank != null && user.rank! <= 3 ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: user.isCurrentUser && !isCurrentUserCard
            ? BorderSide(
                color: TugColors.primaryPurple.withOpacity(0.5),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank number
            if (user.rank != null)
              SizedBox(
                width: 40,
                child: Text(
                  '#${user.rank}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rankTextColor,
                  ),
                ),
              ),
              
            // User avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TugColors.primaryPurple.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  user.displayName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TugColors.primaryPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // User name and stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrentUserCard ? 'Your Ranking' : user.displayName,
                    style: TextStyle(
                      fontSize: isCurrentUserCard ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Stats display
                  Row(
                    children: [
                      // Primary stat based on tab
                      if (isActivitiesTab)
                        _buildStatIcon(
                          Icons.local_fire_department, 
                          '${user.totalActivities}',
                          iconColor: TugColors.primaryPurple.withOpacity(0.8),
                          textColor: TugColors.primaryPurple.withOpacity(0.8),
                        )
                      else
                        _buildStatIcon(
                          Icons.local_fire_department,
                          '${user.streak} streak',
                          iconColor: Colors.redAccent.shade400,
                          textColor: Colors.redAccent.shade400,
                        ),
                        
                      const SizedBox(width: 12),
                      
                      // If it's the current user card, just show the primary and secondary stats
                      if (isCurrentUserCard) ...[
                        if (isActivitiesTab && user.streak > 0)
                          _buildStatIcon(
                            Icons.local_fire_department,
                            '${user.streak} streak',
                            iconColor: Colors.redAccent.shade400,
                            textColor: Colors.redAccent.shade400,
                          )
                        else if (!isActivitiesTab && user.totalActivities > 0)
                          _buildStatIcon(
                            Icons.local_fire_department, 
                            '${user.totalActivities}',
                          ),
                      ] else ...[
                        // Full stats for regular cards
                        // Secondary stats
                        if (isActivitiesTab) ...[
                          _buildStatIcon(
                            Icons.hourglass_bottom, 
                            '${(user.totalDuration / 60).toStringAsFixed(1)}h'
                          ),
                          const SizedBox(width: 12),
                          _buildStatIcon(
                            Icons.calendar_today, 
                            '${user.uniqueActivityDays} days'
                          ),
                          
                          // Show streak if available and in activities tab
                          if (user.streak > 0) ...[
                            const SizedBox(width: 12),
                            _buildStatIcon(
                              Icons.local_fire_department,
                              '${user.streak} streak',
                              iconColor: Colors.redAccent.shade400,
                              textColor: Colors.redAccent.shade400,
                            ),
                          ],
                        ] else ...[
                          // Show activity count if in streak tab
                          _buildStatIcon(
                            Icons.local_fire_department, 
                            '${user.totalActivities}'
                          ),
                          const SizedBox(width: 12),
                          _buildStatIcon(
                            Icons.calendar_today, 
                            '${user.uniqueActivityDays} days'
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Highlight icon for current user
            if (user.isCurrentUser && !isCurrentUserCard)
              const Icon(
                Icons.person,
                color: TugColors.primaryPurple,
                size: 20,
              ),
          ],
        ),
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
}