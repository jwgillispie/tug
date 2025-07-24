// lib/services/vice_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/vice_model.dart';
import '../models/indulgence_model.dart';
import '../config/env_confg.dart';
import '../utils/streak_utils.dart';

class ViceService {
  final Dio _dio;
  final Logger _logger = Logger();
  
  ViceService() : _dio = Dio() {
    _dio.options.baseUrl = EnvConfig.apiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.followRedirects = true;
    _dio.options.maxRedirects = 3;
    _dio.options.validateStatus = (status) {
      return status != null && status >= 200 && status < 400;
    };
    
    // Add auth interceptor with retry logic for quota exceeded
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = firebase_auth.FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Try to get token without forcing refresh first
            try {
              final token = await user.getIdToken(false);
              options.headers['Authorization'] = 'Bearer $token';
            } catch (e) {
              // If that fails, wait a bit and try with forced refresh as fallback
              if (e.toString().contains('quota-exceeded')) {
                _logger.w('ViceService: Auth quota exceeded, using cached token if available');
                // Try to use cached token
                try {
                  final cachedToken = await user.getIdToken(false);
                  options.headers['Authorization'] = 'Bearer $cachedToken';
                } catch (_) {
                  _logger.e('ViceService: No cached token available');
                }
              } else {
                rethrow;
              }
            }
          }
        } catch (e) {
          _logger.e('ViceService: Error getting Firebase auth token: $e');
        }
        handler.next(options);
      },
    ));
  }

  // Vice Management

  Future<List<ViceModel>> getVices({bool forceRefresh = false, bool useCache = true}) async {
    try {
      // Check cache first if not forcing refresh and cache is enabled
      if (!forceRefresh && useCache) {
        final cachedVices = await _getCachedVices();
        final cacheAge = await _getCacheAge('vices');
        
        // Use cache if it's less than 5 minutes old and not empty
        if (cachedVices.isNotEmpty && cacheAge != null && cacheAge.inMinutes < 5) {
          _logger.i('ViceService: Returning cached vices (age: ${cacheAge.inMinutes} minutes)');
          
          // Refresh in background if cache is getting old (>2 minutes)
          if (cacheAge.inMinutes > 2) {
            _backgroundRefreshVices();
          }
          
          return cachedVices;
        }
      }
      
      _logger.i('ViceService: Fetching vices from server (forceRefresh: $forceRefresh)');
      
      final response = await _dio.get('/api/v1/vices/');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['vices'] ?? [];
        List<ViceModel> vices = data.map((json) => ViceModel.fromJson(json)).toList();
        
        // Calculate updated streaks for all vices
        vices = await _calculateViceStreaks(vices);
        
        // Cache the fresh data with calculated streaks
        await _cacheVices(vices);
        
        return vices;
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
      
      // If we get here, the request was successful (validateStatus handled the status codes)
      _logger.i('ViceService: Vice deleted successfully (status: ${response.statusCode})');
      
      // Remove from cache
      await _removeViceFromCache(viceId);
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
      _logger.i('ViceService: Recording indulgence for vices: ${indulgence.viceIds.join(", ")}');
      
      // Try the new multi-vice endpoint first
      try {
        final response = await _dio.post(
          '/api/v1/indulgences/', // New multi-vice endpoint
          data: indulgence.toJson(),
        );
        
        if (response.statusCode == 201) {
          final recordedIndulgence = IndulgenceModel.fromJson(response.data['indulgence']);
          _logger.i('ViceService: Indulgence recorded successfully via new endpoint');
          
          // Invalidate cache to force recalculation of streaks on next load
          await invalidateVicesCache();
          
          return recordedIndulgence;
        } else {
          throw Exception('Failed to record indulgence: ${response.statusCode}');
        }
      } catch (e) {
        _logger.w('ViceService: New endpoint failed, trying fallback: $e');
        
        // Fallback to old single-vice endpoint using primary vice
        final primaryViceId = indulgence.primaryViceId;
        if (primaryViceId == null || primaryViceId.isEmpty) {
          throw Exception('No valid vice selected for indulgence');
        }
        
        final fallbackResponse = await _dio.post(
          '/api/v1/vices/$primaryViceId/indulge', // Fallback to old single-vice endpoint
          data: indulgence.toJson(),
        );
        
        if (fallbackResponse.statusCode == 201) {
          final recordedIndulgence = IndulgenceModel.fromJson(fallbackResponse.data['indulgence']);
          _logger.i('ViceService: Indulgence recorded successfully via fallback endpoint');
          
          // Invalidate cache to force recalculation of streaks on next load
          await invalidateVicesCache();
          
          return recordedIndulgence;
        } else {
          throw Exception('Failed to record indulgence via fallback: ${fallbackResponse.statusCode}');
        }
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

  /// Get all indulgences for the current user across all vices
  Future<List<IndulgenceModel>> getAllIndulgences() async {
    try {
      _logger.i('ViceService: Getting all indulgences for user');
      
      // First get all vices (without streak calculation to avoid circular dependency)
      final vices = await _getVicesRaw();
      return await _getAllIndulgencesForVices(vices);
    } catch (e) {
      _logger.e('ViceService: Error getting all indulgences: $e');
      // Return empty list instead of throwing to prevent UI crashes
      return [];
    }
  }

  /// Get all indulgences for specific vices (internal method to avoid circular dependency)
  Future<List<IndulgenceModel>> _getAllIndulgencesForVices(List<ViceModel> vices) async {
    try {
      _logger.i('ViceService: Getting all indulgences for ${vices.length} vices');
      
      final List<IndulgenceModel> allIndulgences = [];
      
      // Get indulgences for each vice
      for (final vice in vices) {
        if (vice.id != null) {
          try {
            final viceIndulgences = await getIndulgences(vice.id!);
            allIndulgences.addAll(viceIndulgences);
          } catch (e) {
            _logger.w('ViceService: Failed to get indulgences for vice ${vice.id}: $e');
            // Continue with other vices even if one fails
          }
        }
      }
      
      // Sort by date descending (newest first)
      allIndulgences.sort((a, b) => b.date.compareTo(a.date));
      
      return allIndulgences;
    } catch (e) {
      _logger.e('ViceService: Error getting indulgences for vices: $e');
      return [];
    }
  }

  /// Get raw vices from server without streak calculation (to avoid circular dependency)
  Future<List<ViceModel>> _getVicesRaw() async {
    try {
      _logger.i('ViceService: Fetching raw vices from server');
      
      final response = await _dio.get('/api/v1/vices/');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['vices'] ?? [];
        List<ViceModel> vices = data.map((json) => ViceModel.fromJson(json)).toList();
        return vices;
      } else {
        throw Exception('Failed to load vices: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('ViceService: DioException getting raw vices: ${e.message}');
      
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
      _logger.e('ViceService: Error getting raw vices: $e');
      return _getCachedVices();
    }
  }

  /// Get indulgences for the current week (Sunday to Saturday)
  Future<List<IndulgenceModel>> getWeeklyIndulgences() async {
    try {
      _logger.i('ViceService: Getting weekly indulgences');
      
      // Get all indulgences
      final allIndulgences = await getAllIndulgences();
      
      // Calculate start of current week (Sunday)
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      
      // Filter indulgences for current week
      final weeklyIndulgences = allIndulgences.where((indulgence) {
        return indulgence.date.isAfter(startOfWeek) && indulgence.date.isBefore(endOfWeek);
      }).toList();
      
      _logger.i('ViceService: Found ${weeklyIndulgences.length} indulgences for current week');
      return weeklyIndulgences;
    } catch (e) {
      _logger.e('ViceService: Error getting weekly indulgences: $e');
      return [];
    }
  }

  /// Calculate updated streaks for all vices using the new StreakUtils system
  Future<List<ViceModel>> _calculateViceStreaks(List<ViceModel> vices) async {
    try {
      _logger.i('ViceService: Calculating streaks for ${vices.length} vices using calendar day logic');
      
      // Get all indulgences for the user (pass vices to avoid circular dependency)
      final allIndulgences = await _getAllIndulgencesForVices(vices);
      
      // Update each vice with calculated streak data using calendar days
      final updatedVices = StreakUtils.updateVicesWithStreaks(vices, allIndulgences);
      
      // Debug: Log streak calculations for verification
      for (final vice in updatedVices) {
        if (vice.id != null) {
          final debugInfo = StreakUtils.debugViceStreakCalculation(
            vice.id!,
            vice.name,
            allIndulgences.where((i) => i.viceIds.contains(vice.id)).toList(),
            vice.createdAt,
          );
          _logger.i('ViceService: Streak debug for ${vice.name}: current=${debugInfo['current_streak_calculated']}, method=${debugInfo['calculation_method']}');
        }
      }
      
      _logger.i('ViceService: Successfully calculated streaks for all vices using calendar day logic');
      return updatedVices;
    } catch (e) {
      _logger.w('ViceService: Error calculating streaks, returning original vices: $e');
      // Return original vices if streak calculation fails
      return vices;
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

  // Enhanced cache methods for better performance

  Future<void> _cacheVices(List<ViceModel> vices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vicesJson = json.encode(vices.map((v) => v.toJson()).toList());
      await prefs.setString('cached_vices', vicesJson);
      
      // Store cache timestamp
      await prefs.setInt('cached_vices_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      _logger.i('ViceService: Cached ${vices.length} vices');
    } catch (e) {
      _logger.e('ViceService: Error caching vices: $e');
    }
  }

  Future<Duration?> _getCacheAge(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('cached_${key}_timestamp');
      
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return DateTime.now().difference(cacheTime);
      }
      
      return null;
    } catch (e) {
      _logger.e('ViceService: Error getting cache age: $e');
      return null;
    }
  }

  // Background refresh to keep cache fresh without blocking UI
  void _backgroundRefreshVices() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        _logger.i('ViceService: Background refresh of vices');
        await getVices(forceRefresh: true, useCache: false);
      } catch (e) {
        _logger.w('ViceService: Background refresh failed: $e');
        // Silent failure - this is just optimization
      }
    });
  }

  // Cache invalidation methods
  Future<void> invalidateVicesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_vices');
      await prefs.remove('cached_vices_timestamp');
      _logger.i('ViceService: Vices cache invalidated');
    } catch (e) {
      _logger.e('ViceService: Error invalidating cache: $e');
    }
  }

  /// Clear all vices and indulgences cache data - useful for debugging
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all vice-related cache keys
      final keys = prefs.getKeys().where((key) => 
        key.startsWith('cached_vices') || 
        key.startsWith('vice_') ||
        key.startsWith('indulgence_')
      ).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      _logger.i('ViceService: All cache cleared (${keys.length} keys removed)');
    } catch (e) {
      _logger.e('ViceService: Error clearing all cache: $e');
    }
  }

  // Pre-load vices data for performance
  Future<void> preloadVicesData() async {
    try {
      _logger.i('ViceService: Preloading vices data');
      await getVices(forceRefresh: false, useCache: true);
    } catch (e) {
      _logger.w('ViceService: Preload failed: $e');
      // Silent failure - this is just optimization
    }
  }
}