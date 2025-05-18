// lib/services/rankings_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tug/services/api_service.dart';
import 'package:tug/services/cache_service.dart';
import 'package:tug/models/ranking_model.dart';
import 'package:tug/utils/api_error.dart';

class RankingsService {
  final ApiService _apiService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CacheService _cacheService = CacheService();
  
  // Cache keys
  static const String _rankingsCacheKeyPrefix = 'rankings_';
  static const String _userRankCacheKeyPrefix = 'user_rank_';
  
  // Cache durations
  static const Duration _rankingsCacheDuration = Duration(minutes: 15);
  static const Duration _diskCacheDuration = Duration(hours: 2);

  RankingsService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Get top users rankings
  Future<RankingsListModel> getTopUsers({
    int days = 30, 
    int limit = 20,
    String rankBy = 'activities',
    bool forceRefresh = false,
  }) async {
    final String cacheKey = '${_rankingsCacheKeyPrefix}${rankBy}_${days}_$limit';
    
    // Try to get from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        debugPrint('Using cached rankings data');
        final currentUserId = _auth.currentUser?.uid;
        return RankingsListModel.fromJson(cachedData, currentUserId: currentUserId);
      }
    }
    
    // Fetch from API if not in cache or force refresh
    try {
      final response = await _apiService.get(
        '/api/v1/rankings',
        queryParameters: {
          'days': days,
          'limit': limit,
          'rank_by': rankBy,
        },
      );

      // Cache the response
      await _cacheService.set(
        cacheKey, 
        response, 
        memoryCacheDuration: _rankingsCacheDuration,
        diskCacheDuration: _diskCacheDuration
      );
      
      final currentUserId = _auth.currentUser?.uid;
      return RankingsListModel.fromJson(response, currentUserId: currentUserId);
    } on ApiError catch (e) {
      debugPrint('Error getting rankings: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error getting rankings: $e');
      throw ApiError(
        statusCode: 500,
        message: 'Failed to load rankings: $e',
        code: 'ranking_error',
      );
    }
  }

  // Get current user rank
  Future<UserRankingModel?> getCurrentUserRank({
    int days = 30,
    bool forceRefresh = false,
  }) async {
    final String cacheKey = '${_userRankCacheKeyPrefix}${days}';
    final currentUserId = _auth.currentUser?.uid;
    
    if (currentUserId == null) {
      return null; // No user logged in
    }
    
    // Try to get from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        debugPrint('Using cached user rank data');
        return UserRankingModel.fromJson(cachedData, currentUserId: currentUserId);
      }
    }
    
    try {
      final response = await _apiService.get(
        '/api/v1/rankings/me',
        queryParameters: {
          'days': days,
        },
      );

      // Cache the response
      await _cacheService.set(
        cacheKey, 
        response, 
        memoryCacheDuration: _rankingsCacheDuration,
        diskCacheDuration: _diskCacheDuration
      );
      
      return UserRankingModel.fromJson(response, currentUserId: currentUserId);
    } on ApiError catch (e) {
      debugPrint('Error getting user rank: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error getting user rank: $e');
      throw ApiError(
        statusCode: 500,
        message: 'Failed to load user rank: $e',
        code: 'ranking_error',
      );
    }
  }
  
  // Clear all rankings cache
  Future<void> clearCache() async {
    await _cacheService.clearByPrefix(_rankingsCacheKeyPrefix);
    await _cacheService.clearByPrefix(_userRankCacheKeyPrefix);
    debugPrint('Rankings cache cleared');
  }
}