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
    // In web or testing environments, we can use a debug flag to simulate premium
    if (kIsWeb) {
      // For web testing, return true 50% of the time
      return false; // Change to true to test premium features
    }
    
    if (_customerInfo == null) return false;
    
    final entitlementId = EnvConfig.revenueCatPremiumEntitlementId;
    return _customerInfo!.entitlements.active.containsKey(entitlementId);
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
    
    if (kIsWeb) {
      _subscriptionStatusController.add(true); // Simulate purchase success
      return true;
    }
    
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      _handleCustomerInfoUpdate(customerInfo);
      return true;
    } catch (e) {
      // Store the error message
      _lastPurchaseError = e.toString();
      
      if (e.toString().contains('USER_CANCELLED') || 
          e.toString().contains('PURCHASE_CANCELLED') ||
          e.toString().contains('userCancelled: true')) {
        // User cancelled the purchase - no need to show error
      } else {
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
      return true;
    }
    
    try {
      final loginResult = await Purchases.logIn(userId);
      _handleCustomerInfoUpdate(loginResult.customerInfo);
      await Purchases.appUserID;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Log out the current user
  /// This will create a new anonymous user
  Future<bool> logoutUser() async {
    if (!_isInitialized) await initialize();
    
    if (kIsWeb) {
      return true;
    }
    
    try {
      // Clear internal state first
      _customerInfo = null;
      _lastPurchaseError = null;
      
      await Purchases.logOut();
      final customerInfo = await Purchases.getCustomerInfo();
      _handleCustomerInfoUpdate(customerInfo);
      await Purchases.appUserID;
      return true;
    } catch (e) {
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
    if (kIsWeb) {
      // For web testing, return false by default
      return false; // Change to true to test specific entitlements
    }
    
    if (_customerInfo == null) return false;
    return _customerInfo!.entitlements.active.containsKey(entitlementId);
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
    
    if (kIsWeb) return false;
    
    try {
      // First try to restore purchases to ensure latest state
      await restorePurchases();
      
      // Check for any active subscriptions
      if (_customerInfo != null && _customerInfo!.activeSubscriptions.isNotEmpty) {
        return true;
      }
      
      // No legacy purchases found that need migration
      return false;
    } catch (e) {
      return false;
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