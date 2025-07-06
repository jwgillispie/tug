import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme/colors.dart';
import '../../utils/quantum_effects.dart';
import '../../services/app_mode_service.dart';
import '../../services/social_service.dart';
import '../../models/social_models.dart';
import '../../blocs/auth/auth_bloc.dart';
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

  void _getCurrentUser() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.uid;
    }
  }

  Future<void> _loadSocialFeed({bool forceRefresh = false}) async {
    if (_isLoading) return;
    
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
      
      setState(() {
        _posts = filteredPosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
    await _loadSocialFeed(forceRefresh: true);
  }


  Future<void> _toggleLike(SocialPostModel post) async {
    // Prevent multiple rapid taps
    if (_currentUserId == null) return;
    
    // Optimistic UI update
    setState(() {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        final updatedLikes = List<String>.from(_posts[index].likes);
        final isCurrentlyLiked = updatedLikes.contains(_currentUserId!);
        
        if (isCurrentlyLiked) {
          updatedLikes.remove(_currentUserId!);
        } else {
          updatedLikes.add(_currentUserId!);
        }
        
        _posts[index] = SocialPostModel(
          id: _posts[index].id,
          userId: _posts[index].userId,
          content: _posts[index].content,
          postType: _posts[index].postType,
          activityId: _posts[index].activityId,
          viceId: _posts[index].viceId,
          achievementId: _posts[index].achievementId,
          likes: updatedLikes,
          commentsCount: _posts[index].commentsCount,
          isPublic: _posts[index].isPublic,
          createdAt: _posts[index].createdAt,
          updatedAt: _posts[index].updatedAt,
          username: _posts[index].username,
          userDisplayName: _posts[index].userDisplayName,
        );
      }
    });
    
    try {
      final result = await _socialService.likePost(post.id);
      
      // Sync with server response
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          final updatedLikes = List<String>.from(_posts[index].likes);
          
          // Ensure state matches server response
          if (result['liked']) {
            if (!updatedLikes.contains(_currentUserId!)) {
              updatedLikes.add(_currentUserId!);
            }
          } else {
            updatedLikes.remove(_currentUserId!);
          }
          
          _posts[index] = SocialPostModel(
            id: _posts[index].id,
            userId: _posts[index].userId,
            content: _posts[index].content,
            postType: _posts[index].postType,
            activityId: _posts[index].activityId,
            viceId: _posts[index].viceId,
            achievementId: _posts[index].achievementId,
            likes: updatedLikes,
            commentsCount: _posts[index].commentsCount,
            isPublic: _posts[index].isPublic,
            createdAt: _posts[index].createdAt,
            updatedAt: _posts[index].updatedAt,
            username: _posts[index].username,
            userDisplayName: _posts[index].userDisplayName,
          );
        }
      });
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          final updatedLikes = List<String>.from(_posts[index].likes);
          final isCurrentlyLiked = updatedLikes.contains(_currentUserId!);
          
          // Revert the optimistic change
          if (isCurrentlyLiked) {
            updatedLikes.remove(_currentUserId!);
          } else {
            updatedLikes.add(_currentUserId!);
          }
          
          _posts[index] = SocialPostModel(
            id: _posts[index].id,
            userId: _posts[index].userId,
            content: _posts[index].content,
            postType: _posts[index].postType,
            activityId: _posts[index].activityId,
            viceId: _posts[index].viceId,
            achievementId: _posts[index].achievementId,
            likes: updatedLikes,
            commentsCount: _posts[index].commentsCount,
            isPublic: _posts[index].isPublic,
            createdAt: _posts[index].createdAt,
            updatedAt: _posts[index].updatedAt,
            username: _posts[index].username,
            userDisplayName: _posts[index].userDisplayName,
          );
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn\'t give props: $e'),
            backgroundColor: TugColors.error,
          ),
        );
      }
    }
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
    final isLiked = _currentUserId != null && post.isLikedBy(_currentUserId!);
    
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
          const SizedBox(height: 12),
          
          // Actions row
          Row(
            children: [
              _buildActionButton(
                icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                iconColor: isLiked ? Colors.green : null,
                count: post.likes.length,
                label: 'props',
                isDarkMode: isDarkMode,
                isViceMode: isViceMode,
                onTap: () => _toggleLike(post),
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.comment_bank_outlined,
                count: post.commentsCount,
                label: '2 cents',
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
              const Spacer(),
              _buildActionButton(
                icon: Icons.campaign_outlined,
                count: 0,
                label: 'amplify',
                hideCount: true,
                isDarkMode: isDarkMode,
                isViceMode: isViceMode,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Amplify feature launching soon! 📢')),
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
    required VoidCallback onTap,
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