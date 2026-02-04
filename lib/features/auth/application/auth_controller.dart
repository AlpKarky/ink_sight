import 'package:riverpod/riverpod.dart';

import '../domain/models/auth_state.dart';
import '../domain/repositories/auth_repository.dart';

/// Controller for authentication operations.
///
/// This controller manages the authentication state and exposes methods
/// for all authentication flows. It ensures:
/// - State transitions are predictable (idle -> loading -> success/error)
/// - Duplicate requests during loading are prevented
/// - Errors are human-readable
/// - Auth logic is decoupled from UI
///
/// ## Usage with Riverpod
///
/// ```dart
/// final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
///   (ref) => AuthController(ref.watch(authRepositoryProvider)),
/// );
/// ```
///
/// ## State Machine
///
/// ```
/// idle ──> loading ──> success(user)
///                  └─> error(message) ──> idle (on retry)
/// ```
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  /// Tracks whether an operation is in progress to prevent duplicate requests.
  bool _isOperationInProgress = false;

  AuthController(this._repository) : super(const AuthStateIdle());

  /// Whether the controller is currently processing a request.
  ///
  /// Used to prevent duplicate requests when user taps multiple times.
  bool get isOperationInProgress => _isOperationInProgress;

  /// Signs up a new user with email and password.
  ///
  /// Validates inputs before sending to repository.
  /// Does nothing if an operation is already in progress.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    // Prevent duplicate requests
    if (_isOperationInProgress) return;

    _isOperationInProgress = true;
    state = const AuthStateLoading();

    try {
      final user = await _repository.signUpWithEmail(
        email: email,
        password: password,
      );
      state = AuthStateSuccess(user);
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
    } catch (e) {
      state = const AuthStateError(
        'An unexpected error occurred. Please try again.',
      );
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// Signs in with email and password.
  ///
  /// Does nothing if an operation is already in progress.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_isOperationInProgress) return;

    _isOperationInProgress = true;
    state = const AuthStateLoading();

    try {
      final user = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      state = AuthStateSuccess(user);
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
    } catch (e) {
      state = const AuthStateError(
        'An unexpected error occurred. Please try again.',
      );
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// Signs in with Google.
  ///
  /// Does nothing if an operation is already in progress.
  Future<void> signInWithGoogle() async {
    if (_isOperationInProgress) return;

    _isOperationInProgress = true;
    state = const AuthStateLoading();

    try {
      final user = await _repository.signInWithGoogle();
      state = AuthStateSuccess(user);
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
    } catch (e) {
      state = const AuthStateError(
        'An unexpected error occurred. Please try again.',
      );
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// Signs in with Apple.
  ///
  /// Does nothing if an operation is already in progress.
  Future<void> signInWithApple() async {
    if (_isOperationInProgress) return;

    _isOperationInProgress = true;
    state = const AuthStateLoading();

    try {
      final user = await _repository.signInWithApple();
      state = AuthStateSuccess(user);
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
    } catch (e) {
      state = const AuthStateError(
        'An unexpected error occurred. Please try again.',
      );
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// Signs out the current user.
  ///
  /// Returns to idle state on success.
  /// Does nothing if an operation is already in progress.
  Future<void> signOut() async {
    if (_isOperationInProgress) return;

    _isOperationInProgress = true;
    state = const AuthStateLoading();

    try {
      await _repository.signOut();
      state = const AuthStateIdle();
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
    } catch (e) {
      state = const AuthStateError('Failed to sign out. Please try again.');
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// Resets the state to idle.
  ///
  /// Useful for clearing error states before retrying.
  void resetState() {
    if (!_isOperationInProgress) {
      state = const AuthStateIdle();
    }
  }
}

// Provider definitions will be added during implementation.
// For testing, the controller is instantiated directly with a mock repository.
