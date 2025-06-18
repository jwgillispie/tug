// lib/services/values_service.dart
import 'package:flutter/foundation.dart';
import 'package:tug/models/value_model.dart';
import 'api_service.dart';
import 'service_locator.dart';

class ValuesService {
  final ApiService _apiService;

  ValuesService({ApiService? apiService}) 
      : _apiService = apiService ?? ServiceLocator.apiService;

  // Fetch all values
  Future<List<ValueModel>> getValues({bool includeInactive = false}) async {
    try {
      final response = await _apiService.get(
        '/api/v1/values',
        queryParameters: {'include_inactive': includeInactive.toString()},
      );
      
      if (response is List) {
        return response.map((json) => ValueModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Create a new value
  Future<ValueModel> createValue(ValueModel value) async {
    try {
      final response = await _apiService.post(
        '/api/v1/values',
        data: value.toJson(),
      );
      return ValueModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update an existing value
  Future<ValueModel> updateValue(ValueModel value) async {
    try {
      if (value.id == null) {
        throw Exception('Cannot update value without ID');
      }
      
      final response = await _apiService.patch(
        '/api/v1/values/${value.id}',
        data: value.toJson(),
      );
      return ValueModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a value (deactivate)
  Future<bool> deleteValue(String valueId) async {
    try {
      await _apiService.delete('/api/v1/values/$valueId');
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Get value counts
  Future<Map<String, int>> getValueCounts() async {
    try {
      final response = await _apiService.get('/api/v1/values/stats/count');
      return Map<String, int>.from(response);
    } catch (e) {
      return {'total': 0, 'active': 0};
    }
  }
}