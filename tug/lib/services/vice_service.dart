// lib/services/vice_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/vice_model.dart';
import '../models/indulgence_model.dart';
import '../config/env_confg.dart';

class ViceService {
  final Dio _dio;
  final Logger _logger = Logger();
  
  ViceService() : _dio = Dio() {
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
          _logger.e('ViceService: Error getting Firebase auth token: $e');
        }
        handler.next(options);
      },
    ));
  }

  // Vice Management

  Future<List<ViceModel>> getVices() async {
    try {
      _logger.i('ViceService: Getting vices');
      
      final response = await _dio.get('/api/v1/vices/');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['vices'] ?? [];
        return data.map((json) => ViceModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vices: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('ViceService: DioException getting vices: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.response?.statusCode == 404) {
        // Return cached vices if available
        _logger.i('ViceService: Falling back to cached vices due to network error or 404');
        return _getCachedVices();
      }
      
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('ViceService: Error getting vices: $e');
      return _getCachedVices();
    }
  }

  Future<ViceModel> createVice(ViceModel vice) async {
    try {
      _logger.i('ViceService: Creating vice: ${vice.name}');
      
      final response = await _dio.post(
        '/api/v1/vices/',
        data: vice.toJson(),
      );
      
      if (response.statusCode == 201) {
        final createdVice = ViceModel.fromJson(response.data['vice']);
        _logger.i('ViceService: Vice created successfully');
        
        // Update cache
        await _updateViceCache(createdVice);
        
        return createdVice;
      } else {
        throw Exception('Failed to create vice: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('ViceService: DioException creating vice: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('ViceService: Error creating vice: $e');
      throw Exception('Failed to create vice: $e');
    }
  }

  Future<ViceModel> updateVice(ViceModel vice) async {
    try {
      _logger.i('ViceService: Updating vice: ${vice.id}');
      
      final response = await _dio.put(
        '/api/v1/vices/${vice.id}/',
        data: vice.toJson(),
      );
      
      if (response.statusCode == 200) {
        final updatedVice = ViceModel.fromJson(response.data['vice']);
        _logger.i('ViceService: Vice updated successfully');
        
        // Update cache
        await _updateViceCache(updatedVice);
        
        return updatedVice;
      } else {
        throw Exception('Failed to update vice: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('ViceService: DioException updating vice: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('ViceService: Error updating vice: $e');
      throw Exception('Failed to update vice: $e');
    }
  }

  Future<void> deleteVice(String viceId) async {
    try {
      _logger.i('ViceService: Deleting vice: $viceId');
      
      final response = await _dio.delete('/api/v1/vices/$viceId/');
      
      if (response.statusCode == 200) {
        _logger.i('ViceService: Vice deleted successfully');
        
        // Remove from cache
        await _removeViceFromCache(viceId);
      } else {
        throw Exception('Failed to delete vice: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('ViceService: DioException deleting vice: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('ViceService: Error deleting vice: $e');
      throw Exception('Failed to delete vice: $e');
    }
  }

  // Indulgence Management

  Future<IndulgenceModel> recordIndulgence(IndulgenceModel indulgence) async {
    try {
      _logger.i('ViceService: Recording indulgence for vice: ${indulgence.viceId}');
      
      final response = await _dio.post(
        '/api/v1/vices/${indulgence.viceId}/indulge',
        data: indulgence.toJson(),
      );
      
      if (response.statusCode == 201) {
        final recordedIndulgence = IndulgenceModel.fromJson(response.data['indulgence']);
        _logger.i('ViceService: Indulgence recorded successfully');
        
        return recordedIndulgence;
      } else {
        throw Exception('Failed to record indulgence: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('ViceService: DioException recording indulgence: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('ViceService: Error recording indulgence: $e');
      throw Exception('Failed to record indulgence: $e');
    }
  }

  Future<List<IndulgenceModel>> getIndulgences(String viceId) async {
    try {
      _logger.i('ViceService: Getting indulgences for vice: $viceId');
      
      final response = await _dio.get('/api/v1/vices/$viceId/indulgences');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['indulgences'] ?? [];
        return data.map((json) => IndulgenceModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load indulgences: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('ViceService: DioException getting indulgences: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('ViceService: Error getting indulgences: $e');
      throw Exception('Failed to load indulgences: $e');
    }
  }

  // Streak Management

  Future<void> updateViceStreak(String viceId, int newStreak) async {
    try {
      _logger.i('ViceService: Updating streak for vice: $viceId to $newStreak');
      
      final response = await _dio.patch(
        '/api/v1/vices/$viceId/streak',
        data: {'current_streak': newStreak},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update streak: ${response.statusCode}');
      }
      
      _logger.i('ViceService: Streak updated successfully');
    } on DioException catch (e) {
      _logger.e('ViceService: DioException updating streak: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('ViceService: Error updating streak: $e');
      throw Exception('Failed to update streak: $e');
    }
  }

  Future<void> markCleanDay(String viceId, DateTime date) async {
    try {
      _logger.i('ViceService: Marking clean day for vice: $viceId on ${date.toIso8601String()}');
      
      final response = await _dio.post(
        '/api/v1/vices/$viceId/clean-day',
        data: {'date': date.toIso8601String()},
      );
      
      if (response.statusCode != 201) {
        throw Exception('Failed to mark clean day: ${response.statusCode}');
      }
      
      _logger.i('ViceService: Clean day marked successfully');
    } on DioException catch (e) {
      _logger.e('ViceService: DioException marking clean day: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('ViceService: Error marking clean day: $e');
      throw Exception('Failed to mark clean day: $e');
    }
  }

  // Cache Management

  Future<List<ViceModel>> _getCachedVices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedVicesJson = prefs.getString('cached_vices');
      
      if (cachedVicesJson != null) {
        final List<dynamic> cachedData = json.decode(cachedVicesJson);
        return cachedData.map((json) => ViceModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      _logger.e('ViceService: Error getting cached vices: $e');
      return [];
    }
  }

  Future<void> _updateViceCache(ViceModel vice) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedVices = await _getCachedVices();
      
      // Update or add the vice
      final index = cachedVices.indexWhere((v) => v.id == vice.id);
      if (index != -1) {
        cachedVices[index] = vice;
      } else {
        cachedVices.add(vice);
      }
      
      final cachedVicesJson = json.encode(cachedVices.map((v) => v.toJson()).toList());
      await prefs.setString('cached_vices', cachedVicesJson);
    } catch (e) {
      _logger.e('ViceService: Error updating vice cache: $e');
    }
  }

  Future<void> _removeViceFromCache(String viceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedVices = await _getCachedVices();
      
      cachedVices.removeWhere((v) => v.id == viceId);
      
      final cachedVicesJson = json.encode(cachedVices.map((v) => v.toJson()).toList());
      await prefs.setString('cached_vices', cachedVicesJson);
    } catch (e) {
      _logger.e('ViceService: Error removing vice from cache: $e');
    }
  }
}