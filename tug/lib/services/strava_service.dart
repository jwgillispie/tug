// lib/services/strava_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:strava_client/strava_client.dart';
import 'package:tug/models/activity_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tug/services/activity_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;

// This defines the auth callback result
class AuthResult {
  final bool success;
  final String? accessToken;
  final String? errorMessage;
  final bool redirectError;  // Indicates a specific redirect error (browser can't connect to localhost)

  AuthResult({
    required this.success, 
    this.accessToken, 
    this.errorMessage,
    this.redirectError = false,  // Default to false for backward compatibility
  });
}

// This defines the import result
class ImportResult {
  final int importedCount;
  final List<String> importedActivityIds;
  final String? errorMessage;

  ImportResult({
    required this.importedCount,
    required this.importedActivityIds,
    this.errorMessage,
  });
}

class StravaService {
  late final StravaClient _stravaClient;
  final ActivityService _activityService = ActivityService();
  final AppLinks _appLinks = AppLinks();
  Timer? _linkTimeout;

  // OAuth settings
  static const String _scope = 'read,activity:read';
  // Use redirect URI from .env, with fallback to http://localhost
  
  // Storage keys
  static const String _stravaTokenKey = 'strava_access_token';
  static const String _stravaExpiresAtKey = 'strava_token_expires_at';
  static const String _stravaRefreshTokenKey = 'strava_refresh_token';
  static const String _stravaDefaultValueIdKey = 'strava_default_value_id';
  static const String _stravaAthleteIdKey = 'strava_athlete_id';

  // Create a Completer to handle the OAuth flow
  Completer<AuthResult>? _authCompleter;

