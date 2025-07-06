import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/theme/colors.dart';
import '../../services/app_mode_service.dart';
import '../../services/social_service.dart';
import '../../models/social_models.dart';
import '../../blocs/auth/auth_bloc.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final AppModeService _appModeService = AppModeService();
  final SocialService _socialService = SocialService();
  final TextEditingController _searchController = TextEditingController();
  
  AppMode _currentMode = AppMode.valuesMode;
  List<UserSearchResult> _searchResults = [];
  List<FriendshipModel> _friendRequests = [];
  bool _isLoading = false;
  bool _isLoadingRequests = false;
  String? _currentUserId;
  StreamSubscription<AppMode>? _modeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeMode();
    _getCurrentUser();
    _loadFriendRequests();
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

  Future<void> _loadFriendRequests() async {
    if (_isLoadingRequests) return;
    
    setState(() {
      _isLoadingRequests = true;
    });

    try {
      final requests = await _socialService.getPendingFriendRequests();
      setState(() {
        _friendRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _socialService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to search users: $e'),
            backgroundColor: TugColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(String userId, String displayName) async {
    try {
      await _socialService.sendFriendRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to $displayName!'),
            backgroundColor: TugColors.success,
          ),
        );
      }
      // Update the search results to reflect the sent request
      setState(() {
        final updatedResults = <UserSearchResult>[];
        for (final user in _searchResults) {
          if (user.id == userId) {
            updatedResults.add(UserSearchResult(
              id: user.id,
              username: user.username,
              displayName: user.displayName,
              friendshipStatus: 'request_sent',
            ));
          } else {
            updatedResults.add(user);
          }
        }
        _searchResults = updatedResults;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send friend request: $e'),
            backgroundColor: TugColors.error,
          ),
        );
      }
    }
  }

  Future<void> _respondToFriendRequest(String userId, bool accept) async {
    try {
      await _socialService.respondToFriendRequest(userId, accept);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Friend request accepted!' : 'Friend request declined.'),
            backgroundColor: accept ? TugColors.success : TugColors.warning,
          ),
        );
      }
      _loadFriendRequests(); // Refresh the friend requests
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;

    return Scaffold(
      backgroundColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
      appBar: AppBar(
        title: const Text('find friends'),
        backgroundColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'search for friends by username or email...',
                hintStyle: TextStyle(
                  color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: TugColors.getPrimaryColor(isViceMode),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: TextStyle(
                color: TugColors.getTextColor(isDarkMode, isViceMode),
              ),
            ),
          ),

          // Friend requests section
          if (_friendRequests.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: TugColors.getPrimaryColor(isViceMode),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'friend requests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: TugColors.getTextColor(isDarkMode, isViceMode),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _friendRequests.length,
              itemBuilder: (context, index) {
                final request = _friendRequests[index];
                return _buildFriendRequestItem(request, isDarkMode, isViceMode);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Search results
          Expanded(
            child: _buildSearchResults(isDarkMode, isViceMode),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestItem(FriendshipModel request, bool isDarkMode, bool isViceMode) {
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
            child: Text(
              'U', // Default since we don't have user info in FriendshipModel
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
                  'friend request', // We'll need to get user info from another API call
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TugColors.getTextColor(isDarkMode, isViceMode),
                  ),
                ),
                Text(
                  request.requesterId,
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

  Widget _buildSearchResults(bool isDarkMode, bool isViceMode) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: TugColors.getPrimaryColor(isViceMode),
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            ),
            const SizedBox(height: 16),
            Text(
              'search for friends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TugColors.getTextColor(isDarkMode, isViceMode),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'enter a username or email to find friends',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            ),
            const SizedBox(height: 16),
            Text(
              'no users found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TugColors.getTextColor(isDarkMode, isViceMode),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'try a different search term',
              style: TextStyle(
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriendRequests,
      color: TugColors.getPrimaryColor(isViceMode),
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          return _buildUserItem(user, isDarkMode, isViceMode);
        },
      ),
    );
  }

  Widget _buildUserItem(UserSearchResult user, bool isDarkMode, bool isViceMode) {
    final friendshipStatus = user.friendshipStatus;
    final displayName = user.displayName ?? 'Unknown User';
    final username = user.username;
    final userId = user.id;

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
            child: Text(
              displayName[0].toUpperCase(),
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
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TugColors.getTextColor(isDarkMode, isViceMode),
                  ),
                ),
                Text(
                  '@$username',
                  style: TextStyle(
                    fontSize: 12,
                    color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(user, isDarkMode, isViceMode),
        ],
      ),
    );
  }

  Widget _buildActionButton(UserSearchResult user, bool isDarkMode, bool isViceMode) {
    final friendshipStatus = user.friendshipStatus;
    final userId = user.id;
    final displayName = user.displayName ?? 'Unknown User';

    switch (friendshipStatus) {
      case 'friends':
        return Container(
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
        );
      case 'request_sent':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: TugColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'pending',
            style: TextStyle(
              color: TugColors.warning,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        );
      case 'request_received':
        return ElevatedButton(
          onPressed: () => _respondToFriendRequest(userId, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: TugColors.getPrimaryColor(isViceMode),
            foregroundColor: Colors.white,
          ),
          child: const Text('accept'),
        );
      default:
        return ElevatedButton(
          onPressed: () => _sendFriendRequest(userId, displayName),
          style: ElevatedButton.styleFrom(
            backgroundColor: TugColors.getPrimaryColor(isViceMode),
            foregroundColor: Colors.white,
          ),
          child: const Text('add friend'),
        );
    }
  }
}