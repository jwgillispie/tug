// lib/blocs/subscription/subscription_bloc.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tug/models/subscription_model.dart';
import 'package:tug/services/subscription_service.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubscriptions extends SubscriptionEvent {}

class PurchaseSubscription extends SubscriptionEvent {
  final SubscriptionModel subscription;

  const PurchaseSubscription(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

class RestorePurchases extends SubscriptionEvent {}

// States
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionsLoaded extends SubscriptionState {
  final List<SubscriptionModel> subscriptions;
  final bool isPremium;

  const SubscriptionsLoaded({
    required this.subscriptions,
    required this.isPremium,
  });

  @override
  List<Object?> get props => [subscriptions, isPremium];
}

class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
}

class PurchaseInProgress extends SubscriptionState {}

class PurchaseSuccess extends SubscriptionState {
  final SubscriptionModel subscription;

  const PurchaseSuccess(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

class PurchaseError extends SubscriptionState {
  final String message;

  const PurchaseError(this.message);

  @override
  List<Object?> get props => [message];
}

class RestoringPurchases extends SubscriptionState {}

class PurchasesRestored extends SubscriptionState {
  final bool hasPremium;

  const PurchasesRestored({required this.hasPremium});

  @override
  List<Object?> get props => [hasPremium];
}

// BLoC
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionService _subscriptionService;
  StreamSubscription? _subscriptionStatusSubscription;

  SubscriptionBloc({SubscriptionService? subscriptionService})
      : _subscriptionService = subscriptionService ?? SubscriptionService(),
        super(SubscriptionInitial()) {
    on<LoadSubscriptions>(_onLoadSubscriptions);
    on<PurchaseSubscription>(_onPurchaseSubscription);
    on<RestorePurchases>(_onRestorePurchases);

    // Initialize the subscription service
    _subscriptionService.initialize();

    // Listen to subscription status changes
    _subscriptionStatusSubscription = _subscriptionService.onSubscriptionStatusChanged
        .listen((_) {
      // When subscription status changes, reload subscriptions
      add(LoadSubscriptions());
    });
  }

  Future<void> _onLoadSubscriptions(
    LoadSubscriptions event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());

    try {
      final offering = await _subscriptionService.getDefaultOffering();
      
      if (offering == null) {
        emit(const SubscriptionError('No subscription offerings available'));
        return;
      }

      // Convert packages to subscription models
      final subscriptions = <SubscriptionModel>[];
      
      // Add annual package (mark as popular if available)
      final annualPackage = offering.annual;
      if (annualPackage != null) {
        subscriptions.add(
          SubscriptionModel.fromPackage(annualPackage, isPopular: true),
        );
      }
      
      // Add monthly package
      final monthlyPackage = offering.monthly;
      if (monthlyPackage != null) {
        subscriptions.add(
          SubscriptionModel.fromPackage(monthlyPackage),
        );
      }
      
      // Add other packages
      for (final package in offering.availablePackages) {
        // Skip packages we've already added
        if ((package.packageType == PackageType.annual && annualPackage != null) ||
            (package.packageType == PackageType.monthly && monthlyPackage != null)) {
          continue;
        }
        
        subscriptions.add(SubscriptionModel.fromPackage(package));
      }

      // Sort by price (lifetime first, then descending by length)
      subscriptions.sort((a, b) {
        if (a.package.packageType == PackageType.lifetime) return -1;
        if (b.package.packageType == PackageType.lifetime) return 1;
        
        // Compare by period length (annual first, then monthly, etc.)
        if (a.package.packageType == PackageType.annual &&
            b.package.packageType != PackageType.annual) {
          return -1;
        }
        if (a.package.packageType != PackageType.annual &&
            b.package.packageType == PackageType.annual) {
          return 1;
        }
        
        // Fall back to price comparison (higher prices first)
        return b.price.compareTo(a.price);
      });

      emit(SubscriptionsLoaded(
        subscriptions: subscriptions,
        isPremium: _subscriptionService.isPremium,
      ));
    } catch (e) {
      emit(SubscriptionError('Failed to load subscriptions: $e'));
    }
  }

  Future<void> _onPurchaseSubscription(
    PurchaseSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(PurchaseInProgress());

    try {
      final success = await _subscriptionService.purchasePackage(
        event.subscription.package,
      );

      if (success) {
        emit(PurchaseSuccess(event.subscription));
        // After a successful purchase, reload the subscriptions
        add(LoadSubscriptions());
      } else {
        // Check if this is a cancellation
        final cancelError = _subscriptionService.lastPurchaseError;
        final isCancelled = cancelError != null && (
            cancelError.contains('cancel') || 
            cancelError.contains('user cancelled') ||
            cancelError.contains('purchase_cancelled') ||
            cancelError.contains('userCancelled: true')
        );
        
        if (isCancelled) {
          // For cancellations, emit a specific state
          emit(PurchaseError('Purchase was cancelled.'));
        } else {
          emit(const PurchaseError('Purchase was not completed'));
        }
      }
    } catch (e) {
      // Check if this is a cancellation error
      final errorMsg = e.toString().toLowerCase();
      final isCancelled = errorMsg.contains('cancel') || 
                          errorMsg.contains('user cancelled') ||
                          errorMsg.contains('purchase_cancelled') ||
                          errorMsg.contains('usercancelled: true');
      
      if (isCancelled) {
        emit(PurchaseError('Purchase was cancelled.'));
      } else {
        emit(PurchaseError('Failed to make purchase: $e'));
      }
    }
  }

  Future<void> _onRestorePurchases(
    RestorePurchases event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(RestoringPurchases());

    try {
      final success = await _subscriptionService.restorePurchases();
      
      emit(PurchasesRestored(
        hasPremium: _subscriptionService.isPremium,
      ));
      
      // After restoration, reload subscriptions
      add(LoadSubscriptions());
    } catch (e) {
      emit(SubscriptionError('Failed to restore purchases: $e'));
    }
  }

  @override
  Future<void> close() {
    _subscriptionStatusSubscription?.cancel();
    return super.close();
  }
}