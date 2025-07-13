// lib/services/store_config.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tug/config/env_confg.dart';

/// Configuration for the RevenueCat store
class StoreConfig {
  final Store store;
  final String apiKey;
  static StoreConfig? _instance;

  /// Create a new StoreConfig singleton instance
  factory StoreConfig({required Store store, required String apiKey}) {
    _instance ??= StoreConfig._internal(store, apiKey);
    return _instance!;
  }

  StoreConfig._internal(this.store, this.apiKey);

  /// Get the singleton instance
  static StoreConfig get instance {
    if (_instance == null) {
      throw StateError('StoreConfig has not been initialized');
    }
    return _instance!;
  }

  /// Check if the store is Apple App Store
  static bool isForAppleStore() => 
      !kIsWeb && (Platform.isIOS || Platform.isMacOS) && 
      instance.store == Store.appStore;

  /// Check if the store is Google Play Store
  static bool isForGooglePlay() => 
      !kIsWeb && Platform.isAndroid && 
      instance.store == Store.playStore;

  /// Check if the store is Amazon Appstore
  static bool isForAmazonAppstore() => 
      !kIsWeb && Platform.isAndroid && 
      instance.store == Store.amazon;
      
  /// Initialize the store configuration
  static void initialize() {
    if (kIsWeb) {
      return;
    }
    
    final apiKey = EnvConfig.revenueCatApiKey;
    if (apiKey.isEmpty) {
      return;
    }
    
    if (Platform.isIOS || Platform.isMacOS) {
      StoreConfig(
        store: Store.appStore,
        apiKey: apiKey,
      );
    } else if (Platform.isAndroid) {
      // For Android, use Google Play Store by default
      // You could support Amazon Appstore with a build flag
      StoreConfig(
        store: Store.playStore,
        apiKey: apiKey,
      );
    }
  }
}