  StravaService() {
    // Get credentials from .env file using Flutter dotenv
    final clientId = dotenv.env['STRAVA_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['STRAVA_CLIENT_SECRET'] ?? '';

    if (clientId.isEmpty || clientSecret.isEmpty) {
      debugPrint('WARNING: Strava credentials not found in .env file');
    }

    _stravaClient = StravaClient(
      secret: clientSecret, 
      clientId: clientId,
    );

    // Set up app links listener for OAuth callback
    _setupAppLinks();
  }

  void _setupAppLinks() {
    _appLinks.uriLinkStream.listen((uri) async {
      debugPrint('Received app link URI: $uri');
      // Cancel the timeout timer if it's running
      _linkTimeout?.cancel();
      
      // We want to handle both http://localhost and tug://strava-auth formats
      bool isStravaRedirect = false;
      
      // Check if it's the http://localhost format
      if (uri.toString().startsWith('http://localhost') || 
          uri.toString().startsWith('https://localhost')) {
        isStravaRedirect = true;
        debugPrint('Detected Strava OAuth callback via localhost');
      }
      
      // Check if it's the custom scheme format
      if (uri.scheme == 'tug' && 
          (uri.host == 'strava-auth' || uri.toString().contains('strava'))) {
        isStravaRedirect = true;
        debugPrint('Detected Strava OAuth callback via custom scheme');
      }
      
      if (isStravaRedirect) {
        debugPrint('Full callback URI: $uri');
        final authCode = uri.queryParameters['code'];
        final error = uri.queryParameters['error'];
        
        if (authCode != null) {
          debugPrint('Auth code received: ${authCode.substring(0, 5)}...');
          // Get tokens using the authorization code
          await _getTokensWithCode(authCode);
        } else if (error != null) {
          debugPrint('Error received in callback: $error');
          _authCompleter?.complete(
            AuthResult(
              success: false, 
              errorMessage: error,
              redirectError: error.toLowerCase().contains('redirect') || error.toLowerCase().contains('url'),
            ),
          );
        } else {
          debugPrint('No code or error found in callback URI parameters: ${uri.queryParameters}');
        }
      } else {
        debugPrint('URI does not match any Strava callback patterns: $uri');
      }
    });
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

  // Get Strava athlete details and store them
  Future<void> _getAthleteDetails() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) return;

      // Make an API request to get the athlete's details
      debugPrint('Fetching athlete details...');
      
      final response = await http.get(
        Uri.parse('https://www.strava.com/api/v3/athlete'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      
      if (response.statusCode == 200) {
        final athleteData = jsonDecode(response.body);
        final athleteId = athleteData['id']?.toString();
        
        if (athleteId != null) {
          debugPrint('Got athlete ID: $athleteId');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_stravaAthleteIdKey, athleteId);
        } else {
          debugPrint('Athlete ID not found in response');
        }
      } else {
        debugPrint('Error getting athlete: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting athlete details: $e');
    }
  }

  /// Connect to Strava by opening the OAuth flow
  Future<AuthResult> connect() async {
    try {
      // Check for existing auth completer and cancel it
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.complete(
          AuthResult(success: false, errorMessage: 'Authentication cancelled'),
        );
      }
      
      // Create a new auth completer
      _authCompleter = Completer<AuthResult>();
      
      // Create the OAuth URL
      final clientId = dotenv.env['STRAVA_CLIENT_ID'] ?? '';
      // Get redirect URI from environment with fallback
      final redirectUri = dotenv.env['STRAVA_REDIRECT_URI'] ?? 'tug://strava-auth';
      // URI-encode the redirect URI to ensure it's properly formatted
      final encodedRedirectUri = Uri.encodeComponent(redirectUri);
      
      final oauthUrl = 
        'https://www.strava.com/oauth/authorize?client_id=$clientId'
        '&redirect_uri=$encodedRedirectUri'
        '&response_type=code'
        '&approval_prompt=auto'
        '&scope=$_scope';
        
      debugPrint('OAuth URL: $oauthUrl');
      
      // Open the Strava authorization page in the browser
      final url = Uri.parse(oauthUrl);
      
      // Check if the clientId is valid
      if (clientId.isEmpty || clientId == 'Not set') {
        return AuthResult(
          success: false, 
          errorMessage: 'Strava Client ID not configured. Please set up your Strava API credentials in the .env file',
        );
      }
      
      if (await canLaunchUrl(url)) {
        try {
          // Store the OAuth URL for manual entry fallback
          final oauthUrl = url.toString();
          await launchUrl(url, mode: LaunchMode.externalApplication);
          
          // Set a timeout for the OAuth flow (2 minutes)
          _linkTimeout = Timer(const Duration(minutes: 2), () {
            if (_authCompleter != null && !_authCompleter!.isCompleted) {
              // Create a specific error message for this common Safari issue
              final errorMessage = 'Authentication timed out. This could be due to one of the following issues:\n\n'
                  '1. The browser could not redirect back to the app (check that "tug" is set as the Authorization Callback Domain in Strava settings)\n'
                  '2. Your Strava API credentials might be incorrect\n'
                  '3. You might not have approved the authorization in the browser\n\n'
                  'It is recommended to try the manual code entry method instead.';
              
              debugPrint('OAuth timeout: $errorMessage');
              _authCompleter!.complete(
                AuthResult(
                  success: false, 
                  errorMessage: errorMessage,
                  // Add a flag to indicate a redirect error for better handling
                  redirectError: true,
                ),
              );
            }
          });
          
          // Wait for the redirect
          return await _authCompleter!.future;
        } catch (e) {
          debugPrint('Error launching URL: $e');
          return AuthResult(
            success: false, 
            errorMessage: 'Error launching Strava login: ${e.toString()}',
          );
        }
      } else {
        debugPrint('Cannot launch URL: $url');
        return AuthResult(
          success: false, 
          errorMessage: 'Could not launch Strava login page. Please check your internet connection.',
        );
      }
    } catch (e) {
      debugPrint('Strava connection error: $e');
      return AuthResult(success: false, errorMessage: e.toString());
    }
  }

  /// Handle a manually entered authorization code
  Future<AuthResult> handleManualCode(String authCode) async {
    try {
      debugPrint('Handling manual authorization code: ${authCode.substring(0, 5)}...');
      
      // Exchange the code for tokens
      final result = await _exchangeCodeForTokens(authCode);
      
      return result;
    } catch (e) {
      debugPrint('Error handling manual code: $e');
      return AuthResult(success: false, errorMessage: e.toString());
    }
  }
  
