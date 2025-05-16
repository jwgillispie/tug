// lib/services/rankings_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tug/services/api_service.dart';
import 'package:tug/models/ranking_model.dart';
import 'package:tug/utils/api_error.dart';

class RankingsService {
  final ApiService _apiService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RankingsService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Get top users rankings
  Future<RankingsListModel> getTopUsers({
    int days = 30, 
    int limit = 20,
    String rankBy = 'activities'
  }) async {
    try {
      final response = await _apiService.get(
        '/api/v1/rankings',
        queryParameters: {
          'days': days,
          'limit': limit,
          'rank_by': rankBy,
        },
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
  Future<UserRankingModel?> getCurrentUserRank({int days = 30}) async {
    try {
      final response = await _apiService.get(
        '/api/v1/rankings/me',
        queryParameters: {
          'days': days,
        },
      );

      final currentUserId = _auth.currentUser?.uid;
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
}