// =============================================================================
// AUTH CONTROLLER
// =============================================================================
// State machine for authentication operations.
//
// STATE TRANSITIONS:
// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │   ┌──────┐      ┌─────────┐      ┌─────────┐                              │
// │   │ Idle │─────▶│ Loading │─────▶│ Success │                              │
// │   └──────┘      └────┬────┘      └────┬────┘                              │
// │       ▲              │                │                                   │
// │       │              ▼                │                                   │
// │       │         ┌─────────┐           │                                   │
// │       └─────────│  Error  │◀──────────┘  (via Loading)                    │
// │    (sign out)   └─────────┘                                               │
// │                                                                           │
// │   Valid transitions:                                                      │
// │   • Idle/Success/Error → Loading (start operation)                        │
// │   • Loading → Success (auth succeeded)                                    │
// │   • Loading → Idle (sign out succeeded)                                   │
// │   • Loading → Error (operation failed)                                    │
// │                                                                           │
// │   Blocked:                                                                │
// │   • Loading → Loading (ignored, prevents double-submit)                   │
// │   • Any → Any (after disposal)                                            │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘
//
// =============================================================================

import 'domain/auth_repository.dart';

// =============================================================================
// AUTH STATES
// =============================================================================

/// Auth state - sealed class for exhaustive pattern matching.
sealed class AuthState {
  const AuthState();
}

/// Initial state. No user is authenticated.
class AuthIdle extends AuthState {
  const AuthIdle();
}

/// An authentication operation is in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authentication succeeded. Contains the authenticated user.
class AuthSuccess extends AuthState {
  final AuthUser user;
  const AuthSuccess(this.user);
}

/// Authentication failed. Contains a human-readable error message.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// =============================================================================
// AUTH CONTROLLER
// =============================================================================

/// Authentication controller implementing a predictable state machine.
///
/// Every public auth method follows the same execution pattern:
/// ```
/// [Guard]   → Skip if loading or disposed
/// [Enter]   → Emit Loading
/// [Execute] → Run async action
/// [Exit]    → Emit Success/Idle/Error based on result
/// [Cleanup] → Reset loading flag (always runs)
/// ```
class AuthController {
  final AuthRepository _repository;
  final List<void Function(AuthState)> _listeners = [];

  AuthState _state = const AuthIdle();
  bool _isLoading = false;
  bool _isDisposed = false;

  AuthController(this._repository);

  // ===========================================================================
  // PUBLIC API - QUERIES
  // ===========================================================================

  /// Current authentication state.
  AuthState get state => _state;

  // ===========================================================================
  // PUBLIC API - LISTENERS
  // ===========================================================================

  /// Register a listener for state changes.
  void addListener(void Function(AuthState) listener) {
    if (_isDisposed) return;
    _listeners.add(listener);
  }

  /// Remove a listener.
  void removeListener(void Function(AuthState) listener) {
    _listeners.remove(listener);
  }

  /// Clean up resources. No state updates occur after disposal.
  void dispose() {
    _isDisposed = true;
    _listeners.clear();
  }

  // ===========================================================================
  // PUBLIC API - COMMANDS
  // All commands follow: * → Loading → (Success | Idle | Error)
  // ===========================================================================

  /// Sign up with email and password.
  /// Transition: `* → Loading → Success(user) | Error`
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) => _run(
    () => _repository.signUpWithEmail(email: email, password: password),
    _asSuccess,
  );

  /// Sign in with email and password.
  /// Transition: `* → Loading → Success(user) | Error`
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _run(
    () => _repository.signInWithEmail(email: email, password: password),
    _asSuccess,
  );

  /// Sign in with Google.
  /// Transition: `* → Loading → Success(user) | Error`
  Future<void> signInWithGoogle() =>
      _run(_repository.signInWithGoogle, _asSuccess);

  /// Sign in with Apple.
  /// Transition: `* → Loading → Success(user) | Error`
  Future<void> signInWithApple() =>
      _run(_repository.signInWithApple, _asSuccess);

  /// Sign out the current user.
  /// Transition: `* → Loading → Idle | Error`
  Future<void> signOut() => _run(
    _repository.signOut,
    _asIdle,
    fallbackError: 'Failed to sign out. Please try again.',
  );

  // ===========================================================================
  // STATE MACHINE CORE
  // ===========================================================================

  /// Maps a successful auth result to [AuthSuccess].
  static AuthState _asSuccess(AuthUser user) => AuthSuccess(user);

  /// Maps any result to [AuthIdle] (used for sign out).
  static AuthState _asIdle(void _) => const AuthIdle();

  /// Unified execution pattern for all auth operations.
  ///
  /// Guarantees:
  /// - Concurrent operations are blocked (single-flight)
  /// - Post-disposal operations are ignored
  /// - Loading state is always entered before async work
  /// - Loading flag is always reset, even on exception
  /// - Domain errors produce user-friendly messages
  /// - Unknown errors produce fallback message
  Future<void> _run<T>(
    Future<T> Function() action,
    AuthState Function(T) toState, {
    String fallbackError = 'An unexpected error occurred. Please try again.',
  }) async {
    // GUARD: Single-flight protection + disposal check
    if (_isLoading || _isDisposed) return;

    _isLoading = true;
    _emit(const AuthLoading());

    try {
      // EXECUTE: Run the async repository action
      final result = await action();
      // EXIT (success): Map result to target state
      _emit(toState(result));
    } on AuthFailure catch (e) {
      // EXIT (domain error): Use domain error message
      _emit(AuthError(e.message));
    } catch (_) {
      // EXIT (unknown error): Use fallback message
      _emit(AuthError(fallbackError));
    } finally {
      // CLEANUP: Always reset loading flag
      _isLoading = false;
    }
  }

  /// Emit a new state to all listeners.
  ///
  /// Safety guarantees:
  /// - Ignores emissions after disposal
  /// - Iterates a copy to handle listener self-removal
  /// - Stops iteration if disposed mid-notification
  void _emit(AuthState newState) {
    if (_isDisposed) return;

    _state = newState;

    for (final listener in List.of(_listeners)) {
      if (_isDisposed) break;
      listener(newState);
    }
  }
}
