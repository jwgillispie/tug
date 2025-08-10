// lib/services/subscription_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tug/config/env_confg.dart';
import 'package:tug/services/store_config.dart';

/// Service that handles all subscription and in-app purchase interactions
/// using RevenueCat's Purchases SDK.
class SubscriptionService {
  // Singleton pattern
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isInitialized = false;
  CustomerInfo? _customerInfo;
  String? _lastPurchaseError;
  bool _isOnline = true;
  DateTime? _lastSuccessfulSync;
  
  // Controller for subscription status changes
  final _subscriptionStatusController = StreamController<bool>.broadcast();
  
  /// Stream that emits when premium status changes
  Stream<bool> get onSubscriptionStatusChanged => 
      _subscriptionStatusController.stream;
      
  /// Get the last purchase error message
  String? get lastPurchaseError => _lastPurchaseError;
  
  /// Initialize the subscription service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Handle web or unsupported platforms
      if (kIsWeb) {
        _isInitialized = true;
        return;
      }
      
      // Initialize the store configuration
      StoreConfig.initialize();
      
      // Set log level for debugging
      try {
        await Purchases.setLogLevel(LogLevel.debug);
      } catch (e) {
        if (e is MissingPluginException) {
          _isInitialized = true;
          return;
        }
        rethrow;
      }
      
      // Create the proper configuration based on platform
      PurchasesConfiguration configuration;
      
