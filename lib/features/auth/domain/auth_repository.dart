// =============================================================================
// AUTH REPOSITORY CONTRACT
// =============================================================================
// Domain-level interface for authentication operations.
//
// This file defines:
//   - AuthUser: Domain model for authenticated user
//   - AuthFailure: Sealed class for domain-specific failures
//   - AuthRepository: Abstract interface for auth operations
//
// No implementation details, no SDK types, no Flutter UI dependencies.
// =============================================================================

// =============================================================================
// DOMAIN MODEL
// =============================================================================

/// Authenticated user domain model.
///
/// This is a pure domain representation - no SDK types or platform specifics.
class AuthUser {
  /// Unique identifier for the user.
  final String id;

  /// User's email address.
  final String email;

  /// User's display name (may be null if not provided).
  final String? displayName;

  /// URL to user's profile photo (may be null).
  final String? photoUrl;

  /// How the user authenticated.
  final AuthMethod authMethod;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.authMethod,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() =>
      'AuthUser(id: $id, email: $email, displayName: $displayName)';

  /// Creates a copy with updated fields.
  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    AuthMethod? authMethod,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      authMethod: authMethod ?? this.authMethod,
    );
  }
}

/// Authentication method used to sign in.
enum AuthMethod {
  /// Email and password authentication.
  emailPassword,

  /// Google OAuth authentication.
  google,

  /// Apple Sign In authentication.
  apple,
}

// =============================================================================
// FAILURE TYPES
// =============================================================================

/// Domain-specific authentication failures.
///
/// Sealed class ensures exhaustive handling of all failure cases.
/// Each failure type includes a human-readable message.
sealed class AuthFailure implements Exception {
  /// Human-readable error message suitable for display.
  String get message;
}

/// Invalid email or password during sign in.
class InvalidCredentials extends AuthFailure {
  @override
  String get message => 'Invalid email or password. Please try again.';
}

/// Email format is invalid.
class InvalidEmail extends AuthFailure {
  @override
  String get message => 'Please enter a valid email address.';
}

/// Password does not meet requirements.
class WeakPassword extends AuthFailure {
  @override
  String get message =>
      'Password must be at least 8 characters with at least 1 number.';
}

/// Account already exists with this email.
class EmailAlreadyInUse extends AuthFailure {
  @override
  String get message => 'An account with this email already exists.';
}

/// No account found with provided email.
class UserNotFound extends AuthFailure {
  @override
  String get message => 'No account found with this email.';
}

/// Network connectivity issue.
class NetworkError extends AuthFailure {
  @override
  String get message =>
      'Network error. Please check your connection and try again.';
}

/// User cancelled the authentication flow.
class AuthCancelled extends AuthFailure {
  @override
  String get message => 'Sign in was cancelled.';
}

/// Too many failed attempts, temporarily blocked.
class TooManyRequests extends AuthFailure {
  @override
  String get message =>
      'Too many attempts. Please wait a moment and try again.';
}

/// Google Sign In is not available.
class GoogleSignInUnavailable extends AuthFailure {
  @override
  String get message =>
      'Google sign in is currently unavailable. Please try another method.';
}

/// Apple Sign In is not available on this device.
class AppleSignInUnavailable extends AuthFailure {
  @override
  String get message => 'Apple sign in is not available on this device.';
}

/// User account has been disabled.
class UserDisabled extends AuthFailure {
  @override
  String get message =>
      'This account has been disabled. Please contact support.';
}

/// Operation not allowed (e.g., sign-in method disabled).
class OperationNotAllowed extends AuthFailure {
  @override
  String get message => 'This sign in method is not enabled.';
}

/// Unknown or unexpected error.
class UnknownAuthFailure extends AuthFailure {
  final String? details;

  UnknownAuthFailure([this.details]);

  @override
  String get message => 'An unexpected error occurred. Please try again.';

  @override
  String toString() => 'UnknownAuthFailure(details: $details)';
}

// =============================================================================
// REPOSITORY INTERFACE
// =============================================================================

/// Abstract interface for authentication operations.
///
/// Implementations may use Firebase, Supabase, custom backend, etc.
/// All methods are async and throw [AuthFailure] on error.
///
/// ## Usage
///
/// ```dart
/// class FirebaseAuthRepository implements AuthRepository {
///   // Implementation...
/// }
///
/// final authRepo = FirebaseAuthRepository();
/// try {
///   final user = await authRepo.signInWithEmail(
///     email: 'user@example.com',
///     password: 'password123',
///   );
/// } on AuthFailure catch (e) {
///   print(e.message);
/// }
/// ```
abstract interface class AuthRepository {
  /// Signs up a new user with email and password.
  ///
  /// Throws:
  /// - [InvalidEmail] if email format is invalid
  /// - [WeakPassword] if password doesn't meet requirements
  /// - [EmailAlreadyInUse] if account already exists
  /// - [NetworkError] if no network connection
  /// - [UnknownAuthFailure] for unexpected errors
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Signs in an existing user with email and password.
  ///
  /// Throws:
  /// - [InvalidCredentials] if email/password is wrong
  /// - [UserNotFound] if no account exists
  /// - [UserDisabled] if account is disabled
  /// - [TooManyRequests] if too many failed attempts
  /// - [NetworkError] if no network connection
  /// - [UnknownAuthFailure] for unexpected errors
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Signs in using Google authentication.
  ///
  /// Throws:
  /// - [AuthCancelled] if user cancels the flow
  /// - [GoogleSignInUnavailable] if Google services unavailable
  /// - [NetworkError] if no network connection
  /// - [UnknownAuthFailure] for unexpected errors
  Future<AuthUser> signInWithGoogle();

  /// Signs in using Apple authentication.
  ///
  /// Throws:
  /// - [AuthCancelled] if user cancels the flow
  /// - [AppleSignInUnavailable] if not supported on device
  /// - [NetworkError] if no network connection
  /// - [UnknownAuthFailure] for unexpected errors
  Future<AuthUser> signInWithApple();

  /// Signs out the current user.
  ///
  /// Throws:
  /// - [NetworkError] if sign out requires network and fails
  /// - [UnknownAuthFailure] for unexpected errors
  Future<void> signOut();

  /// Returns the currently authenticated user, or null if not signed in.
  ///
  /// This method should not throw - returns null on any error.
  Future<AuthUser?> getCurrentUser();

  /// Stream of authentication state changes.
  ///
  /// Emits the current user when signed in, null when signed out.
  /// Useful for listening to auth state in the app.
  Stream<AuthUser?> get authStateChanges;
}
