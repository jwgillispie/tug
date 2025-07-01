import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/theme/colors.dart';
import '../../services/app_mode_service.dart';
import '../../services/social_service.dart';
import '../../models/social_models.dart';
import '../../blocs/auth/auth_bloc.dart';
import 'user_search_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  final AppModeService _appModeService = AppModeService();
  final SocialService _socialService = SocialService();
  
  AppMode _currentMode = AppMode.valuesMode;
  List<FriendshipModel> _friends = [];
  List<FriendshipModel> _pendingRequests = [];
  bool _isLoading = false;
  bool _isLoadingRequests = false;
  String? _currentUserId;
  StreamSubscription<AppMode>? _modeSubscription;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeMode();
    _getCurrentUser();
    _loadFriends();
    _loadPendingRequests();
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

  Future<void> _loadFriends() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final friends = await _socialService.getFriends();
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load friends: $e'),
            backgroundColor: TugColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadPendingRequests() async {
    if (_isLoadingRequests) return;
    
    setState(() {
      _isLoadingRequests = true;
    });

    try {
      final requests = await _socialService.getPendingFriendRequests();
      setState(() {
        _pendingRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  Future<void> _respondToFriendRequest(String friendshipId, bool accept) async {
    try {
      await _socialService.respondToFriendRequest(friendshipId, accept);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Friend request accepted!' : 'Friend request declined.'),
            backgroundColor: accept ? TugColors.success : TugColors.warning,
          ),
        );
      }
      // Refresh both lists
      _loadPendingRequests();
      _loadFriends();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to respond to friend request: $e'),
            backgroundColor: TugColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _modeSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;

    return Scaffold(
      backgroundColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
      appBar: AppBar(
        title: const Text('friends'),
        backgroundColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.person_add,
              color: TugColors.getTextColor(isDarkMode, isViceMode),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserSearchScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TugColors.getPrimaryColor(isViceMode),
          labelColor: TugColors.getPrimaryColor(isViceMode),
          unselectedLabelColor: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
          tabs: [
            Tab(
              text: 'friends (${_friends.length})',
            ),
            Tab(
              text: 'requests (${_pendingRequests.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(isDarkMode, isViceMode),
          _buildRequestsTab(isDarkMode, isViceMode),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(bool isDarkMode, bool isViceMode) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: TugColors.getPrimaryColor(isViceMode),
        ),
      );
    }

    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            ),
            const SizedBox(height: 16),
            Text(
              'no friends yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TugColors.getTextColor(isDarkMode, isViceMode),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'search for friends to get started!',
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
                  MaterialPageRoute(builder: (context) => const UserSearchScreen()),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('find friends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TugColors.getPrimaryColor(isViceMode),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      color: TugColors.getPrimaryColor(isViceMode),
      child: ListView.builder(
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friendship = _friends[index];
          return _buildFriendItem(friendship, isDarkMode, isViceMode);
        },
      ),
    );
  }

  Widget _buildRequestsTab(bool isDarkMode, bool isViceMode) {
    if (_isLoadingRequests) {
      return Center(
        child: CircularProgressIndicator(
          color: TugColors.getPrimaryColor(isViceMode),
        ),
      );
    }

    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            ),
            const SizedBox(height: 16),
            Text(
              'no pending requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TugColors.getTextColor(isDarkMode, isViceMode),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'friend requests will appear here',
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
      onRefresh: _loadPendingRequests,
      color: TugColors.getPrimaryColor(isViceMode),
      child: ListView.builder(
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          return _buildRequestItem(request, isDarkMode, isViceMode);
        },
      ),
    );
  }

  Widget _buildFriendItem(FriendshipModel friendship, bool isDarkMode, bool isViceMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: TugColors.getPrimaryColor(isViceMode),
            child: const Text(
              'F', // Default since we don't have user info in FriendshipModel
              style: TextStyle(
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
                  'friend', // We'll need to get user info from another API call
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TugColors.getTextColor(isDarkMode, isViceMode),
                  ),
                ),
                Text(
                  'connected since ${_formatDate(friendship.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: TugColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'friends',
              style: TextStyle(
                color: TugColors.success,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(FriendshipModel request, bool isDarkMode, bool isViceMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: TugColors.getPrimaryColor(isViceMode),
            child: const Text(
              'R', // Default since we don't have user info in FriendshipModel
              style: TextStyle(
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
                  'friend request',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TugColors.getTextColor(isDarkMode, isViceMode),
                  ),
                ),
                Text(
                  'from: ${request.requesterId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => _respondToFriendRequest(request.id, false),
                child: Text(
                  'decline',
                  style: TextStyle(color: TugColors.error),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _respondToFriendRequest(request.id, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TugColors.getPrimaryColor(isViceMode),
                  foregroundColor: Colors.white,
                ),
                child: const Text('accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}