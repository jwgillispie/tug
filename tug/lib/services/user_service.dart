// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../config/env_confg.dart';

class UserService {
  String get baseUrl => '${EnvConfig.apiUrl}/api/v1';
  
  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<UserModel> getUserProfile(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  Future<UserModel> getCurrentUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else {
        throw Exception('Failed to load current user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load current user profile: $e');
    }
  }

  Future<UserModel> updateCurrentUserProfile({
    String? displayName,
    String? bio,
    String? profilePictureUrl,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> updateData = {};
      
      if (displayName != null) updateData['display_name'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (profilePictureUrl != null) updateData['profile_picture_url'] = profilePictureUrl;

      final response = await http.patch(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else {
        throw Exception('Failed to update user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Legacy method for backward compatibility
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<Map<String, dynamic>> uploadProfilePicture(String base64Image) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/me/profile-picture'),
        headers: headers,
        body: json.encode({'image': base64Image}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to upload profile picture: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}