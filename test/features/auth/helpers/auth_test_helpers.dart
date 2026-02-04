import 'package:inksight/features/auth/application/auth_controller.dart';
import 'package:inksight/features/auth/domain/models/auth_state.dart';
import 'package:inksight/features/auth/domain/repositories/auth_repository.dart';

import '../mocks/mock_auth_repository.dart';

/// Helper class for setting up auth controller tests.
class AuthTestHelper {
  final MockAuthRepository mockRepository;
  late AuthController controller;
  final List<AuthState> stateHistory = [];

  AuthTestHelper() : mockRepository = MockAuthRepository();

  /// Creates a new controller instance and starts recording state changes.
  void setUp() {
    controller = AuthController(mockRepository);
    stateHistory.clear();
    stateHistory.add(controller.state);

    // Listen to state changes
    controller.addListener((state) {
      stateHistory.add(state);
    });
  }

  /// Disposes the controller.
  void tearDown() {
    controller.dispose();
  }

  /// Verifies the state transition sequence.
  bool verifyStateSequence(List<Type> expectedStates) {
    if (stateHistory.length != expectedStates.length) {
      return false;
    }

    for (var i = 0; i < stateHistory.length; i++) {
      if (stateHistory[i].runtimeType != expectedStates[i]) {
        return false;
      }
    }
    return true;
  }

  /// Gets all error messages from state history.
  List<String> get errorMessages =>
      stateHistory.whereType<AuthStateError>().map((e) => e.message).toList();
}

/// Matcher helpers for auth states.
extension AuthStateMatcher on AuthState {
  /// Checks if this is an error state with the expected message.
  bool isErrorWithMessage(String expectedMessage) {
    return this is AuthStateError &&
        (this as AuthStateError).message == expectedMessage;
  }

  /// Checks if this is a success state with the expected user id.
  bool isSuccessWithUserId(String expectedUserId) {
    return this is AuthStateSuccess &&
        (this as AuthStateSuccess).user.id == expectedUserId;
  }
}

/// Common auth exceptions for testing.
class TestAuthExceptions {
  static const networkError = AuthException(
    code: AuthErrorCode.networkError,
    message: 'Network error. Please check your connection and try again.',
  );

  static const invalidEmail = AuthException(
    code: AuthErrorCode.invalidEmail,
    message: 'Please enter a valid email address.',
  );

  static const weakPassword = AuthException(
    code: AuthErrorCode.weakPassword,
    message: 'Password must be at least 8 characters with at least 1 number.',
  );

  static const emailAlreadyInUse = AuthException(
    code: AuthErrorCode.emailAlreadyInUse,
    message: 'An account with this email already exists.',
  );

  static const userNotFound = AuthException(
    code: AuthErrorCode.userNotFound,
    message: 'No account found with this email. Please sign up first.',
  );

  static const wrongPassword = AuthException(
    code: AuthErrorCode.wrongPassword,
    message: 'Incorrect password. Please try again.',
  );

  static const invalidCredentials = AuthException(
    code: AuthErrorCode.invalidCredentials,
    message: 'Invalid email or password. Please check your credentials.',
  );

  static const socialSignInCancelled = AuthException(
    code: AuthErrorCode.socialSignInCancelled,
    message: 'Sign in was cancelled.',
  );

  static const googleSignInFailed = AuthException(
    code: AuthErrorCode.socialSignInFailed,
    message: 'Sign in failed. Please try again.',
  );

  static const googleUnavailable = AuthException(
    code: AuthErrorCode.googleSignInUnavailable,
    message:
        'Google sign in is currently unavailable. Please try another method.',
  );

  static const appleSignInFailed = AuthException(
    code: AuthErrorCode.socialSignInFailed,
    message: 'Sign in failed. Please try again.',
  );

  static const appleNotSupported = AuthException(
    code: AuthErrorCode.appleSignInNotSupported,
    message: 'Apple sign in is not available on this device.',
  );

  static const tooManyRequests = AuthException(
    code: AuthErrorCode.tooManyRequests,
    message: 'Too many attempts. Please wait a moment and try again.',
  );
}