  /// Exchange code for tokens (used by both automatic and manual flows)
  Future<AuthResult> _exchangeCodeForTokens(String authCode) async {
    try {
      final clientId = dotenv.env['STRAVA_CLIENT_ID'] ?? '';
      final clientSecret = dotenv.env['STRAVA_CLIENT_SECRET'] ?? '';
      
      debugPrint('Exchanging authorization code for tokens...');
      
      // Make the API call to exchange the code for tokens
      final tokenUrl = 'https://www.strava.com/oauth/token';
      final response = await http.post(
        Uri.parse(tokenUrl),
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': authCode,
          'grant_type': 'authorization_code',
        },
      );
      
      debugPrint('Token exchange response code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        
        // Extract tokens from response
        final accessToken = tokenData['access_token'];
        final refreshToken = tokenData['refresh_token'];
        final expiresAt = tokenData['expires_at'];
        
        if (accessToken != null && refreshToken != null && expiresAt != null) {
          debugPrint('Successfully obtained tokens from Strava');
          
          // Save tokens to preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_stravaTokenKey, accessToken);
          await prefs.setString(_stravaRefreshTokenKey, refreshToken);
          await prefs.setInt(_stravaExpiresAtKey, expiresAt);
          
          // Get athlete details
          await _getAthleteDetails();
          
          return AuthResult(success: true, accessToken: accessToken);
        } else {
          debugPrint('Missing token data in response: $tokenData');
          return AuthResult(
            success: false,
            errorMessage: 'Missing token data in Strava response',
          );
        }
      } else {
        debugPrint('Token exchange failed: ${response.body}');
        return AuthResult(
          success: false,
          errorMessage: 'Token exchange failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error exchanging code for token: $e');
      return AuthResult(success: false, errorMessage: e.toString());
    }
  }

  // Exchange the authorization code for tokens for the OAuth flow
  Future<void> _getTokensWithCode(String authCode) async {
    try {
      // Use our common code exchange method
      final result = await _exchangeCodeForTokens(authCode);
      
      // Complete the auth flow with the result
      _authCompleter?.complete(result);
    } catch (e) {
      debugPrint('Error in OAuth token exchange: $e');
      _authCompleter?.complete(
        AuthResult(success: false, errorMessage: e.toString()),
      );
    }
  }
  
  // We don't need this anymore - it's just left for reference
  /*
  // Old implementation before refactoring
  Future<void> _oldImplementation(String authCode) async {
    // This function has been replaced by _exchangeCodeForTokens
  }
  */

  /// Disconnect from Strava
  Future<bool> disconnect() async {
    try {
      final accessToken = await getAccessToken();
      
      if (accessToken != null) {
        // Properly revoke the token with Strava API
        try {
          debugPrint('Deauthorizing with Strava API...');
          
          final response = await http.post(
            Uri.parse('https://www.strava.com/oauth/deauthorize'),
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          );
          
          if (response.statusCode == 200) {
            debugPrint('Successfully deauthorized from Strava');
          } else {
            debugPrint('Error deauthorizing from Strava: ${response.statusCode} ${response.body}');
            // Continue anyway to clean local data
          }
        } catch (e) {
          debugPrint('Error deauthorizing from Strava API: $e');
          // Continue anyway to clean local data
        }
      }
      
      // Clear local tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stravaTokenKey);
      await prefs.remove(_stravaExpiresAtKey);
      await prefs.remove(_stravaRefreshTokenKey);
      await prefs.remove(_stravaAthleteIdKey);
      await prefs.remove(_stravaDefaultValueIdKey);

      return true;
    } catch (e) {
      debugPrint('Strava disconnection error: $e');
      return false;
    }
  }

