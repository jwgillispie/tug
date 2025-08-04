// // lib/utils/local_storage.dart
// import 'package:flutter/foundation.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:path_provider/path_provider.dart' as path_provider;

// class LocalStorage {
//   static Future<void> initialize() async {
//     try {
//       // Skip Hive initialization on web
//       if (kIsWeb) {
//         debugPrint('Running on web, skipping Hive initialization');
//         return;
//       }
      
//       final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
//       await Hive.initFlutter(appDocumentDir.path);
      
//       // Open boxes
//       await Hive.openBox<String>('values');
//       await Hive.openBox<String>('activities');
//       await Hive.openBox<String>('settings');
      
//       debugPrint('Hive initialized successfully');
//     } catch (e) {
//       debugPrint('Error initializing Hive: $e');
//       // Don't rethrow when on web to prevent app from crashing
//       if (!kIsWeb) {
//         rethrow;
//       }
//     }
//   }

//   static Box<String> getValuesBox() {
//     if (kIsWeb) {
//       throw UnsupportedError('Local storage not available on web');
//     }
//     return Hive.box<String>('values');
//   }

//   static Box<String> getActivitiesBox() {
//     if (kIsWeb) {
//       throw UnsupportedError('Local storage not available on web');
//     }
//     return Hive.box<String>('activities');
//   }

//   static Box<String> getSettingsBox() {
//     if (kIsWeb) {
//       throw UnsupportedError('Local storage not available on web');
//     }
//     return Hive.box<String>('settings');
//   }
// }
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static late SharedPreferences _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Store & retrieve a string
  static Future<void> setValue(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static String? getValue(String key) {
    return _prefs.getString(key);
  }

  // Store & retrieve a boolean
  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Store & retrieve an integer
  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }
}