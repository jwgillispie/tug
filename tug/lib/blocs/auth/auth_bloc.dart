// lib/blocs/auth/auth_bloc.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:tug/services/api_service.dart';
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
      debugPrint('Auth state stream error: $error');
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
      debugPrint('AuthBloc: Attempting login with ${event.email}');
      final user = await authRepository.signIn(
        event.email,
        event.password,
      );

      if (user != null) {
        debugPrint('AuthBloc: Login successful, syncing with MongoDB');
        // Sync with MongoDB after successful authentication
        try {
          final apiService = ApiService();
          final syncSuccess = await apiService.syncUserWithMongoDB();

          if (syncSuccess) {
            debugPrint('AuthBloc: MongoDB sync completed successfully');
          } else {
            debugPrint(
                'AuthBloc: MongoDB sync failed but continuing with login');
          }
        } catch (e) {
          // Log but don't fail if sync fails
          debugPrint('AuthBloc: MongoDB sync error: $e');
        }

        emit(Authenticated(user, emailVerified: user.emailVerified));
      } else {
        emit(const AuthError('Login failed'));
      }
    } catch (e) {
      debugPrint('AuthBloc: Login error: $e');
      emit(_mapFirebaseErrorToAuthError(e));
    }
  }

  Future<void> _onSignUp(
    SignUpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      debugPrint('AuthBloc: Starting sign up process');
      final user = await authRepository.signUp(
        event.name,
        event.email,
        event.password,
      );

      if (user != null) {
        debugPrint('AuthBloc: Signup successful, syncing with MongoDB');
        // Sync with MongoDB after successful signup
        try {
          final apiService = ApiService();
          final syncSuccess = await apiService.syncUserWithMongoDB();

          if (syncSuccess) {
            debugPrint('AuthBloc: MongoDB sync completed successfully');
          } else {
            debugPrint(
                'AuthBloc: MongoDB sync failed but continuing with signup flow');
          }
        } catch (e) {
          // Log but don't fail if sync fails
          debugPrint('AuthBloc: MongoDB sync error: $e');
        }

        // Send email verification
        await authRepository.sendEmailVerification();
        debugPrint('AuthBloc: Email verification sent');

        emit(Authenticated(user, emailVerified: user.emailVerified));
      } else {
        emit(const AuthError('Sign up failed'));
      }
    } catch (e) {
      debugPrint('AuthBloc: Sign up error caught: $e');
      emit(_mapFirebaseErrorToAuthError(e));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(_mapFirebaseErrorToAuthError(e));
    }
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
    debugPrint(
        'AuthBloc: Auth state changed: ${event.user?.uid ?? 'Not authenticated'}');
    final user = event.user;
    if (user != null) {
      emit(Authenticated(user, emailVerified: user.emailVerified));
    } else {
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

  // Helper method to map Firebase errors to user-friendly messages
  AuthError _mapFirebaseErrorToAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return AuthError('No user found with this email', code: error.code);
        case 'wrong-password':
          return AuthError('Incorrect password', code: error.code);
        case 'email-already-in-use':
          return AuthError('This email is already registered',
              code: error.code);
        case 'weak-password':
          return AuthError('Password is too weak. Use at least 6 characters.',
              code: error.code);
        case 'invalid-email':
          return AuthError('Invalid email format', code: error.code);
        case 'user-disabled':
          return AuthError('This account has been disabled', code: error.code);
        case 'requires-recent-login':
          return AuthError('Please log in again to continue', code: error.code);
        case 'too-many-requests':
          return AuthError('Too many attempts. Please try again later.',
              code: error.code);
        default:
          return AuthError(error.message ?? 'Authentication error',
              code: error.code);
      }
    }
    return AuthError(error.toString());
  }
}
