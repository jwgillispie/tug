import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../models/value_model.dart';

abstract class IValuesRepository {
  Future<List<ValueModel>> getValues({bool forceRefresh = false});
  Future<ValueModel> addValue(ValueModel value);
  Future<ValueModel> updateValue(ValueModel value);
  Future<void> deleteValue(String id);
  Future<Map<String, dynamic>> getStreakStats({String? valueId, bool forceRefresh = false});
}

class ValuesRepository implements IValuesRepository {
  final ApiService _apiService;
  final CacheService _cacheService;
  late final SharedPreferences _prefs;

  // Cache keys
  static const String _valuesCacheKey = 'values_list';
  static const Duration _cacheValidity = Duration(minutes: 15);

  ValuesRepository({
    ApiService? apiService,
    CacheService? cacheService,
    SharedPreferences? prefs,
  }) : 
    _apiService = apiService ?? ApiService(),
    _cacheService = cacheService ?? CacheService() {
    // Initialize SharedPreferences
    _initializePrefs(prefs);
  }

  Future<void> _initializePrefs(SharedPreferences? prefs) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<List<ValueModel>> getValues({bool forceRefresh = false}) async {
    // If force refresh is requested, don't use cache
    if (!forceRefresh) {
      try {
        // Try to get from cache first
        final cachedValues = await _cacheService.get<List<dynamic>>(_valuesCacheKey);
        
        if (cachedValues != null) {
          return cachedValues
              .map((valueData) => ValueModel.fromJson(Map<String, dynamic>.from(valueData)))
              .toList();
        }
      } catch (e) {
      }
    } else {
    }

    try {
      // Fetch from API if cache didn't work or force refresh was requested
      final response = await _apiService.get('/api/v1/values');

      if (response != null) {
        final List<dynamic> valuesData = response;
        final values = valuesData
            .map((valueData) => ValueModel.fromJson(valueData))
            .toList();

        // Cache the values
        await _cacheService.set(
          _valuesCacheKey, 
          valuesData, 
          memoryCacheDuration: _cacheValidity,
          diskCacheDuration: Duration(hours: 3),
        );

        return values;
      }
    } catch (e) {
    }

    // If API call fails or no data, return cached values (which might be empty)
    return _getCachedValues();
  }

  @override
  Future<ValueModel> addValue(ValueModel value) async {
    try {
      final response = await _apiService.post(
        '/api/v1/values',
        data: value.toJson(),
      );

      if (response != null) {
        final newValue = ValueModel.fromJson(response);

        // Invalidate cache
        await _cacheService.remove(_valuesCacheKey);

        return newValue;
      }
    } catch (e) {

      // Store locally if offline
      if (value.id == null) {
        // Generate a temporary ID
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final tempValue = value.copyWith(id: tempId);

        // Add to cache
        final cachedValues = await _getCachedValues();
        cachedValues.add(tempValue);
        await _cacheValues(cachedValues);

        return tempValue;
      }
    }

    // Return original value if all else fails
    return value;
  }

  @override
  Future<ValueModel> updateValue(ValueModel value) async {
    try {
      if (value.id == null) {
        throw Exception('Cannot update value without ID');
      }

      final response = await _apiService.patch(
        '/api/v1/values/${value.id}',
        data: value.toJson(),
      );

      if (response != null) {
        final updatedValue = ValueModel.fromJson(response);

        // Invalidate cache
        await _cacheService.remove(_valuesCacheKey);

        return updatedValue;
      }
    } catch (e) {

      // Update locally if offline
      final cachedValues = await _getCachedValues();
      final index = cachedValues.indexWhere((v) => v.id == value.id);
      if (index != -1) {
        cachedValues[index] = value;
        await _cacheValues(cachedValues);
      }
    }

    // Return original value if all else fails
    return value;
  }

  @override
  Future<void> deleteValue(String id) async {
    try {
      // Don't add trailing slash here - ApiService will handle it
      final url = '/api/v1/values/$id';


      await _apiService.delete(url);

      // Invalidate cache
      await _cacheService.remove(_valuesCacheKey);
    } catch (e) {

      // Just mark as inactive locally if offline
      final cachedValues = await _getCachedValues();
      final index = cachedValues.indexWhere((v) => v.id == id);
      if (index != -1) {
        cachedValues[index] = cachedValues[index].copyWith(active: false);
        await _cacheValues(cachedValues);
      }
    }
  }

  // Helper methods for local caching using SharedPreferences
  Future<List<ValueModel>> _getCachedValues() async {
    try {
      await _ensurePrefsInitialized();
      final cachedData = _prefs.getString('values');
      if (cachedData != null) {
        final List<dynamic> valuesData = jsonDecode(cachedData);
        return valuesData
            .map((valueData) => ValueModel.fromJson(valueData))
            .toList();
      }
    } catch (e) {
    }
    return [];
  }

  Future<void> _cacheValues(List<ValueModel> values) async {
    try {
      await _ensurePrefsInitialized();
      final valuesJson = values.map((value) => value.toJson()).toList();
      await _prefs.setString('values', jsonEncode(valuesJson));
    } catch (e) {
    }
  }

  Future<void> _ensurePrefsInitialized() async {
    
  }
  
  @override
  Future<Map<String, dynamic>> getStreakStats({String? valueId, bool forceRefresh = false}) async {
    // Generate a cache key based on value ID
    final cacheKey = 'streak_stats_${valueId ?? "all"}';

    // Try to get from cache first if not forcing refresh
    if (!forceRefresh) {
      try {
        final cachedStats = await _cacheService.get<Map<String, dynamic>>(cacheKey);
        if (cachedStats != null) {
          return cachedStats;
        }
      } catch (e) {
      }
    } else {
    }

    try {
      String url = '/api/v1/values/stats/streaks';

      if (valueId != null) {
        url = '$url?value_id=$valueId';
      }

      final response = await _apiService.get(url);

      if (response != null) {
        final stats = Map<String, dynamic>.from(response);

        // Cache the streak stats
        await _cacheService.set(
          cacheKey,
          stats,
          memoryCacheDuration: _cacheValidity,
          diskCacheDuration: Duration(hours: 2),
        );

        return stats;
      }
    } catch (e) {
    }

    // Return empty map if API fails and no cache is available
    return {};
  }
}