// =============================================================================
// AUTH CONTROLLER
// =============================================================================
// Simple state notifier for authentication operations.
// Accepts repository via constructor for testability.
// =============================================================================

import 'domain/auth_repository.dart';

/// Auth state - sealed class for exhaustive matching.
sealed class AuthState {
  const AuthState();
}

class AuthIdle extends AuthState {
  const AuthIdle();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final AuthUser user;
  const AuthSuccess(this.user);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// Authentication controller with simple state management.
///
/// Accepts [AuthRepository] via constructor for dependency injection.
/// Does not depend on Flutter UI.
class AuthController {
  final AuthRepository _repository;
  final List<void Function(AuthState)> _listeners = [];

  AuthState _state = const AuthIdle();
  bool _isLoading = false;

  AuthController(this._repository);

  /// Current authentication state.
  AuthState get state => _state;

  /// Register a listener for state changes.
  void addListener(void Function(AuthState) listener) {
    _listeners.add(listener);
  }

  /// Remove a listener.
  void removeListener(void Function(AuthState) listener) {
    _listeners.remove(listener);
  }

  void _setState(AuthState newState) {
    _state = newState;
    for (final listener in _listeners) {
      listener(newState);
    }
  }

  /// Sign up with email and password.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _setState(const AuthLoading());

    try {
      final user = await _repository.signUpWithEmail(
        email: email,
        password: password,
      );
      _setState(AuthSuccess(user));
    } on AuthFailure catch (e) {
      _setState(AuthError(e.message));
    } catch (e) {
      _setState(
        const AuthError('An unexpected error occurred. Please try again.'),
      );
    } finally {
      _isLoading = false;
    }
  }

  /// Sign in with email and password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _setState(const AuthLoading());

    try {
      final user = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      _setState(AuthSuccess(user));
    } on AuthFailure catch (e) {
      _setState(AuthError(e.message));
    } catch (e) {
      _setState(
        const AuthError('An unexpected error occurred. Please try again.'),
      );
    } finally {
      _isLoading = false;
    }
  }

  /// Sign in with Google.
  Future<void> signInWithGoogle() async {
    if (_isLoading) return;

    _isLoading = true;
    _setState(const AuthLoading());

    try {
      final user = await _repository.signInWithGoogle();
      _setState(AuthSuccess(user));
    } on AuthFailure catch (e) {
      _setState(AuthError(e.message));
    } catch (e) {
      _setState(
        const AuthError('An unexpected error occurred. Please try again.'),
      );
    } finally {
      _isLoading = false;
    }
  }

  /// Sign in with Apple.
  Future<void> signInWithApple() async {
    if (_isLoading) return;

    _isLoading = true;
    _setState(const AuthLoading());

    try {
      final user = await _repository.signInWithApple();
      _setState(AuthSuccess(user));
    } on AuthFailure catch (e) {
      _setState(AuthError(e.message));
    } catch (e) {
      _setState(
        const AuthError('An unexpected error occurred. Please try again.'),
      );
    } finally {
      _isLoading = false;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    if (_isLoading) return;

    _isLoading = true;
    _setState(const AuthLoading());

    try {
      await _repository.signOut();
      _setState(const AuthIdle());
    } on AuthFailure catch (e) {
      _setState(AuthError(e.message));
    } catch (e) {
      _setState(const AuthError('Failed to sign out. Please try again.'));
    } finally {
      _isLoading = false;
    }
  }
}
