// lib/utils/error_handler.dart

class ErrorHandler {
  // Generic error message mapping for Firebase Auth errors
  static String getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'requires-recent-login':
        return 'Please log in again to continue';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error';
    }
  }

  // Generic safe operation wrapper
  static Future<T?> safeOperation<T>(
    Future<T> Function() operation, {
    T? fallback,
    void Function(Object error)? onError,
  }) async {
    try {
      return await operation();
    } catch (e) {
      onError?.call(e);
      return fallback;
    }
  }

  // Generic void operation wrapper (for operations that don't return values)
  static Future<void> safeVoidOperation(
    Future<void> Function() operation, {
    void Function(Object error)? onError,
  }) async {
    try {
      await operation();
    } catch (e) {
      onError?.call(e);
    }
  }
}