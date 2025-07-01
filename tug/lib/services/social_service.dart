// lib/services/social_service.dart
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/social_models.dart';
import '../config/env_confg.dart';
import 'cache_service.dart';

class SocialService {
  final Dio _dio;
  final Logger _logger = Logger();
  final CacheService _cacheService = CacheService();
  
  SocialService() : _dio = Dio() {
    _dio.options.baseUrl = EnvConfig.apiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.followRedirects = true;
    _dio.options.maxRedirects = 3;
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = firebase_auth.FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken(true);
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          _logger.e('SocialService: Error getting Firebase auth token: $e');
        }
        handler.next(options);
      },
    ));
  }

  // Friend Management

  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      _logger.i('SocialService: Searching users with query: $query');
      
      final response = await _dio.get(
        '/api/v1/social/users/search/',
        queryParameters: {'q': query, 'limit': 20},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['users'] ?? [];
        return data.map((json) => UserSearchResult.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search users: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException searching users: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error searching users: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  Future<FriendshipModel> sendFriendRequest(String userId) async {
    try {
      _logger.i('SocialService: Sending friend request to: $userId');
      
      final request = FriendRequestCreate(addresseeId: userId);
      final response = await _dio.post(
        '/api/v1/social/friends/request',
        data: request.toJson(),
      );
      
      if (response.statusCode == 201) {
        final friendship = FriendshipModel.fromJson(response.data['friendship']);
        _logger.i('SocialService: Friend request sent successfully');
        
        // Invalidate friends cache
        await _invalidateFriendsCache();
        
        return friendship;
      } else {
        throw Exception('Failed to send friend request: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException sending friend request: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error sending friend request: $e');
      throw Exception('Failed to send friend request: $e');
    }
  }

  Future<void> respondToFriendRequest(String friendshipId, bool accept) async {
    try {
      _logger.i('SocialService: ${accept ? 'Accepting' : 'Rejecting'} friend request: $friendshipId');
      
      final response = await _dio.post(
        '/api/v1/social/friends/respond/$friendshipId',
        queryParameters: {'accept': accept},
      );
      
      if (response.statusCode == 200) {
        _logger.i('SocialService: Friend request response successful');
        
        // Invalidate friends cache since friendship status changed
        await _invalidateFriendsCache();
        
      } else {
        throw Exception('Failed to respond to friend request: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException responding to friend request: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error responding to friend request: $e');
      throw Exception('Failed to respond to friend request: $e');
    }
  }

  Future<List<FriendshipModel>> getFriends({bool forceRefresh = false}) async {
    try {
      _logger.i('SocialService: Getting friends list');
      
      const cacheKey = 'friends_list';
      
      // Try to get from cache first (unless force refresh)
      if (!forceRefresh) {
        try {
          final cachedData = await _cacheService.get<List<dynamic>>(cacheKey);
          if (cachedData != null) {
            _logger.i('SocialService: Returning cached friends list');
            return cachedData.map((json) => FriendshipModel.fromJson(json)).toList();
          }
        } catch (e) {
          _logger.w('SocialService: Failed to load cached friends: $e');
        }
      }
      
      final response = await _dio.get('/api/v1/social/friends');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['friends'] ?? [];
        final friends = data.map((json) => FriendshipModel.fromJson(json)).toList();
        
        // Cache the data
        try {
          await _cacheService.set(
            cacheKey, 
            data,
            memoryCacheDuration: const Duration(minutes: 10), // Friends list changes less frequently
            diskCacheDuration: const Duration(hours: 2), // 2 hours disk cache
          );
        } catch (e) {
          _logger.w('SocialService: Failed to cache friends: $e');
        }
        
        return friends;
      } else {
        throw Exception('Failed to get friends: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException getting friends: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error getting friends: $e');
      throw Exception('Failed to get friends: $e');
    }
  }

  Future<List<FriendshipModel>> getPendingFriendRequests() async {
    try {
      _logger.i('SocialService: Getting pending friend requests');
      
      final response = await _dio.get('/api/v1/social/friends/requests');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['friend_requests'] ?? [];
        return data.map((json) => FriendshipModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get friend requests: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException getting friend requests: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error getting friend requests: $e');
      throw Exception('Failed to get friend requests: $e');
    }
  }

  // Social Posts

  Future<SocialPostModel> createPost(CreatePostRequest request) async {
    try {
      _logger.i('SocialService: Creating post: ${request.content.substring(0, 50)}...');
      
      final response = await _dio.post(
        '/api/v1/social/posts',
        data: request.toJson(),
      );
      
      if (response.statusCode == 201) {
        final post = SocialPostModel.fromJson(response.data['post']);
        _logger.i('SocialService: Post created successfully');
        
        // Invalidate relevant caches
        await _invalidateFeedCache();
        await _invalidateStatisticsCache();
        
        return post;
      } else {
        throw Exception('Failed to create post: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException creating post: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  Future<List<SocialPostModel>> getSocialFeed({int limit = 20, int skip = 0, bool forceRefresh = false}) async {
    try {
      _logger.i('SocialService: Getting social feed (limit: $limit, skip: $skip, forceRefresh: $forceRefresh)');
      
      // Generate cache key based on limit and skip
      final cacheKey = 'social_feed_${limit}_$skip';
      
      // Try to get from cache first (unless force refresh)
      if (!forceRefresh) {
        try {
          final cachedData = await _cacheService.get<List<dynamic>>(cacheKey);
          if (cachedData != null) {
            _logger.i('SocialService: Returning cached social feed');
            return cachedData.map((json) => SocialPostModel.fromJson(json)).toList();
          }
        } catch (e) {
          _logger.w('SocialService: Failed to load cached social feed: $e');
        }
      }
      
      final response = await _dio.get(
        '/api/v1/social/feed',
        queryParameters: {'limit': limit, 'skip': skip},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['posts'] ?? [];
        final posts = data.map((json) => SocialPostModel.fromJson(json)).toList();
        
        // Cache the data
        try {
          await _cacheService.set(
            cacheKey, 
            data,
            memoryCacheDuration: const Duration(minutes: 2), // Short memory cache for social feed
            diskCacheDuration: const Duration(minutes: 10), // 10 minutes disk cache
          );
        } catch (e) {
          _logger.w('SocialService: Failed to cache social feed: $e');
        }
        
        return posts;
      } else {
        throw Exception('Failed to get social feed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException getting social feed: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error getting social feed: $e');
      throw Exception('Failed to get social feed: $e');
    }
  }

  Future<Map<String, dynamic>> likePost(String postId) async {
    try {
      _logger.i('SocialService: Toggling like for post: $postId');
      
      final response = await _dio.post('/api/v1/social/posts/$postId/like');
      
      if (response.statusCode == 200) {
        _logger.i('SocialService: Post like toggled successfully');
        
        // Invalidate relevant caches (likes affect feed and statistics)
        await _invalidateFeedCache();
        await _invalidateStatisticsCache();
        
        return {
          'liked': response.data['liked'],
          'likes_count': response.data['likes_count'],
        };
      } else {
        throw Exception('Failed to like post: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException liking post: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error liking post: $e');
      throw Exception('Failed to like post: $e');
    }
  }

  Future<CommentModel> addComment(String postId, String content) async {
    try {
      _logger.i('SocialService: Adding comment to post: $postId');
      
      final request = CreateCommentRequest(content: content);
      final response = await _dio.post(
        '/api/v1/social/posts/$postId/comments',
        data: request.toJson(),
      );
      
      if (response.statusCode == 201) {
        final comment = CommentModel.fromJson(response.data['comment']);
        _logger.i('SocialService: Comment added successfully');
        
        // Invalidate relevant caches
        await _invalidateCommentsCache(postId);
        await _invalidateFeedCache(); // Comments count affects feed
        await _invalidateStatisticsCache();
        
        return comment;
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException adding comment: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<List<CommentModel>> getPostComments(String postId, {int limit = 50, int skip = 0, bool forceRefresh = false}) async {
    try {
      _logger.i('SocialService: Getting comments for post: $postId');
      
      // Generate cache key based on post ID, limit, and skip
      final cacheKey = 'comments_${postId}_${limit}_$skip';
      
      // Try to get from cache first (unless force refresh)
      if (!forceRefresh) {
        try {
          final cachedData = await _cacheService.get<List<dynamic>>(cacheKey);
          if (cachedData != null) {
            _logger.i('SocialService: Returning cached comments for post: $postId');
            return cachedData.map((json) => CommentModel.fromJson(json)).toList();
          }
        } catch (e) {
          _logger.w('SocialService: Failed to load cached comments: $e');
        }
      }
      
      final response = await _dio.get(
        '/api/v1/social/posts/$postId/comments',
        queryParameters: {'limit': limit, 'skip': skip},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['comments'] ?? [];
        final comments = data.map((json) => CommentModel.fromJson(json)).toList();
        
        // Cache the data
        try {
          await _cacheService.set(
            cacheKey, 
            data,
            memoryCacheDuration: const Duration(minutes: 5), // Comments change less frequently
            diskCacheDuration: const Duration(hours: 1), // 1 hour disk cache
          );
        } catch (e) {
          _logger.w('SocialService: Failed to cache comments: $e');
        }
        
        return comments;
      } else {
        throw Exception('Failed to get comments: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException getting comments: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error getting comments: $e');
      throw Exception('Failed to get comments: $e');
    }
  }

  Future<Map<String, dynamic>> getSocialStatistics({bool forceRefresh = false}) async {
    try {
      _logger.i('SocialService: Getting social statistics');
      
      const cacheKey = 'social_statistics';
      
      // Try to get from cache first (unless force refresh)
      if (!forceRefresh) {
        try {
          final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
          if (cachedData != null) {
            _logger.i('SocialService: Returning cached social statistics');
            return cachedData;
          }
        } catch (e) {
          _logger.w('SocialService: Failed to load cached social statistics: $e');
        }
      }
      
      final response = await _dio.get('/api/v1/social/statistics');
      
      if (response.statusCode == 200) {
        final stats = response.data as Map<String, dynamic>;
        
        // Cache the data
        try {
          await _cacheService.set(
            cacheKey, 
            stats,
            memoryCacheDuration: const Duration(minutes: 5), // Statistics change periodically
            diskCacheDuration: const Duration(hours: 1), // 1 hour disk cache
          );
        } catch (e) {
          _logger.w('SocialService: Failed to cache social statistics: $e');
        }
        
        return stats;
      } else {
        throw Exception('Failed to get social statistics: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException getting social statistics: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error getting social statistics: $e');
      throw Exception('Failed to get social statistics: $e');
    }
  }

  // Cache invalidation methods
  
  /// Invalidates social feed cache when new posts are created or feed changes
  Future<void> _invalidateFeedCache() async {
    try {
      await _cacheService.clearByPrefix('social_feed_');
      _logger.i('SocialService: Social feed cache invalidated');
    } catch (e) {
      _logger.w('SocialService: Failed to invalidate feed cache: $e');
    }
  }

  /// Invalidates comments cache for a specific post
  Future<void> _invalidateCommentsCache(String postId) async {
    try {
      await _cacheService.clearByPrefix('comments_$postId');
      _logger.i('SocialService: Comments cache invalidated for post: $postId');
    } catch (e) {
      _logger.w('SocialService: Failed to invalidate comments cache: $e');
    }
  }

  /// Invalidates social statistics cache
  Future<void> _invalidateStatisticsCache() async {
    try {
      await _cacheService.remove('social_statistics');
      _logger.i('SocialService: Social statistics cache invalidated');
    } catch (e) {
      _logger.w('SocialService: Failed to invalidate statistics cache: $e');
    }
  }

  /// Invalidates friends cache
  Future<void> _invalidateFriendsCache() async {
    try {
      await _cacheService.remove('friends_list');
      _logger.i('SocialService: Friends cache invalidated');
    } catch (e) {
      _logger.w('SocialService: Failed to invalidate friends cache: $e');
    }
  }
}