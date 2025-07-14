import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    } catch (e) {
      // Fallback to Firebase UID
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          _currentUserId = authState.user.uid;
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
          // In vices mode, show only vice indulgence posts
          return post.postType == PostType.viceIndulgence;
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
    // Force refresh social feed - clear current posts and reload
    if (!mounted) return;
    
    setState(() {
      _posts.clear();
    });
    
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
          physics: const AlwaysScrollableScrollPhysics(),
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
                    isViceMode ? 'indulgence feed' : 'activity feed',
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
                  ? 'see when your friends are being honest about their struggles. posts are automatically created when they log indulgences.'
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
      children: [
        ..._posts.map((post) => _buildFeedItem(post, isDarkMode, isViceMode)),
        const SizedBox(height: 100), // Space at bottom for navigation bar
      ],
    );
  }

  Widget _buildFeedItem(SocialPostModel post, bool isDarkMode, bool isViceMode) {
    final primaryColor = TugColors.getPrimaryColor(isViceMode);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        primaryColor.withValues(alpha: 0.08),
                        TugColors.getSurfaceColor(isDarkMode, isViceMode).withValues(alpha: 0.95),
                        primaryColor.withValues(alpha: 0.05),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.9),
                        TugColors.getSurfaceColor(isDarkMode, isViceMode).withValues(alpha: 0.85),
                        primaryColor.withValues(alpha: 0.03),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                width: 1.5,
                color: primaryColor.withValues(alpha: isDarkMode ? 0.3 : 0.2),
              ),
              boxShadow: [
                // Primary glow shadow
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                // Depth shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
                // Subtle ambient light
                if (isDarkMode)
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -1),
                    spreadRadius: -4,
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                splashColor: primaryColor.withValues(alpha: 0.1),
                highlightColor: primaryColor.withValues(alpha: 0.05),
                onTap: () {
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
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
                          // Post type indicator - show value name for activity posts
                          if (post.postType == PostType.activityUpdate && post.hasValueInfo)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (post.valueColorObject ?? TugColors.getPrimaryColor(isViceMode)).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                post.valueName!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: post.valueColorObject ?? TugColors.getPrimaryColor(isViceMode),
                                ),
                              ),
                            )
                          else if (post.postType != PostType.general && post.postType != PostType.activityUpdate)
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
                                if (value == 'edit') {
                                  _showEditPostDialog(post, isDarkMode, isViceMode);
                                } else if (value == 'delete') {
                                  _showDeletePostDialog(post, isDarkMode, isViceMode);
                                } else if (value == 'hide') {
                                  _hidePost(post, isViceMode);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18, color: TugColors.getPrimaryColor(isViceMode)),
                                      const SizedBox(width: 12),
                                      const Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete, size: 18, color: Colors.red),
                                      const SizedBox(width: 12),
                                      const Text('Delete'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'hide',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility_off, size: 18, color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true)),
                                      const SizedBox(width: 12),
                                      const Text('Hide'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
          
          // 1. Value section
          if (post.hasValueInfo) ...[
            Text(
              'Value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  post.valueName!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: post.valueColorObject ?? TugColors.getPrimaryColor(isViceMode),
                    height: 1.3,
                  ),
                ),
                if (post.formattedDuration.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: TugColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${post.formattedDuration}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TugColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // 2. Activity section
          if (post.activityName != null && post.activityName!.isNotEmpty) ...[
            Text(
              'Activity',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.activityName!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: TugColors.getTextColor(isDarkMode, isViceMode),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // 3. Notes section
          if (post.content.isNotEmpty) ...[
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            // Notes content
            Text(
              post.content,
              style: TextStyle(
                fontSize: 15,
                color: TugColors.getTextColor(isDarkMode, isViceMode),
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 12),
          
          // Actions row
          Center(
            child: _buildActionButton(
                icon: Icons.record_voice_over,
                count: post.commentsCount,
                label: 'comments',
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
            ),
        ],
      ),
                ),
              ),
            ),
          ),
        ),
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
      case PostType.viceIndulgence:
        return 'indulgence';
      case PostType.achievement:
        return 'achievement';
      case PostType.general:
        return 'general';
    }
  }

  void _hidePost(SocialPostModel post, bool isViceMode) {
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Post hidden from your feed'),
        backgroundColor: TugColors.getPrimaryColor(isViceMode),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // Restore the post to the feed
            _loadSocialFeed();
          },
        ),
      ),
    );
    
    // Remove post from local list (hide it)
    setState(() {
      _posts.removeWhere((p) => p.id == post.id);
    });
  }

  void _showEditPostDialog(SocialPostModel post, bool isDarkMode, bool isViceMode) {
    final TextEditingController controller = TextEditingController(text: post.content);
    final messenger = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? TugColors.darkSurface : Colors.white,
        title: Text(
          'Edit Post',
          style: TextStyle(
            color: TugColors.getTextColor(isDarkMode, isViceMode),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'What\'s on your mind?',
            hintStyle: TextStyle(
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: TugColors.getPrimaryColor(isViceMode),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: TugColors.getPrimaryColor(isViceMode),
                width: 2,
              ),
            ),
          ),
          style: TextStyle(
            color: TugColors.getTextColor(isDarkMode, isViceMode),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Post content cannot be empty')),
                );
                return;
              }
              
              try {
                Navigator.pop(dialogContext);
                
                // Show loading
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Updating post...'),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                
                final updatedPost = await _socialService.updatePost(post.id, controller.text.trim());
                
                if (!mounted) return;
                
                // Update the post in the list
                setState(() {
                  final index = _posts.indexWhere((p) => p.id == post.id);
                  if (index != -1) {
                    _posts[index] = updatedPost;
                  }
                });
                
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Post updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to update post: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TugColors.getPrimaryColor(isViceMode),
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeletePostDialog(SocialPostModel post, bool isDarkMode, bool isViceMode) {
    final messenger = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? TugColors.darkSurface : Colors.white,
        title: Text(
          'Delete Post',
          style: TextStyle(
            color: TugColors.getTextColor(isDarkMode, isViceMode),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(
            color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(dialogContext);
                
                // Show loading
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Deleting post...'),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                
                await _socialService.deletePost(post.id);
                
                if (!mounted) return;
                
                // Remove the post from the list
                setState(() {
                  _posts.removeWhere((p) => p.id == post.id);
                });
                
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Post deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete post: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

}