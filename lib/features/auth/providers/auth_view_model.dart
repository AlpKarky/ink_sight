// =============================================================================
// AUTH VIEW MODEL
// =============================================================================
// Riverpod 3 AsyncNotifier for authentication operations.
// Mirrors AuthController logic for Riverpod integration.
//
// STATE TRANSITIONS:
// ┌───────────────────────────────────────────────────────────────────────────┐
// │   Idle/Success/Error → Loading → Success | Idle | Error                   │
// │   Loading → Loading (ignored, prevents double-submit)                     │
// └───────────────────────────────────────────────────────────────────────────┘
// =============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';
import '../domain/auth_repository.dart';
import 'auth_repository_provider.dart';

// =============================================================================
// AUTH VIEW MODEL
// =============================================================================

/// Authentication ViewModel using Riverpod 3 AsyncNotifier.
///
/// Every public auth method follows the same execution pattern:
/// ```
/// [Guard]   → Skip if loading
/// [Enter]   → state = AsyncValue.data(AuthLoading())
/// [Execute] → Run async action
/// [Exit]    → state = AsyncValue.data(Success/Idle/Error)
/// [Cleanup] → Reset loading flag (always runs)
/// ```
class AuthViewModel extends AsyncNotifier<AuthState> {
  bool _isLoading = false;

  @override
  FutureOr<AuthState> build() {
    return const AuthIdle();
  }

  /// Access to the auth repository via provider.
  AuthRepository get _repository => ref.read(authRepositoryProvider);

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
  /// - Loading state is always entered before async work
  /// - Loading flag is always reset, even on exception
  /// - Domain errors produce user-friendly messages
  /// - Unknown errors produce fallback message
  Future<void> _run<T>(
    Future<T> Function() action,
    AuthState Function(T) toState, {
    String fallbackError = 'An unexpected error occurred. Please try again.',
  }) async {
    // GUARD: Single-flight protection
    if (_isLoading) return;

    _isLoading = true;
    state = const AsyncValue.data(AuthLoading());

    try {
      // EXECUTE: Run the async repository action
      final result = await action();
      // EXIT (success): Map result to target state
      state = AsyncValue.data(toState(result));
    } on AuthFailure catch (e) {
      // EXIT (domain error): Use domain error message
      state = AsyncValue.data(AuthError(e.message));
    } catch (_) {
      // EXIT (unknown error): Use fallback message
      state = AsyncValue.data(AuthError(fallbackError));
    } finally {
      // CLEANUP: Always reset loading flag
      _isLoading = false;
    }
  }
}

// =============================================================================
// PROVIDER
// =============================================================================

/// Provider for [AuthViewModel].
final authViewModelProvider = AsyncNotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
