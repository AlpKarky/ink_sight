import '../models/user.dart';

/// Abstract contract for authentication operations.
///
/// This repository defines the interface for all authentication methods.
/// Implementations can use Firebase, Supabase, custom backend, etc.
///
/// All methods throw [AuthException] on failure.
abstract class AuthRepository {
  /// Signs up a new user with email and password.
  ///
  /// Throws [AuthException] if:
  /// - Email is already in use
  /// - Email format is invalid
  /// - Password doesn't meet requirements
  /// - Network error occurs
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Signs in an existing user with email and password.
  ///
  /// Throws [AuthException] if:
  /// - User not found
  /// - Password is incorrect
  /// - Network error occurs
  Future<User> signInWithEmail({
    required String email,
    required String password,
  });

  /// Signs in with Google authentication.
  ///
  /// Throws [AuthException] if:
  /// - User cancels the sign-in flow
  /// - Google services unavailable
  /// - Network error occurs
  Future<User> signInWithGoogle();

  /// Signs in with Apple authentication.
  ///
  /// Throws [AuthException] if:
  /// - User cancels the sign-in flow
  /// - Apple services unavailable
  /// - Network error occurs
  /// - Not available on current platform
  Future<User> signInWithApple();

  /// Signs out the current user.
  ///
  /// Throws [AuthException] if sign out fails.
  Future<void> signOut();

  /// Returns the currently authenticated user, if any.
  Future<User?> getCurrentUser();
}

/// Exception thrown by [AuthRepository] operations.
///
/// Contains a [code] for programmatic handling and a [message]
/// suitable for display to users.
class AuthException implements Exception {
  final AuthErrorCode code;
  final String message;

  const AuthException({required this.code, required this.message});

  @override
  String toString() => 'AuthException($code): $message';
}

/// Error codes for authentication failures.
///
/// Used for programmatic error handling and mapping to user-friendly messages.
enum AuthErrorCode {
  // Email/Password errors
  invalidEmail,
  weakPassword,
  emailAlreadyInUse,
  userNotFound,
  wrongPassword,
  invalidCredentials,

  // Social sign-in errors
  socialSignInCancelled,
  socialSignInFailed,
  googleSignInUnavailable,
  appleSignInUnavailable,
  appleSignInNotSupported,

  // General errors
  networkError,
  tooManyRequests,
  operationNotAllowed,
  unknown,
}

/// Maps error codes to human-readable messages.
///
/// These messages are suitable for display to end users.
String getHumanReadableAuthError(AuthErrorCode code) {
  return switch (code) {
    AuthErrorCode.invalidEmail => 'Please enter a valid email address.',
    AuthErrorCode.weakPassword =>
      'Password must be at least 8 characters with at least 1 number.',
    AuthErrorCode.emailAlreadyInUse =>
      'An account with this email already exists.',
    AuthErrorCode.userNotFound =>
      'No account found with this email. Please sign up first.',
    AuthErrorCode.wrongPassword => 'Incorrect password. Please try again.',
    AuthErrorCode.invalidCredentials =>
      'Invalid email or password. Please check your credentials.',
    AuthErrorCode.socialSignInCancelled => 'Sign in was cancelled.',
    AuthErrorCode.socialSignInFailed => 'Sign in failed. Please try again.',
    AuthErrorCode.googleSignInUnavailable =>
      'Google sign in is currently unavailable. Please try another method.',
    AuthErrorCode.appleSignInUnavailable =>
      'Apple sign in is currently unavailable. Please try another method.',
    AuthErrorCode.appleSignInNotSupported =>
      'Apple sign in is not available on this device.',
    AuthErrorCode.networkError =>
      'Network error. Please check your connection and try again.',
    AuthErrorCode.tooManyRequests =>
      'Too many attempts. Please wait a moment and try again.',
    AuthErrorCode.operationNotAllowed =>
      'This sign in method is not enabled. Please contact support.',
    AuthErrorCode.unknown => 'An unexpected error occurred. Please try again.',
  };
}
