// lib/utils/local_storage.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class LocalStorage {
  static Future<void> initialize() async {
    try {
      final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
      
      // Open boxes
      await Hive.openBox<String>('values');
      await Hive.openBox<String>('activities');
      await Hive.openBox<String>('settings');
      
      debugPrint('Hive initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Hive: $e');
      rethrow;
    }
  }

  static Box<String> getValuesBox() {
    return Hive.box<String>('values');
  }

  static Box<String> getActivitiesBox() {
    return Hive.box<String>('activities');
  }

  static Box<String> getSettingsBox() {
    return Hive.box<String>('settings');
  }
}