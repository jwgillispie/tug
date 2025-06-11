// lib/services/cache_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service for caching data with both in-memory and persistent storage
class CacheService {
  // Singleton pattern
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // In-memory cache
  final Map<String, dynamic> _memoryCache = {};
  
  // Cache expiration timestamps
  final Map<String, DateTime> _expirations = {};
  
  // Default expiration durations
  static const Duration defaultMemoryCacheDuration = Duration(minutes: 5);
  static const Duration defaultDiskCacheDuration = Duration(hours: 24);
  
  // Cache initialization flag
  bool _initialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  // Get initialization future
  Future<void> get initialized => _initCompleter.future;

  // Initialize cache
  Future<void> initialize() async {
    if (!_initialized) {
      try {
        // Load persistent cache metadata
        final prefs = await SharedPreferences.getInstance();
        final expirationData = prefs.getString('cache_expirations');
        
        if (expirationData != null) {
          final Map<String, dynamic> expirations = jsonDecode(expirationData);
          expirations.forEach((key, value) {
            _expirations[key] = DateTime.parse(value);
          });
        }
        
        _initialized = true;
        _initCompleter.complete();
      } catch (e) {
        _initCompleter.completeError(e);
      }
    }
    
    return initialized;
  }

  // Get an item from cache
  Future<T?> get<T>(String key, {bool useMemoryOnly = false}) async {
    await initialized;
    
    // Check if key exists in memory cache and is not expired
    if (_memoryCache.containsKey(key)) {
      if (!_isExpired(key)) {
        return _memoryCache[key] as T?;
      } else {
        // Remove expired item
        _memoryCache.remove(key);
        _expirations.remove(key);
      }
    }
    
    // If not found in memory or memory-only mode, check persistent storage
    if (!useMemoryOnly) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('cache_$key');
      
      if (data != null && !_isExpired(key)) {
        try {
          final dynamic value = jsonDecode(data);
          
          // Cache in memory for faster future access
          _memoryCache[key] = value;
          
          return value as T?;
        } catch (e) {
          
          // Remove invalid data
          await prefs.remove('cache_$key');
        }
      } else if (data != null) {
        // Remove expired data
        await prefs.remove('cache_$key');
        _expirations.remove(key);
      }
    }
    
    // Not found or expired
    return null;
  }

  // Store an item in cache
  Future<void> set<T>(
    String key, 
    T value, {
    Duration? memoryCacheDuration,
    Duration? diskCacheDuration,
    bool persistToDisk = true,
  }) async {
    await initialized;
    
    final memoryExpiry = memoryCacheDuration ?? defaultMemoryCacheDuration;
    final diskExpiry = diskCacheDuration ?? defaultDiskCacheDuration;
    final expiryTime = DateTime.now().add(memoryExpiry);
    
    // Store in memory
    _memoryCache[key] = value;
    _expirations[key] = expiryTime;
    
    // Persist to disk if requested
    if (persistToDisk) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonData = jsonEncode(value);
        
        await prefs.setString('cache_$key', jsonData);
        
        // Update expiration timestamps in persistent storage
        final diskExpiryTime = DateTime.now().add(diskExpiry);
        _expirations[key] = diskExpiryTime;
        await _persistExpirations();
        
      } catch (e) {
      }
    } else {
    }
  }

  // Remove an item from cache
  Future<void> remove(String key) async {
    await initialized;
    
    _memoryCache.remove(key);
    _expirations.remove(key);
    
    // Remove from persistent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cache_$key');
    
    // Update expiration timestamps
    await _persistExpirations();
    
  }

  // Clear all cache
  Future<void> clear() async {
    await initialized;
    
    _memoryCache.clear();
    _expirations.clear();
    
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    // Remove all cache entries
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        await prefs.remove(key);
      }
    }
    
    // Clear expirations
    await prefs.remove('cache_expirations');
    
  }

  // Clear cache by prefix
  Future<void> clearByPrefix(String prefix) async {
    await initialized;
    
    // Remove from memory
    final memoryKeys = _memoryCache.keys.toList();
    for (final key in memoryKeys) {
      if (key.startsWith(prefix)) {
        _memoryCache.remove(key);
        _expirations.remove(key);
      }
    }
    
    // Remove from persistent storage
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith('cache_$prefix')) {
        await prefs.remove(key);
      }
    }
    
    // Update expirations
    await _persistExpirations();
    
  }

  // Check if an item is expired
  bool _isExpired(String key) {
    if (!_expirations.containsKey(key)) {
      return true;
    }
    
    return DateTime.now().isAfter(_expirations[key]!);
  }

  // Persist expiration timestamps
  Future<void> _persistExpirations() async {
    final prefs = await SharedPreferences.getInstance();
    
    final Map<String, String> expirationStrings = {};
    _expirations.forEach((key, value) {
      expirationStrings[key] = value.toIso8601String();
    });
    
    await prefs.setString('cache_expirations', jsonEncode(expirationStrings));
  }
}