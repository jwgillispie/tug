import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme/colors.dart';
import '../../services/app_mode_service.dart';
import '../../services/social_service.dart';
import '../../models/social_models.dart';
import '../../blocs/auth/auth_bloc.dart';

class CommentsScreen extends StatefulWidget {
  final SocialPostModel post;
  final Function(SocialPostModel)? onPostUpdated;
  final bool autoFocusInput;
  
  const CommentsScreen({
    super.key,
    required this.post,
    this.onPostUpdated,
    this.autoFocusInput = false,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final AppModeService _appModeService = AppModeService();
  final SocialService _socialService = SocialService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  AppMode _currentMode = AppMode.valuesMode;
  List<CommentModel> _comments = [];
  bool _isLoading = false;
  bool _isPostingComment = false;
  String? _currentUserId;
  StreamSubscription<AppMode>? _modeSubscription;
  late SocialPostModel _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _initializeMode();
    _getCurrentUser();
    _loadComments();
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

  Future<void> _loadComments() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await _socialService.getPostComments(widget.post.id);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load comments: $e'),
            backgroundColor: TugColors.error,
          ),
        );
      }
    }
  }


  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isPostingComment = true;
    });

    try {
      final comment = await _socialService.addComment(widget.post.id, content);
      
      // Update local state
      setState(() {
        _comments.add(comment);
        _commentController.clear();
        _isPostingComment = false;
        
        // Update post comment count
        _currentPost = SocialPostModel(
          id: _currentPost.id,
          userId: _currentPost.userId,
          content: _currentPost.content,
          postType: _currentPost.postType,
          activityId: _currentPost.activityId,
          viceId: _currentPost.viceId,
          achievementId: _currentPost.achievementId,
          commentsCount: _currentPost.commentsCount + 1,
          isPublic: _currentPost.isPublic,
          createdAt: _currentPost.createdAt,
          updatedAt: _currentPost.updatedAt,
          username: _currentPost.username,
          userDisplayName: _currentPost.userDisplayName,
          valueName: _currentPost.valueName,
          valueColor: _currentPost.valueColor,
          activityName: _currentPost.activityName,
          activityDuration: _currentPost.activityDuration,
          activityNotes: _currentPost.activityNotes,
        );
      });
      
      // Notify parent if callback provided
      widget.onPostUpdated?.call(_currentPost);
      
      // Scroll to bottom to show new comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
    } catch (e) {
      setState(() {
        _isPostingComment = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: $e'),
            backgroundColor: TugColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _modeSubscription?.cancel();
    _commentController.dispose();
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
        title: const Text('comments'),
        backgroundColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Original post
          Container(
            margin: const EdgeInsets.all(16),
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
                      radius: 16,
                      backgroundColor: TugColors.getPrimaryColor(isViceMode),
                      child: Text(
                        _currentPost.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_currentPost.userId != _currentUserId) {
                                context.push('/user/${_currentPost.userId}');
                              }
                            },
                            child: Text(
                              _currentPost.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _currentPost.userId != _currentUserId 
                                    ? TugColors.getPrimaryColor(isViceMode)
                                    : TugColors.getTextColor(isDarkMode, isViceMode),
                                decoration: _currentPost.userId != _currentUserId 
                                    ? TextDecoration.underline 
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            _currentPost.timeAgoText,
                            style: TextStyle(
                              fontSize: 11,
                              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Post content
                Text(
                  _currentPost.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: TugColors.getTextColor(isDarkMode, isViceMode),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Value badge with color and time
                if (_currentPost.hasValueInfo) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_currentPost.valueColorObject ?? TugColors.getPrimaryColor(isViceMode)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _currentPost.valueColorObject ?? TugColors.getPrimaryColor(isViceMode),
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
                            color: _currentPost.valueColorObject ?? TugColors.getPrimaryColor(isViceMode),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentPost.valueName!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _currentPost.valueColorObject ?? TugColors.getPrimaryColor(isViceMode),
                          ),
                        ),
                        if (_currentPost.formattedDuration.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            _currentPost.formattedDuration,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _currentPost.valueColorObject ?? TugColors.getPrimaryColor(isViceMode),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                
                // Post stats
                Row(
                  children: [
                    Text(
                      '${_currentPost.commentsCount} comments',
                      style: TextStyle(
                        fontSize: 12,
                        color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Comments list
          Expanded(
            child: _buildCommentsList(isDarkMode, isViceMode),
          ),
          
          // Comment input
          _buildCommentInput(isDarkMode, isViceMode),
        ],
      ),
    );
  }

  Widget _buildCommentsList(bool isDarkMode, bool isViceMode) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: TugColors.getPrimaryColor(isViceMode),
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            ),
            const SizedBox(height: 16),
            Text(
              'ainno comments yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TugColors.getTextColor(isDarkMode, isViceMode),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'say something sweet!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComments,
      color: TugColors.getPrimaryColor(isViceMode),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _comments.length,
        itemBuilder: (context, index) {
          final comment = _comments[index];
          return _buildCommentItem(comment, isDarkMode, isViceMode);
        },
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment, bool isDarkMode, bool isViceMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: TugColors.getPrimaryColor(isViceMode),
            child: Text(
              comment.displayName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (comment.userId != _currentUserId) {
                          context.push('/user/${comment.userId}');
                        }
                      },
                      child: Text(
                        comment.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: comment.userId != _currentUserId 
                              ? TugColors.getPrimaryColor(isViceMode)
                              : TugColors.getTextColor(isDarkMode, isViceMode),
                          decoration: comment.userId != _currentUserId 
                              ? TextDecoration.underline 
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgoText,
                      style: TextStyle(
                        fontSize: 11,
                        color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: TugColors.getTextColor(isDarkMode, isViceMode),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(bool isDarkMode, bool isViceMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
        border: Border(
          top: BorderSide(
            color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true)
                .withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                autofocus: widget.autoFocusInput,
                decoration: InputDecoration(
                  hintText: 'share your thoughts...',
                  hintStyle: TextStyle(
                    color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                  ),
                  filled: true,
                  fillColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: TextStyle(
                  color: TugColors.getTextColor(isDarkMode, isViceMode),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: TugColors.getPrimaryColor(isViceMode),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isPostingComment ? null : _postComment,
                icon: _isPostingComment
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}