  /// Refresh the Strava access token
  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_stravaRefreshTokenKey);
      
      if (refreshToken == null) {
        debugPrint('No refresh token available');
        return false;
      }
      
      final clientId = dotenv.env['STRAVA_CLIENT_ID'] ?? '';
      final clientSecret = dotenv.env['STRAVA_CLIENT_SECRET'] ?? '';
      
      debugPrint('Refreshing Strava access token...');
      
      // Make the API call to refresh the token
      final response = await http.post(
        Uri.parse('https://www.strava.com/oauth/token'),
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );
      
      debugPrint('Token refresh response code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        
        final accessToken = tokenData['access_token'];
        final newRefreshToken = tokenData['refresh_token'];
        final expiresAt = tokenData['expires_at'];
        
        if (accessToken != null && newRefreshToken != null && expiresAt != null) {
          debugPrint('Token refreshed successfully');
          
          await prefs.setString(_stravaTokenKey, accessToken);
          await prefs.setString(_stravaRefreshTokenKey, newRefreshToken);
          await prefs.setInt(_stravaExpiresAtKey, expiresAt);
          return true;
        } else {
          debugPrint('Missing token data in refresh response: $tokenData');
          return false;
        }
      } else {
        debugPrint('Token refresh failed: ${response.body}');
        return false;
      }
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
      
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('Strava access token not found');
      }
      
      // Make a direct HTTP request to the Strava API to get activities
      try {
        debugPrint('Fetching Strava activities with token: ${accessToken.substring(0, 5)}...');
        
        final response = await http.get(
          Uri.parse('https://www.strava.com/api/v3/athlete/activities?per_page=$limit'),
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );
        
        debugPrint('Strava API response code: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final List<dynamic> activitiesJson = jsonDecode(response.body);
          debugPrint('Received ${activitiesJson.length} activities from Strava');
          
          if (activitiesJson.isEmpty) {
            return [];
          }
          
          // Parse the JSON response and convert to our ActivityModel format
          return activitiesJson.map((json) {
            // Extract activity data
            final id = json['id'].toString();
            final name = json['name'] ?? 'Strava Activity';
            final movingTimeSeconds = json['moving_time'] ?? 0;
            final distance = json['distance'] ?? 0.0; // in meters
            final elevationGain = json['total_elevation_gain'] ?? 0.0; // in meters
            final averageSpeed = json['average_speed'] ?? 0.0; // in m/s
            final startDateStr = json['start_date'] ?? '';
            final activityType = json['type'] ?? 'Activity';
            
            // Calculate duration in minutes
            final durationMin = (movingTimeSeconds / 60).round();
            
            // Parse the date
            DateTime date;
            try {
              // Parse the date from Strava - it contains timezone information (UTC)
              DateTime parsedDate = DateTime.parse(startDateStr);
              
              // Convert to UTC format with no timezone offset to avoid timezone comparison issues
              // Use toIso8601String() for serialization to API without timezone offset
              date = DateTime.utc(
                parsedDate.year, 
                parsedDate.month, 
                parsedDate.day,
                parsedDate.hour,
                parsedDate.minute,
                parsedDate.second,
              );
              
              debugPrint('Strava date converted: $startDateStr -> ${date.toIso8601String()}');
            } catch (e) {
              debugPrint('Error parsing Strava date: $e');
              date = DateTime.now().toUtc();
            }
            
            // Format notes with activity details
            String notes = 'Imported from Strava\n';
            notes += 'Type: $activityType\n';
            
            // Convert meters to kilometers for distance
            final distanceKm = (distance / 1000).toStringAsFixed(1);
            notes += 'Distance: $distanceKm km\n';
            
            if (elevationGain > 0) {
              notes += 'Elevation gain: $elevationGain m\n';
            }
            
            // Convert m/s to km/h for speed
            final speedKmh = (averageSpeed * 3.6).toStringAsFixed(1);
            notes += 'Avg speed: $speedKmh km/h\n';
            
            return ActivityModel(
              id: 'strava_$id',
              name: name,
              valueId: '',  // Will be set during import
              duration: durationMin,
              date: date,
              notes: notes,
              importSource: 'strava',
            );
          }).toList();
        } else if (response.statusCode == 401) {
          // Token expired - try to refresh
          debugPrint('Token expired, attempting to refresh...');
          final refreshSuccess = await _refreshToken();
          if (refreshSuccess) {
            // Retry with new token
            return getActivities(limit: limit);
          } else {
            debugPrint('Token refresh failed, falling back to sample data');
            return _getSampleActivities();
          }
        } else {
          debugPrint('Error fetching Strava activities: ${response.statusCode} ${response.body}');
          // Fallback to sample activities on API error
          return _getSampleActivities();
        }
      } catch (e) {
        debugPrint('Error fetching Strava activities via HTTP: $e');
        // Fallback to sample activities on exception
        return _getSampleActivities();
      }
    } catch (e) {
      debugPrint('Error in getActivities: $e');
      
      // Fallback to sample activities if there's an error
      return _getSampleActivities();
    }
  }

  /// Get sample activities for demo and testing purposes
  List<ActivityModel> _getSampleActivities() {
    final now = DateTime.now().toUtc(); // Use UTC date for consistency
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
      ActivityModel(
        id: 'strava_sample_4',
        name: 'Brooklyn Bridge Run',
        valueId: '',
        duration: 52,
        date: now.subtract(const Duration(days: 4)),
        notes:
            'Imported from Strava\nType: Run\nDistance: 6.4 km\nElevation gain: 85 m\nAvg speed: 7.2 km/h',
        importSource: 'strava',
      ),
      ActivityModel(
        id: 'strava_sample_5',
        name: 'Central Park Loop',
        valueId: '',
        duration: 38,
        date: now.subtract(const Duration(days: 5)),
        notes:
            'Imported from Strava\nType: Run\nDistance: 4.9 km\nElevation gain: 62 m\nAvg speed: 8.1 km/h',
        importSource: 'strava',
      ),
      ActivityModel(
        id: 'strava_sample_6',
        name: 'Hudson River Cycle',
        valueId: '',
        duration: 75,
        date: now.subtract(const Duration(days: 7)),
        notes:
            'Imported from Strava\nType: Ride\nDistance: 22.3 km\nElevation gain: 110 m\nAvg speed: 17.9 km/h',
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
      final failedActivities = <String>[];

      for (final activity in activities) {
        try {
          // Ensure the date is in UTC format to avoid timezone issues
          final utcDate = DateTime.utc(
            activity.date.year,
            activity.date.month,
            activity.date.day,
            activity.date.hour,
            activity.date.minute,
            activity.date.second,
          );
          
          // Create a new activity with the specified valueId and UTC date
          final newActivity = ActivityModel(
            name: activity.name,
            valueId: valueId,
            duration: activity.duration,
            date: utcDate,  // Use the UTC date
            notes: activity.notes ?? 'Imported from Strava',
            importSource: 'strava',
          );
          
          debugPrint('Importing activity: ${activity.name} with date: ${utcDate.toIso8601String()}');

          // Save to the database
          final result = await _activityService.createActivity(newActivity);
          if (result.id != null) {
            importedIds.add(result.id!);
            debugPrint('Successfully imported activity: ${result.id}');
          } else {
            failedActivities.add(activity.name);
            debugPrint('Failed to import activity: ${activity.name} - No ID returned');
          }
        } catch (activityError) {
          failedActivities.add(activity.name);
          debugPrint('Error importing individual activity ${activity.name}: $activityError');
        }
      }
      
      String? errorMessage;
      if (failedActivities.isNotEmpty) {
        errorMessage = 'Failed to import some activities: ${failedActivities.join(", ")}';
        debugPrint(errorMessage);
      }

      return ImportResult(
        importedCount: importedIds.length,
        importedActivityIds: importedIds,
        errorMessage: failedActivities.isNotEmpty ? errorMessage : null,
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
  
  /// Get the stored athlete ID
  Future<String?> getAthleteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_stravaAthleteIdKey);
  }
}
