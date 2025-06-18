// lib/blocs/auth/auth_bloc.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:tug/services/cache_service.dart';
import 'package:tug/services/subscription_service.dart';
import 'package:tug/services/service_locator.dart';
import 'package:tug/utils/error_handler.dart';
import '../../repositories/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SignUpEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const SignUpEvent({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class LogoutEvent extends AuthEvent {}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  const ForgotPasswordEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

class VerifyEmailEvent extends AuthEvent {}

class AuthStateChangedEvent extends AuthEvent {
  final User? user;

  const AuthStateChangedEvent(this.user);

  @override
  List<Object?> get props => [user];
}

class CheckAuthStatusEvent extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final bool emailVerified;

  const Authenticated(this.user, {this.emailVerified = false});

  @override
  List<Object?> get props => [user, emailVerified];
}

class Unauthenticated extends AuthState {}

class PasswordResetSent extends AuthState {
  final String email;

  const PasswordResetSent(this.email);

  @override
  List<Object?> get props => [email];
}

class EmailVerificationSent extends AuthState {
  const EmailVerificationSent();
}

class AuthError extends AuthState {
  final String message;
  final String code;

  const AuthError(this.message, {this.code = ''});

  @override
  List<Object?> get props => [message, code];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository authRepository;
  late final StreamSubscription<User?> _authSubscription;

  AuthBloc({
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<SignUpEvent>(_onSignUp);
    on<LogoutEvent>(_onLogout);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<VerifyEmailEvent>(_onVerifyEmail);
    on<AuthStateChangedEvent>(_onAuthStateChanged);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);

    // Listen to auth state changes
    _authSubscription = authRepository
        .authStateChanges()
        .listen((user) => add(AuthStateChangedEvent(user)), onError: (error) {
      add(LogoutEvent());
    });
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signIn(
        event.email,
        event.password,
      );

      if (user != null) {
        await _syncUserAfterAuth();
        emit(Authenticated(user, emailVerified: user.emailVerified));
      } else {
        emit(const AuthError('Login failed'));
      }
    } catch (e) {
      emit(_mapFirebaseErrorToAuthError(e));
    }
  }

  Future<void> _onSignUp(
    SignUpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signUp(
        event.name,
        event.email,
        event.password,
      );

      if (user != null) {
        await _syncUserAfterAuth();
        
        // Send email verification
        await authRepository.sendEmailVerification();

        emit(Authenticated(user, emailVerified: user.emailVerified));
      } else {
        emit(const AuthError('Sign up failed'));
      }
    } catch (e) {
      emit(_mapFirebaseErrorToAuthError(e));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Clear all cached data before signing out
      await _clearUserDataOnLogout();
      
      await authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(_mapFirebaseErrorToAuthError(e));
    }
  }

  /// Clear all user-specific cached data on logout
  Future<void> _clearUserDataOnLogout() async {
    await ErrorHandler.safeVoidOperation(
      () async {
        // Clear all cache service data
        await CacheService().clear();
        
        // Clear subscription service data (RevenueCat logout)
        await SubscriptionService().logoutUser();
      },
      onError: (error) {
        // Don't rethrow - logout should still proceed even if cache clearing fails
      },
    );
  }

  Future<void> _onForgotPassword(
    ForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.resetPassword(event.email);
      emit(PasswordResetSent(event.email));
    } catch (e) {
      emit(_mapFirebaseErrorToAuthError(e));
    }
  }

  Future<void> _onVerifyEmail(
    VerifyEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = authRepository.getCurrentUser();
      if (user != null && !user.emailVerified) {
        await authRepository.sendEmailVerification();
        emit(const EmailVerificationSent());
        emit(Authenticated(user, emailVerified: false));
      }
    } catch (e) {
      emit(_mapFirebaseErrorToAuthError(e));
    }
  }

  void _onAuthStateChanged(
    AuthStateChangedEvent event,
    Emitter<AuthState> emit,
  ) {
    final user = event.user;
    if (user != null) {
      emit(Authenticated(user, emailVerified: user.emailVerified));
    } else {
      // User signed out (could be due to token expiration, logout, etc.)
      // Clear cached data asynchronously without blocking the state change
      _clearUserDataOnLogout().catchError((e) {
      });
      emit(Unauthenticated());
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = authRepository.getCurrentUser();
      if (user != null) {
        // Check if token needs to be refreshed
        await user.getIdToken(true);
        emit(Authenticated(user, emailVerified: user.emailVerified));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(_mapFirebaseErrorToAuthError(e));
    }
  }

  // Helper method to sync user after authentication
  Future<void> _syncUserAfterAuth() async {
    await ErrorHandler.safeVoidOperation(
      () => ServiceLocator.apiService.syncUserWithMongoDB(),
      onError: (error) {
        // Log but don't fail if sync fails - authentication should still proceed
      },
    );
  }

  // Helper method to map Firebase errors to user-friendly messages
  AuthError _mapFirebaseErrorToAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      final message = ErrorHandler.getFirebaseAuthErrorMessage(error.code);
      return AuthError(
        error.message ?? message, 
        code: error.code
      );
    }
    return AuthError(error.toString());
  }
}
