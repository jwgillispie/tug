import 'package:flutter/material.dart';
import '../../utils/theme/colors.dart';
import '../../services/app_mode_service.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final AppModeService _appModeService = AppModeService();
  AppMode _currentMode = AppMode.valuesMode;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeMode();
  }

  void _initializeMode() async {
    await _appModeService.initialize();
    _appModeService.modeStream.listen((mode) {
      if (mounted) {
        setState(() {
          _currentMode = mode;
        });
      }
    });
    setState(() {
      _currentMode = _appModeService.currentMode;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;

    return Scaffold(
      backgroundColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(isDarkMode, isViceMode),
          _buildFeedContent(isDarkMode, isViceMode),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDarkMode, bool isViceMode) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: TugColors.getPrimaryGradient(),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Social Feed',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'See what your friends are up to',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          'Social',
          style: TextStyle(
            color: TugColors.getTextColor(isDarkMode, isViceMode),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.search,
            color: TugColors.getTextColor(isDarkMode, isViceMode),
          ),
          onPressed: () {
            // TODO: Implement friend search
          },
        ),
        IconButton(
          icon: Icon(
            Icons.person_add,
            color: TugColors.getTextColor(isDarkMode, isViceMode),
          ),
          onPressed: () {
            // TODO: Implement add friends
          },
        ),
      ],
    );
  }

  Widget _buildFeedContent(bool isDarkMode, bool isViceMode) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return _buildComingSoonCard(isDarkMode, isViceMode);
          }
          
          // Mock feed items for now
          return _buildFeedItem(
            isDarkMode: isDarkMode,
            isViceMode: isViceMode,
            username: _getMockUsername(index),
            activity: _getMockActivity(index, isViceMode),
            timeAgo: _getMockTimeAgo(index),
            likes: _getMockLikes(index),
            comments: _getMockComments(index),
          );
        },
        childCount: 6, // 1 coming soon card + 5 mock items
      ),
    );
  }

  Widget _buildComingSoonCard(bool isDarkMode, bool isViceMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TugColors.getPrimaryColor(isViceMode).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.construction,
            size: 48,
            color: TugColors.getPrimaryColor(isViceMode),
          ),
          const SizedBox(height: 16),
          Text(
            'Social Features Coming Soon!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: TugColors.getTextColor(isDarkMode, isViceMode),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with friends, share your progress, and motivate each other on your journey.',
            style: TextStyle(
              fontSize: 14,
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeaturePreview(
                icon: Icons.favorite,
                label: 'Kudos',
                isDarkMode: isDarkMode,
                isViceMode: isViceMode,
              ),
              _buildFeaturePreview(
                icon: Icons.comment,
                label: 'Comments',
                isDarkMode: isDarkMode,
                isViceMode: isViceMode,
              ),
              _buildFeaturePreview(
                icon: Icons.leaderboard,
                label: 'Challenges',
                isDarkMode: isDarkMode,
                isViceMode: isViceMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePreview({
    required IconData icon,
    required String label,
    required bool isDarkMode,
    required bool isViceMode,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TugColors.getPrimaryColor(isViceMode).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: TugColors.getPrimaryColor(isViceMode),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedItem({
    required bool isDarkMode,
    required bool isViceMode,
    required String username,
    required String activity,
    required String timeAgo,
    required int likes,
    required int comments,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: TugColors.getPrimaryColor(isViceMode),
                child: Text(
                  username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: TugColors.getTextColor(isDarkMode, isViceMode),
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Activity content
          Text(
            activity,
            style: TextStyle(
              fontSize: 14,
              color: TugColors.getTextColor(isDarkMode, isViceMode),
            ),
          ),
          const SizedBox(height: 12),
          
          // Actions row
          Row(
            children: [
              _buildActionButton(
                icon: Icons.favorite_border,
                count: likes,
                isDarkMode: isDarkMode,
                isViceMode: isViceMode,
                onTap: () {
                  // TODO: Implement like functionality
                },
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.comment_outlined,
                count: comments,
                isDarkMode: isDarkMode,
                isViceMode: isViceMode,
                onTap: () {
                  // TODO: Implement comment functionality
                },
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                ),
                onPressed: () {
                  // TODO: Implement share functionality
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required bool isDarkMode,
    required bool isViceMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            ),
          ),
        ],
      ),
    );
  }

  // Mock data generators
  String _getMockUsername(int index) {
    final names = ['alex_runner', 'sarah_fit', 'mike_strong', 'emma_zen', 'david_goals'];
    return names[index % names.length];
  }

  String _getMockActivity(int index, bool isViceMode) {
    if (isViceMode) {
      final activities = [
        'Successfully avoided social media for 3 hours! 💪',
        'Resisted the urge to order takeout and cooked at home instead 🍳',
        'Had a productive work session without checking my phone 📱',
        'Chose water over soda today - small wins count! 💧',
        'Meditated for 10 minutes instead of scrolling endlessly 🧘‍♀️',
      ];
      return activities[index % activities.length];
    } else {
      final activities = [
        'Completed a 30-minute morning jog! Feeling energized 🏃‍♂️',
        'Read for 45 minutes today - halfway through my monthly goal 📚',
        'Practiced guitar for an hour. Getting better at that difficult song! 🎸',
        'Had a great meditation session. Finding more peace each day 🧘‍♀️',
        'Cooked a healthy meal from scratch. Nourishing my body well 🥗',
      ];
      return activities[index % activities.length];
    }
  }

  String _getMockTimeAgo(int index) {
    final times = ['2h ago', '4h ago', '1d ago', '2d ago', '3d ago'];
    return times[index % times.length];
  }

  int _getMockLikes(int index) {
    return [12, 8, 15, 6, 20][index % 5];
  }

  int _getMockComments(int index) {
    return [3, 1, 5, 2, 7][index % 5];
  }
}