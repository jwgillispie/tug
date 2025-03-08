// lib/repositories/values_repository.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/value_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class IValuesRepository {
  Future<List<ValueModel>> getValues();
  Future<ValueModel> addValue(ValueModel value);
  Future<ValueModel> updateValue(ValueModel value);
  Future<void> deleteValue(String id);
}

class ValuesRepository implements IValuesRepository {
  final ApiService _apiService;
  final Box<String> _localValuesBox;

  ValuesRepository({
    ApiService? apiService,
    Box<String>? localValuesBox,
  }) : _apiService = apiService ?? ApiService(),
       _localValuesBox = localValuesBox ?? Hive.box<String>('values');

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
        final cachedValues = _getCachedValues();
        cachedValues.add(newValue);
        _cacheValues(cachedValues);
        
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
        final cachedValues = _getCachedValues();
        cachedValues.add(tempValue);
        _cacheValues(cachedValues);
        
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
        final cachedValues = _getCachedValues();
        final index = cachedValues.indexWhere((v) => v.id == value.id);
        if (index != -1) {
          cachedValues[index] = updatedValue;
          _cacheValues(cachedValues);
        }
        
        return updatedValue;
      }
    } catch (e) {
      debugPrint('Error updating value on API: $e');
      
      // Update locally if offline
      final cachedValues = _getCachedValues();
      final index = cachedValues.indexWhere((v) => v.id == value.id);
      if (index != -1) {
        cachedValues[index] = value;
        _cacheValues(cachedValues);
      }
    }
    
    // Return original value if all else fails
    return value;
  }

  @override
  Future<void> deleteValue(String id) async {
    try {
      await _apiService.delete('/api/v1/values/$id');
      
      // Remove from cache
      final cachedValues = _getCachedValues();
      cachedValues.removeWhere((value) => value.id == id);
      _cacheValues(cachedValues);
    } catch (e) {
      debugPrint('Error deleting value from API: $e');
      
      // Just mark as inactive locally if offline
      final cachedValues = _getCachedValues();
      final index = cachedValues.indexWhere((v) => v.id == id);
      if (index != -1) {
        cachedValues[index] = cachedValues[index].copyWith(active: false);
        _cacheValues(cachedValues);
      }
    }
  }

  // Helper methods for local caching
  List<ValueModel> _getCachedValues() {
    try {
      final cachedData = _localValuesBox.get('values');
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

  void _cacheValues(List<ValueModel> values) {
    try {
      final valuesJson = values.map((value) => value.toJson()).toList();
      _localValuesBox.put('values', jsonEncode(valuesJson));
    } catch (e) {
      debugPrint('Error caching values: $e');
    }
  }
}