// lib/services/social_service.dart
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/social_models.dart';
import '../config/env_confg.dart';

class SocialService {
  final Dio _dio;
  final Logger _logger = Logger();
  
  SocialService() : _dio = Dio() {
    _dio.options.baseUrl = EnvConfig.apiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.followRedirects = true;
    _dio.options.maxRedirects = 3;
    _dio.options.validateStatus = (status) {
      return status != null && status >= 200 && status < 400;
    };
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = firebase_auth.FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken(true);
            options.headers['Authorization'] = 'Bearer $token';
            // Auth token added successfully
          } else {
            _logger.w('SocialService: No Firebase user found');
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
      final requestData = request.toJson();
      _logger.i('SocialService: Request data: $requestData');
      
      final response = await _dio.post(
        '/api/v1/social/friends/request',
        data: requestData,
      );
      
      if (response.statusCode == 201) {
        final friendship = FriendshipModel.fromJson(response.data['friendship']);
        _logger.i('SocialService: Friend request sent successfully');
        
        return friendship;
      } else {
        throw Exception('Failed to send friend request: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      
      if (statusCode == 400 && responseData != null) {
        // Handle specific 400 errors with user-friendly messages
        final detail = responseData['detail'] ?? 'Bad request';
        if (detail.contains('Already friends')) {
          throw Exception('You are already friends with this user');
        } else if (detail.contains('Friend request already pending')) {
          throw Exception('Friend request already sent');
        } else if (detail.contains('Cannot send friend request to yourself')) {
          throw Exception('Cannot send friend request to yourself');
        } else if (detail.contains('Cannot send friend request to blocked user')) {
          throw Exception('Cannot send friend request to this user');
        }
        throw Exception(detail);
      } else if (statusCode == 404) {
        throw Exception('User not found');
      } else if (statusCode == 401 || statusCode == 403) {
        throw Exception('Authentication required. Please log in again.');
      }
      
      _logger.e('SocialService: DioException sending friend request: ${e.message}');
      _logger.e('SocialService: Response data: $responseData');
      _logger.e('SocialService: Response status: $statusCode');
      throw Exception('Network error. Please try again later.');
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
        
      } else {
        throw Exception('Failed to respond to friend request: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      
      if (statusCode == 400 && responseData != null) {
        final detail = responseData['detail'] ?? 'Bad request';
        if (detail.contains('no longer pending')) {
          throw Exception('Friend request is no longer pending');
        } else if (detail.contains('Not authorized')) {
          throw Exception('You are not authorized to respond to this request');
        }
        throw Exception(detail);
      } else if (statusCode == 404) {
        throw Exception('Friend request not found');
      } else if (statusCode == 401 || statusCode == 403) {
        throw Exception('Authentication required. Please log in again.');
      }
      
      _logger.e('SocialService: DioException responding to friend request: ${e.message}');
      throw Exception('Network error. Please try again later.');
    } catch (e) {
      _logger.e('SocialService: Error responding to friend request: $e');
      throw Exception('Failed to respond to friend request: $e');
    }
  }

  Future<List<FriendshipModel>> getFriends({bool forceRefresh = false}) async {
    try {
      _logger.i('SocialService: Getting friends list');
      
      final response = await _dio.get('/api/v1/social/friends');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['friends'] ?? [];
        final friends = data.map((json) => FriendshipModel.fromJson(json)).toList();
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

  Future<SocialPostModel> updatePost(String postId, String newContent) async {
    try {
      _logger.i('SocialService: Updating post: $postId');
      
      final response = await _dio.put(
        '/api/v1/social/posts/$postId',
        data: {'content': newContent},
      );
      
      if (response.statusCode == 200) {
        final post = SocialPostModel.fromJson(response.data['post']);
        _logger.i('SocialService: Post updated successfully');
        
        return post;
      } else {
        throw Exception('Failed to update post: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException updating post: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error updating post: $e');
      throw Exception('Failed to update post: $e');
    }
  }

  Future<List<SocialPostModel>> getSocialFeed({int limit = 20, int skip = 0, bool forceRefresh = false}) async {
    try {
      _logger.i('SocialService: Getting social feed (limit: $limit, skip: $skip)');
      
      final response = await _dio.get(
        '/api/v1/social/feed',
        queryParameters: {
          'limit': limit, 
          'skip': skip,
          'timestamp': DateTime.now().millisecondsSinceEpoch, // Cache buster
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['posts'] ?? [];
        final posts = data.map((json) => SocialPostModel.fromJson(json)).toList();
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
      
      final response = await _dio.get(
        '/api/v1/social/posts/$postId/comments',
        queryParameters: {'limit': limit, 'skip': skip},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['comments'] ?? [];
        final comments = data.map((json) => CommentModel.fromJson(json)).toList();
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
      
      final response = await _dio.get('/api/v1/social/statistics');
      
      if (response.statusCode == 200) {
        final stats = response.data as Map<String, dynamic>;
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

  // Social Data Cleanup Methods

  // Note: Post deletion is not supported by the backend since posts are auto-generated
  // from activities and achievements. To remove a post, delete the underlying activity.

  Future<void> removeFriend(String friendshipId) async {
    try {
      _logger.i('SocialService: Removing friend: $friendshipId');
      
      final response = await _dio.delete('/api/v1/social/friends/$friendshipId');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.i('SocialService: Friend removed successfully');
      } else {
        throw Exception('Failed to remove friend: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialService: DioException removing friend: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialService: Error removing friend: $e');
      throw Exception('Failed to remove friend: $e');
    }
  }

  Future<void> clearAllUserSocialData() async {
    try {
      _logger.i('SocialService: Clearing all user social data');
      
      // Try the bulk endpoint first
      try {
        await _dio.delete('/api/v1/social/user/all-data');
        _logger.i('SocialService: All user social data cleared successfully via bulk endpoint');
        return;
      } on DioException catch (bulkError) {
        if (bulkError.response?.statusCode == 404) {
          _logger.i('SocialService: Bulk endpoint not available, falling back to individual deletions');
        } else {
          rethrow;
        }
      }
      
      // Fallback: Delete individual social data
      _logger.i('SocialService: Performing individual social data cleanup');
      
      // Note: Posts are auto-generated from activities and cannot be deleted directly
      // They will be cleaned up when the underlying activities/achievements are deleted
      _logger.i('SocialService: Skipping post deletion - posts are auto-generated from activities');
      
      // Get and remove all friendships
      try {
        final friends = await getFriends();
        for (final friendship in friends) {
          try {
            await removeFriend(friendship.id);
          } catch (e) {
            _logger.w('SocialService: Failed to remove friend ${friendship.id}: $e');
          }
        }
        _logger.i('SocialService: Removed ${friends.length} friendships');
      } catch (e) {
        _logger.w('SocialService: Error during friendship cleanup: $e');
      }
      
      _logger.i('SocialService: Individual social data cleanup completed');
      
    } catch (e) {
      _logger.e('SocialService: Error clearing social data: $e');
      throw Exception('Failed to clear social data: $e');
    }
  }

}