      try {
        if (StoreConfig.isForAmazonAppstore()) {
          configuration = AmazonConfiguration(StoreConfig.instance.apiKey)
            ..appUserID = null // Let RevenueCat generate an anonymous ID
            ..purchasesAreCompletedBy = const PurchasesAreCompletedByRevenueCat();
        } else {
          configuration = PurchasesConfiguration(StoreConfig.instance.apiKey)
            ..appUserID = null // Let RevenueCat generate an anonymous ID
            ..purchasesAreCompletedBy = const PurchasesAreCompletedByRevenueCat();
        }
        
        // Configure the SDK
        await Purchases.configure(configuration);
        
        // Get the anonymous user ID (useful to display to users)
        await Purchases.appUserID;
        
        // Fetch initial customer info
        final customerInfo = await Purchases.getCustomerInfo();
        _handleCustomerInfoUpdate(customerInfo);
        
        // Listen for customer info updates
        Purchases.addCustomerInfoUpdateListener(_handleCustomerInfoUpdate);
        
        _isInitialized = true;
      } catch (e) {
        _isInitialized = true; // Mark as initialized to prevent retry loops
      }
    } catch (e) {
      _isInitialized = true;
    }
  }
  
  /// Handles customer info updates and notifies listeners
  void _handleCustomerInfoUpdate(CustomerInfo info) {
    final oldPremiumStatus = isPremium;
    _customerInfo = info;
    
    // Debug logging
    
    // Check if premium status changed and notify listeners
    if (oldPremiumStatus != isPremium) {
      _subscriptionStatusController.add(isPremium);
    }
  }
  
  /// Check if the user has premium access
  bool get isPremium {
    // For web platforms, we need to check if there's a valid customer info
    // and active entitlements. Web purchases should still work through RevenueCat's web support
    if (kIsWeb) {
      // If we have customer info from a previous session or successful sync
      if (_customerInfo != null) {
        final entitlementId = EnvConfig.revenueCatPremiumEntitlementId;
        return _customerInfo!.entitlements.active.containsKey(entitlementId);
      }
      // Default to false for web if no customer info available
      return false;
    }
    
    if (_customerInfo == null) return false;
    
    final entitlementId = EnvConfig.revenueCatPremiumEntitlementId;
    final hasActiveEntitlement = _customerInfo!.entitlements.active.containsKey(entitlementId);
    
    // Additional validation: check if the entitlement is not expired
    if (hasActiveEntitlement) {
      final entitlement = _customerInfo!.entitlements.active[entitlementId];
      if (entitlement != null) {
        // Check if the entitlement is still active (not expired)
        return entitlement.isActive;
      }
    }
    
    return false;
  }
  
  /// Get active subscriptions for the user
  Set<String> get activeSubscriptions {
    return _customerInfo?.activeSubscriptions.toSet() ?? <String>{};
  }
  
  /// Get available offerings from RevenueCat
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) await initialize();
    
    // If on web or plugin not available, return mock data for testing
    if (kIsWeb) {
      return null;
    }
    
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      return null;
    }
  }
  
  /// Get the default offering
  Future<Offering?> getDefaultOffering() async {
    if (kIsWeb) {
      return null;
    }
    
    final offerings = await getOfferings();
    if (offerings == null) return null;
    
    final offeringId = EnvConfig.revenueCatOfferingId;
    return offerings.current ?? offerings.getOffering(offeringId);
  }
  
  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    if (!_isInitialized) await initialize();
    
    // Reset last error
    _lastPurchaseError = null;
    
    // Check network connectivity first
    if (!await _checkNetworkConnectivity()) {
      _lastPurchaseError = 'No network connection. Please check your internet and try again.';
      return false;
    }
    
    if (kIsWeb) {
      // For web, we should attempt to make a real purchase if RevenueCat supports it
      // or return false to indicate web purchases aren't supported yet
      _lastPurchaseError = 'Web purchases are not yet supported. Please use the mobile app.';
      return false;
    }
    
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      _handleCustomerInfoUpdate(customerInfo);
      _lastSuccessfulSync = DateTime.now();
      _isOnline = true;
      return true;
    } catch (e) {
      // Store the error message
      _lastPurchaseError = e.toString();
      
      // Handle specific error cases
      if (e.toString().contains('USER_CANCELLED') || 
          e.toString().contains('PURCHASE_CANCELLED') ||
          e.toString().contains('userCancelled: true')) {
        // User cancelled the purchase - no need to show error
        _lastPurchaseError = null; // Clear error for cancellations
      } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
        _lastPurchaseError = 'Network error. Please check your connection.';
        _isOnline = false;
      } else if (e.toString().contains('ITEM_ALREADY_OWNED')) {
        _lastPurchaseError = 'You already own this subscription. Try restoring purchases.';
      } else {
        _lastPurchaseError = 'Purchase failed. Please try again later.';
      }
      return false;
    }
  }
  
  /// Restore purchases
  Future<bool> restorePurchases() async {
    if (!_isInitialized) await initialize();
    
    if (kIsWeb) {
      return false;
    }
    
    try {
      final customerInfo = await Purchases.restorePurchases();
      _handleCustomerInfoUpdate(customerInfo);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Log in a user with a specific user ID
  /// This allows syncing purchases across devices
  Future<bool> loginUser(String userId) async {
    if (!_isInitialized) await initialize();
    
    if (kIsWeb) {
      // For web, we should still attempt to identify the user
      // even if purchases aren't fully supported
      try {
        final loginResult = await Purchases.logIn(userId);
        _handleCustomerInfoUpdate(loginResult.customerInfo);
        _lastSuccessfulSync = DateTime.now();
        return true;
      } catch (e) {
        return false;
      }
    }
    
    try {
      final loginResult = await Purchases.logIn(userId);
      _handleCustomerInfoUpdate(loginResult.customerInfo);
      await Purchases.appUserID;
      _lastSuccessfulSync = DateTime.now();
      _isOnline = true;
      return true;
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        _isOnline = false;
      }
      return false;
    }
  }
  
  /// Log out the current user
  /// This will create a new anonymous user
  Future<bool> logoutUser() async {
    if (!_isInitialized) await initialize();
    
    try {
      // Clear internal state first
      _customerInfo = null;
      _lastPurchaseError = null;
      _lastSuccessfulSync = null;
      
      if (kIsWeb) {
        // For web, clear the user and create a new anonymous session
        await Purchases.logOut();
        final customerInfo = await Purchases.getCustomerInfo();
        _handleCustomerInfoUpdate(customerInfo);
        return true;
      }
      
      await Purchases.logOut();
      final customerInfo = await Purchases.getCustomerInfo();
      _handleCustomerInfoUpdate(customerInfo);
      await Purchases.appUserID;
      _isOnline = true;
      return true;
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        _isOnline = false;
      }
      return false;
    }
  }
  
  /// Get the current app user ID
  Future<String> getCurrentUserID() async {
    if (!_isInitialized) await initialize();
    
    if (kIsWeb) {
      return 'web-user-id';
    }
    
    try {
      return await Purchases.appUserID;
    } catch (e) {
      return '';
    }
  }
  
  /// Check if the current user is anonymous
  Future<bool> isAnonymousUser() async {
    final userId = await getCurrentUserID();
    return userId.contains('RCAnonymousID:');
  }
  
  /// Check if a specific entitlement is active
  bool hasEntitlement(String entitlementId) {
    if (_customerInfo == null) return false;
    
    final hasActiveEntitlement = _customerInfo!.entitlements.active.containsKey(entitlementId);
    
    // Additional validation: check if the entitlement is not expired and is active
    if (hasActiveEntitlement) {
      final entitlement = _customerInfo!.entitlements.active[entitlementId];
      if (entitlement != null) {
        // Check if the entitlement is active and not expired
        return entitlement.isActive;
      }
    }
    
    return false;
  }
  
  /// Get the premium entitlement info
  EntitlementInfo? get premiumEntitlement {
    if (kIsWeb || _customerInfo == null) return null;
    
    final entitlementId = EnvConfig.revenueCatPremiumEntitlementId;
    return _customerInfo!.entitlements.all[entitlementId];
  }
  
  /// Check if user has legacy purchases that need migration
  /// This is useful when transitioning from IAP to subscription model
  Future<bool> checkForLegacyPurchases() async {
    if (!_isInitialized) await initialize();
    
    try {
      // First try to restore purchases to ensure latest state
      await restorePurchases();
      
      // Check for any active subscriptions or entitlements
      if (_customerInfo != null) {
        final hasActiveSubscriptions = _customerInfo!.activeSubscriptions.isNotEmpty;
        final hasActiveEntitlements = _customerInfo!.entitlements.active.isNotEmpty;
        
        return hasActiveSubscriptions || hasActiveEntitlements;
      }
      
      // No legacy purchases found that need migration
      return false;
    } catch (e) {
      // If we can't check, assume false to be safe
      return false;
    }
  }
  
  /// Check network connectivity
  Future<bool> _checkNetworkConnectivity() async {
    try {
      // Simple connectivity check - in production you might want to use connectivity_plus
      // For now, we'll assume network is available unless we get network errors
      return true;
    } catch (e) {
      _isOnline = false;
      return false;
    }
  }
  
  /// Get network status
  bool get isOnline => _isOnline;
  
  /// Get last successful sync time
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;
  
  /// Force refresh subscription status from RevenueCat
  Future<bool> refreshSubscriptionStatus() async {
    if (!_isInitialized) await initialize();
    
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _handleCustomerInfoUpdate(customerInfo);
      _lastSuccessfulSync = DateTime.now();
      _isOnline = true;
      return true;
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        _isOnline = false;
      }
      return false;
    }
  }
  
  /// Check if subscription data is stale (older than 1 hour)
  bool get isDataStale {
    if (_lastSuccessfulSync == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastSuccessfulSync!);
    return difference.inHours >= 1;
  }
  
  /// Get subscription status with staleness information
  SubscriptionStatus getSubscriptionStatus() {
    final premium = isPremium;
    final stale = isDataStale;
    final online = _isOnline;
    
    if (!premium && stale && !online) {
      return SubscriptionStatus.unknown; // Can't verify due to network issues
    } else if (premium) {
      return SubscriptionStatus.premium;
    } else {
      return SubscriptionStatus.free;
    }
  }

  /// Clean up resources
  void dispose() {
    try {
      if (_isInitialized && !kIsWeb) {
        Purchases.removeCustomerInfoUpdateListener(_handleCustomerInfoUpdate);
      }
    } catch (e) {
      // Error removing listener - continue with cleanup
    } finally {
      _subscriptionStatusController.close();
    }
  }
}

/// Enum for subscription status with uncertainty handling
enum SubscriptionStatus {
  premium,
  free,
  unknown, // When we can't verify due to network issues or stale data
}