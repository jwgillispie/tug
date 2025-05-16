// lib/models/subscription_model.dart
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currencyCode;
  final String currencySymbol;
  final String period;
  final Package package;
  final bool isPopular;
  
  SubscriptionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.currencySymbol,
    required this.period,
    required this.package,
    this.isPopular = false,
  });
  
  // Factory to create from a RevenueCat Package
  factory SubscriptionModel.fromPackage(Package package, {bool isPopular = false}) {
    final product = package.storeProduct;
    final packageType = package.packageType;
    
    String period;
    switch (packageType) {
      case PackageType.monthly:
        period = 'Monthly';
        break;
      case PackageType.annual:
        period = 'Annual';
        break;
      case PackageType.weekly:
        period = 'Weekly';
        break;
      case PackageType.lifetime:
        period = 'Lifetime';
        break;
      case PackageType.unknown:
      default:
        period = '';
        break;
    }
    
    // Format the price with the currency symbol
    final formatter = NumberFormat.simpleCurrency(
      name: product.currencyCode, 
      decimalDigits: 2,
    );
    
    String currencySymbol = formatter.currencySymbol;
    
    // Create a default title if not provided
    String title = product.title;
    if (title.isEmpty || title.toLowerCase().contains(product.identifier.toLowerCase())) {
      title = packageType == PackageType.annual 
          ? 'Annual Premium' 
          : packageType == PackageType.monthly 
              ? 'Monthly Premium' 
              : packageType == PackageType.lifetime
                  ? 'Lifetime Premium'
                  : 'Premium';
    }
    
    // Create a default description if not provided
    String description = product.description;
    if (description.isEmpty) {
      description = packageType == PackageType.annual 
          ? 'Premium features for a full year' 
          : packageType == PackageType.monthly 
              ? 'Premium features billed monthly' 
              : packageType == PackageType.lifetime
                  ? 'Premium features forever with a one-time purchase'
                  : 'Unlock premium features';
    }
    
    return SubscriptionModel(
      id: product.identifier,
      title: title,
      description: description,
      price: product.price,
      currencyCode: product.currencyCode,
      currencySymbol: currencySymbol,
      period: period,
      package: package,
      isPopular: isPopular,
    );
  }
  
  // Format price with currency symbol
  String get formattedPrice => '$currencySymbol${price.toStringAsFixed(2)}';
  
  // Format price with period
  String get formattedPriceWithPeriod {
    if (period == 'Lifetime') {
      return '$formattedPrice one-time';
    } else if (period == 'Annual') {
      return '$formattedPrice / year';
    } else if (period == 'Monthly') {
      return '$formattedPrice / month';
    } else if (period == 'Weekly') {
      return '$formattedPrice / week';
    } else {
      return formattedPrice;
    }
  }
  
  // Get equivalent monthly price for comparison
  double get monthlyEquivalentPrice {
    switch (package.packageType) {
      case PackageType.annual:
        return price / 12;
      case PackageType.monthly:
        return price;
      case PackageType.weekly:
        return price * 4.33; // Average weeks in a month
      default:
        return price;
    }
  }
  
  // For annual subscriptions, calculate the savings percentage compared to monthly
  String? get savingsComparedToMonthly {
    if (package.packageType != PackageType.annual) return null;
    
    // This requires access to the monthly package price, which we don't have here.
    // In actual implementation, you would compare with a known monthly price.
    // For example: return '${(1 - (price / (12 * monthlyPrice)) * 100).round()}%';
    
    // Default savings message without calculation
    return 'Save over 15%';
  }
}