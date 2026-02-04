// =============================================================================
// AUTH CONTROLLER
// =============================================================================
// Simple state notifier for authentication operations.
// Accepts repository via constructor for testability.
// =============================================================================

/// User model returned on successful authentication.
class User {
  final String id;
  final String email;
  final String? displayName;
  final AuthProvider provider;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    required this.provider,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          id == other.id &&
          email == other.email &&
          provider == other.provider;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ provider.hashCode;
}

enum AuthProvider { email, google, apple }

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
  final User user;
  const AuthSuccess(this.user);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// Repository interface the controller depends on.
abstract class AuthRepository {
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  });
  Future<User> signInWithEmail({
    required String email,
    required String password,
  });
  Future<User> signInWithGoogle();
  Future<User> signInWithApple();
  Future<void> signOut();
}

/// Exception thrown by repository operations.
class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException(this.code, this.message);
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
    } on AuthException catch (e) {
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
    } on AuthException catch (e) {
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
    } on AuthException catch (e) {
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
    } on AuthException catch (e) {
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
    } on AuthException catch (e) {
      _setState(AuthError(e.message));
    } catch (e) {
      _setState(const AuthError('Failed to sign out. Please try again.'));
    } finally {
      _isLoading = false;
    }
  }
}
