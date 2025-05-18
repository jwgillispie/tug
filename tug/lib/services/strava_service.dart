// lib/services/strava_service.dart
import 'package:flutter/foundation.dart';
import 'package:strava_client/strava_client.dart';
import 'package:tug/models/activity_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tug/services/activity_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthResult {
  final bool success;
  final String? accessToken;
  final String? errorMessage;

  AuthResult({required this.success, this.accessToken, this.errorMessage});
}

class ImportResult {
  final int importedCount;
  final List<String> importedActivityIds;
  final String? errorMessage;

  ImportResult(
      {required this.importedCount,
      required this.importedActivityIds,
      this.errorMessage});
}

class StravaService {
  late final StravaClient _stravaClient;
  final ActivityService _activityService = ActivityService();

  // Storage keys
  static const String _stravaTokenKey = 'strava_access_token';
  static const String _stravaExpiresAtKey = 'strava_token_expires_at';
  static const String _stravaRefreshTokenKey = 'strava_refresh_token';
  static const String _stravaDefaultValueIdKey = 'strava_default_value_id';

  StravaService() {
    final clientId = dotenv.env['STRAVA_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['STRAVA_CLIENT_SECRET'] ?? '';

    _stravaClient = StravaClient(secret: clientSecret, clientId: clientId);
  }

  /// Check if the user is already connected to Strava
  Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_stravaTokenKey);
    final expiresAt = prefs.getInt(_stravaExpiresAtKey);

    if (accessToken != null && expiresAt != null) {
      // Check if token is expired
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (expiresAt > now) {
        return true; // Token is valid
      } else {
        // Try to refresh the token
        return _refreshToken();
      }
    }

    return false;
  }

  /// Connect to Strava by opening the OAuth flow
  Future<AuthResult> connect() async {
    try {
      // For now, implement a simplified version that just reads tokens from .env
      // In a real implementation, this would use the OAuth flow with a webview or app

      // Simulate a successful authentication
      final accessToken = dotenv.env['STRAVA_ACCESS_TOKEN'] ?? 'dummy_token';
      final expiresAt =
          DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/
              1000;
      final refreshToken =
          dotenv.env['STRAVA_REFRESH_TOKEN'] ?? 'dummy_refresh_token';

      // Save tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stravaTokenKey, accessToken);
      await prefs.setInt(_stravaExpiresAtKey, expiresAt);
      await prefs.setString(_stravaRefreshTokenKey, refreshToken);

      // In a real app, we would launch a browser for OAuth and handle redirect
      // For demo purposes, we'll just show a success message
      debugPrint('Successfully connected to Strava (simulated)');

      return AuthResult(success: true, accessToken: accessToken);
    } catch (e) {
      debugPrint('Strava connection error: $e');
      return AuthResult(success: false, errorMessage: e.toString());
    }
  }

  /// Disconnect from Strava
  Future<bool> disconnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stravaTokenKey);
      await prefs.remove(_stravaExpiresAtKey);
      await prefs.remove(_stravaRefreshTokenKey);

      // In a real app, we would revoke tokens with Strava's API
      return true;
    } catch (e) {
      debugPrint('Strava disconnection error: $e');
      return false;
    }
  }

  /// Refresh the Strava access token
  Future<bool> _refreshToken() async {
    try {
      // In a real app, this would call the Strava API to refresh the token
      // For now, simulate successful refresh
      final accessToken =
          dotenv.env['STRAVA_ACCESS_TOKEN'] ?? 'refreshed_token';
      final expiresAt =
          DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/
              1000;
      final refreshToken =
          dotenv.env['STRAVA_REFRESH_TOKEN'] ?? 'refreshed_refresh_token';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stravaTokenKey, accessToken);
      await prefs.setInt(_stravaExpiresAtKey, expiresAt);
      await prefs.setString(_stravaRefreshTokenKey, refreshToken);

      return true;
    } catch (e) {
      debugPrint('Strava token refresh error: $e');
      return false;
    }
  }

  /// Get activities from Strava and convert them to Tug activity format
  Future<List<ActivityModel>> getActivities({int limit = 20}) async {
    try {
      if (!await isConnected()) {
        throw Exception('Not connected to Strava');
      }

      // In a real app, this would fetch from Strava API
      // For now, return sample activities
      return _getSampleActivities();
    } catch (e) {
      debugPrint('Error fetching Strava activities: $e');
      return [];
    }
  }

  /// Get sample activities for demo purposes
  List<ActivityModel> _getSampleActivities() {
    final now = DateTime.now();
    return [
      ActivityModel(
        id: 'strava_sample_1',
        name: 'Morning Run',
        valueId: '',
        duration: 45,
        date: now.subtract(const Duration(days: 1)),
        notes:
            'Imported from Strava\nType: Run\nDistance: 5.2 km\nElevation gain: 120 m',
        importSource: 'strava',
      ),
      ActivityModel(
        id: 'strava_sample_2',
        name: 'Evening Ride',
        valueId: '',
        duration: 60,
        date: now.subtract(const Duration(days: 2)),
        notes:
            'Imported from Strava\nType: Ride\nDistance: 15.7 km\nAvg speed: 16.8 km/h',
        importSource: 'strava',
      ),
      ActivityModel(
        id: 'strava_sample_3',
        name: 'Weekend Hike',
        valueId: '',
        duration: 120,
        date: now.subtract(const Duration(days: 3)),
        notes:
            'Imported from Strava\nType: Hike\nDistance: 8.3 km\nElevation gain: 450 m',
        importSource: 'strava',
      ),
    ];
  }

  /// Get the stored access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_stravaTokenKey);
  }

  /// Set the default value ID for Strava activity imports
  Future<bool> setDefaultValueId(String valueId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stravaDefaultValueIdKey, valueId);
      return true;
    } catch (e) {
      debugPrint('Error setting default value ID: $e');
      return false;
    }
  }

  /// Get the default value ID for Strava activity imports
  Future<String?> getDefaultValueId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_stravaDefaultValueIdKey);
    } catch (e) {
      debugPrint('Error getting default value ID: $e');
      return null;
    }
  }

  /// Import activities from Strava
  Future<ImportResult> importActivities(
      List<ActivityModel> activities, String valueId) async {
    try {
      final importedIds = <String>[];

      for (final activity in activities) {
        // Create a new activity with the specified valueId
        final newActivity = ActivityModel(
          name: activity.name,
          valueId: valueId,
          duration: activity.duration,
          date: activity.date,
          notes: activity.notes ?? 'Imported from Strava',
          importSource: 'strava',
        );

        // Save to the database
        final result = await _activityService.createActivity(newActivity);
        if (result != null && result.id != null) {
          importedIds.add(result.id!);
        }
      }

      return ImportResult(
        importedCount: importedIds.length,
        importedActivityIds: importedIds,
      );
    } catch (e) {
      debugPrint('Error importing activities: $e');
      return ImportResult(
        importedCount: 0,
        importedActivityIds: [],
        errorMessage: e.toString(),
      );
    }
  }
}
