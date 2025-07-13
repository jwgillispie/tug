import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme/colors.dart';
import '../../utils/quantum_effects.dart';
import '../../services/app_mode_service.dart';
import '../../widgets/notifications/notification_bell.dart';
import '../../services/social_service.dart';
import '../../models/social_models.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../services/user_service.dart';
import 'user_search_screen.dart';
import 'friends_screen.dart';
import 'comments_screen.dart';
import 'social_onboarding_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final AppModeService _appModeService = AppModeService();
  final SocialService _socialService = SocialService();
  final UserService _userService = UserService();
  final ScrollController _scrollController = ScrollController();
  
  AppMode _currentMode = AppMode.valuesMode;
  List<SocialPostModel> _posts = [];
  bool _isLoading = false;
  String? _currentUserId;
  StreamSubscription<AppMode>? _modeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeMode();
    _getCurrentUser();
    _loadSocialFeed();
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

  void _getCurrentUser() async {
    try {
      final userData = await _userService.getCurrentUserProfile();
      _currentUserId = userData.id;
      debugPrint('SocialScreen: Current user ID (backend): $_currentUserId');
    } catch (e) {
      debugPrint('SocialScreen: Failed to get backend user ID: $e');
      // Fallback to Firebase UID
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          _currentUserId = authState.user.uid;
          debugPrint('SocialScreen: Using Firebase UID as fallback: $_currentUserId');
        }
      }
    }
  }

  Future<void> _loadSocialFeed({bool forceRefresh = false}) async {
    if (_isLoading || !mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final allPosts = await _socialService.getSocialFeed(
        limit: 50, 
        skip: 0, 
        forceRefresh: forceRefresh,
      );
      
      // Filter posts based on current mode
      final filteredPosts = allPosts.where((post) {
        if (_currentMode == AppMode.vicesMode) {
          // In vices mode, show only vice progress posts
          return post.postType == PostType.viceProgress;
        } else {
          // In values mode, show activity updates and achievements
          return post.postType == PostType.activityUpdate || 
                 post.postType == PostType.achievement;
        }
      }).toList();
      
      if (mounted) {
        setState(() {
          _posts = filteredPosts;
          _isLoading = false;
        });
        
        // Debug: Log posts and ownership
        for (final post in filteredPosts) {
          debugPrint('SocialScreen: Post ${post.id} by ${post.userId} (${post.displayName}) - isOwned: ${post.userId == _currentUserId}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load social feed: $e'),
            backgroundColor: TugColors.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshSocialFeed() async {
    // Force refresh social feed (SocialService doesn't use caching yet)
    await _loadSocialFeed(forceRefresh: true);
  }





  @override
  void dispose() {
    _modeSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;

    return Scaffold(
      backgroundColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isViceMode
                  ? (isDarkMode 
                      ? [TugColors.darkBackground, TugColors.viceGreenDark, TugColors.viceGreen]
                      : [TugColors.lightBackground, TugColors.viceGreen.withAlpha(20)])
                  : (isDarkMode 
                      ? [TugColors.darkBackground, TugColors.primaryPurpleDark, TugColors.primaryPurple]
                      : [TugColors.lightBackground, TugColors.primaryPurple.withAlpha(20)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: QuantumEffects.holographicShimmer(
          child: QuantumEffects.gradientText(
            'home',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            colors: isViceMode
                ? (isDarkMode ? [TugColors.viceGreen, TugColors.viceGreenLight, TugColors.viceGreenDark] : [TugColors.viceGreen, TugColors.viceGreenLight])
                : (isDarkMode ? [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark] : [TugColors.primaryPurple, TugColors.primaryPurpleLight]),
          ),
        ),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: Icon(
              Icons.people,
              color: isViceMode
                  ? (isDarkMode ? TugColors.viceGreenLight : TugColors.viceGreen)
                  : (isDarkMode ? TugColors.primaryPurpleLight : TugColors.primaryPurple),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.person_add,
              color: isViceMode
                  ? (isDarkMode ? TugColors.viceGreenLight : TugColors.viceGreen)
                  : (isDarkMode ? TugColors.primaryPurpleLight : TugColors.primaryPurple),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserSearchScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSocialFeed,
        color: TugColors.getPrimaryColor(isViceMode),
        child: ListView(
          controller: _scrollController,
          children: [
            _buildModeInfoSection(isDarkMode, isViceMode),
            _buildFeedContent(isDarkMode, isViceMode),
          ],
        ),
      ),
    );
  }


  Widget _buildModeInfoSection(bool isDarkMode, bool isViceMode) {
    return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isViceMode ? Icons.psychology : Icons.timeline,
                  color: TugColors.getPrimaryColor(isViceMode),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isViceMode ? 'vice progress feed' : 'activity feed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: TugColors.getTextColor(isDarkMode, isViceMode),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isViceMode 
                  ? 'see your friends\' progress overcoming vices. posts are automatically created when they hit milestones like 7, 30, or 100 days clean!'
                  : 'your friends\' activities automatically appear here when they log workouts, complete goals, or hit achievements. just like strava!',
              style: TextStyle(
                fontSize: 14,
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: TugColors.getPrimaryColor(isViceMode),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'all posts are automatically generated from activities',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: TugColors.getPrimaryColor(isViceMode),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildFeedContent(bool isDarkMode, bool isViceMode) {
    if (_isLoading && _posts.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            color: TugColors.getPrimaryColor(isViceMode),
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              ),
              const SizedBox(height: 16),
              Text(
                'nobody\'s dropped anything yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: TugColors.getTextColor(isDarkMode, isViceMode),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'be the first to share what\'s working for you!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SocialOnboardingScreen()),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('see how it works'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TugColors.getPrimaryColor(isViceMode),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
      );
    }

    return Column(
      children: _posts.map((post) => _buildFeedItem(post, isDarkMode, isViceMode)).toList(),
    );
  }

  Widget _buildFeedItem(SocialPostModel post, bool isDarkMode, bool isViceMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
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
                  post.displayName[0].toUpperCase(),
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
                    GestureDetector(
                      onTap: () {
                        if (post.userId != _currentUserId) {
                          context.push('/user/${post.userId}');
                        }
                      },
                      child: Text(
                        post.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: post.userId != _currentUserId 
                              ? TugColors.getPrimaryColor(isViceMode)
                              : TugColors.getTextColor(isDarkMode, isViceMode),
                          decoration: post.userId != _currentUserId 
                              ? TextDecoration.underline 
                              : null,
                        ),
                      ),
                    ),
                    Text(
                      post.timeAgoText,
                      style: TextStyle(
                        fontSize: 12,
                        color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                      ),
                    ),
                  ],
                ),
              ),
              // Post type indicator
              if (post.postType != PostType.general)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPostTypeLabel(post.postType),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: TugColors.getPrimaryColor(isViceMode),
                    ),
                  ),
                ),
              // Edit/Delete menu for user's own posts
              if (post.userId == _currentUserId) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: TugColors.getPrimaryColor(isViceMode),
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'hide') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Post hidden from your feed'),
                          backgroundColor: TugColors.getPrimaryColor(isViceMode),
                          action: SnackBarAction(
                            label: 'Undo',
                            textColor: Colors.white,
                            onPressed: () {
                              // Could implement unhide functionality
                            },
                          ),
                        ),
                      );
                      // Remove post from local list (hide it)
                      setState(() {
                        _posts.removeWhere((p) => p.id == post.id);
                      });
                    } else if (value == 'info') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('This post was automatically created from your activity. To modify it, edit the original activity or achievement.'),
                          backgroundColor: TugColors.getPrimaryColor(isViceMode),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'hide',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_off, size: 18, color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true)),
                          const SizedBox(width: 12),
                          const Text('Hide post'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: TugColors.getPrimaryColor(isViceMode)),
                          const SizedBox(width: 12),
                          const Text('About this post'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          
          // Post content
          Text(
            post.content,
            style: TextStyle(
              fontSize: 14,
              color: TugColors.getTextColor(isDarkMode, isViceMode),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          
          // Value badge with color and time
          if (post.hasValueInfo) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (post.valueColorObject ?? TugColors.getPrimaryColor(isViceMode)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: post.valueColorObject ?? TugColors.getPrimaryColor(isViceMode),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: post.valueColorObject ?? TugColors.getPrimaryColor(isViceMode),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    post.valueName!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: post.valueColorObject ?? TugColors.getPrimaryColor(isViceMode),
                    ),
                  ),
                  if (post.formattedDuration.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      post.formattedDuration,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: post.valueColorObject ?? TugColors.getPrimaryColor(isViceMode),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (post.activityNotes != null && post.activityNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.activityNotes!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          
          // Actions row
          Row(
            children: [
              _buildActionButton(
                icon: Icons.record_voice_over,
                count: post.commentsCount,
                label: 'two cents',
                isDarkMode: isDarkMode,
                isViceMode: isViceMode,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentsScreen(
                        post: post,
                        onPostUpdated: (updatedPost) {
                          setState(() {
                            final index = _posts.indexWhere((p) => p.id == updatedPost.id);
                            if (index != -1) {
                              _posts[index] = updatedPost;
                            }
                          });
                        },
                      ),
                    ),
                  );
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
    Color? iconColor,
    required int count,
    String? label,
    bool hideCount = false,
    required bool isDarkMode,
    required bool isViceMode,
    required VoidCallback? onTap,
    int? userCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor ?? TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              ),
              if (!hideCount && count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                  ),
                ),
              ],
              if (userCount != null && userCount > 0) ...[
                const SizedBox(width: 2),
                Text(
                  '($userCount)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getPostTypeLabel(PostType postType) {
    switch (postType) {
      case PostType.activityUpdate:
        return 'activity';
      case PostType.viceProgress:
        return 'progress';
      case PostType.achievement:
        return 'achievement';
      case PostType.general:
        return 'general';
    }
  }

}