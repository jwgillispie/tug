import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/value_model.dart';

abstract class IValuesRepository {
  Future<List<ValueModel>> getValues();
  Future<ValueModel> addValue(ValueModel value);
  Future<ValueModel> updateValue(ValueModel value);
  Future<void> deleteValue(String id);
}

class ValuesRepository implements IValuesRepository {
  final ApiService _apiService;
  late final SharedPreferences _prefs;

  ValuesRepository({
    ApiService? apiService,
    SharedPreferences? prefs,
  }) : _apiService = apiService ?? ApiService() {
    // Initialize SharedPreferences
    _initializePrefs(prefs);
  }

  Future<void> _initializePrefs(SharedPreferences? prefs) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<List<ValueModel>> getValues() async {
    try {
      // Try to get values from API
      final response = await _apiService.get('/api/v1/values');

      if (response != null) {
        final List<dynamic> valuesData = response;
        final values = valuesData
            .map((valueData) => ValueModel.fromJson(valueData))
            .toList();

        // Cache the values locally
        _cacheValues(values);

        return values;
      }
    } catch (e) {
      debugPrint('Error fetching values from API: $e');
    }

    // If API call fails or no data, return cached values
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

        // Update cache
        final cachedValues = await _getCachedValues();
        cachedValues.add(newValue);
        await _cacheValues(cachedValues);

        return newValue;
      }
    } catch (e) {
      debugPrint('Error adding value to API: $e');

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

        // Update cache
        final cachedValues = await _getCachedValues();
        final index = cachedValues.indexWhere((v) => v.id == value.id);
        if (index != -1) {
          cachedValues[index] = updatedValue;
          await _cacheValues(cachedValues);
        }

        return updatedValue;
      }
    } catch (e) {
      debugPrint('Error updating value on API: $e');

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

      debugPrint('Deleting value: $id');

      await _apiService.delete(url);

      // Remove from cache
      final cachedValues = await _getCachedValues();
      cachedValues.removeWhere((value) => value.id == id);
      await _cacheValues(cachedValues);
    } catch (e) {
      debugPrint('Error deleting value from API: $e');

      // Just mark as inactive locally if offline
      final cachedValues = await _getCachedValues();
      final index = cachedValues.indexWhere((v) => v.id == id);
      if (index != -1) {
        cachedValues[index] = cachedValues[index].copyWith(active: false);
        await _cacheValues(cachedValues);
      }
    }
  }

  // Helper methods for local caching
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
      debugPrint('Error getting cached values: $e');
    }
    return [];
  }

  Future<void> _cacheValues(List<ValueModel> values) async {
    try {
      await _ensurePrefsInitialized();
      final valuesJson = values.map((value) => value.toJson()).toList();
      await _prefs.setString('values', jsonEncode(valuesJson));
    } catch (e) {
      debugPrint('Error caching values: $e');
    }
  }

  Future<void> _ensurePrefsInitialized() async {
    if (_prefs == null) {
      await _initializePrefs(null);
    }
  }
}