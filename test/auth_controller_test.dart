// ignore_for_file: unused_local_variable
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:inksight/features/auth/auth_controller.dart';
import 'package:inksight/features/auth/domain/auth_repository.dart';

// =============================================================================
// AUTH CONTROLLER CONTRACT TESTS
// =============================================================================

// =============================================================================
// FAKE REPOSITORY FOR TESTING
// =============================================================================

/// Configurable fake implementation of [AuthRepository] for testing.
///
/// Supports simulating:
/// - Success scenarios (set [nextUser])
/// - Failure scenarios (set [nextFailure])
/// - Delayed responses (set [artificialDelay])
/// - Call counting for verification
class FakeAuthRepository implements AuthRepository {
  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// The user to return on successful operations.
  AuthUser? nextUser;

  /// The failure to throw on operations. Takes precedence over [nextUser].
  AuthFailure? nextFailure;

  /// Artificial delay to simulate network latency.
  Duration? artificialDelay;

  /// Current signed-in user (for getCurrentUser and authStateChanges).
  AuthUser? _currentUser;

  /// Stream controller for auth state changes.
  final _authStateController = StreamController<AuthUser?>.broadcast();

  // ---------------------------------------------------------------------------
  // Call Counters
  // ---------------------------------------------------------------------------

  int signUpCallCount = 0;
  int signInCallCount = 0;
  int googleSignInCallCount = 0;
  int appleSignInCallCount = 0;
  int signOutCallCount = 0;
  int getCurrentUserCallCount = 0;

  // ---------------------------------------------------------------------------
  // Setup Helpers
  // ---------------------------------------------------------------------------

  /// Resets all configuration and counters.
  void reset() {
    nextUser = null;
    nextFailure = null;
    artificialDelay = null;
    _currentUser = null;
    signUpCallCount = 0;
    signInCallCount = 0;
    googleSignInCallCount = 0;
    appleSignInCallCount = 0;
    signOutCallCount = 0;
    getCurrentUserCallCount = 0;
  }

  /// Configure for successful sign in/up.
  void simulateSuccess(AuthUser user) {
    nextUser = user;
    nextFailure = null;
  }

  /// Configure to throw invalid credentials error.
  void simulateInvalidCredentials() {
    nextFailure = InvalidCredentials();
  }

  /// Configure to throw wrong password error (alias for invalid credentials).
  void simulateWrongPassword() {
    nextFailure = InvalidCredentials();
  }

  /// Configure to throw email already in use error.
  void simulateDuplicateEmail() {
    nextFailure = EmailAlreadyInUse();
  }

  /// Configure to throw network error.
  void simulateNetworkFailure() {
    nextFailure = NetworkError();
  }

  /// Configure to throw auth cancelled error.
  void simulateSocialLoginCancel() {
    nextFailure = AuthCancelled();
  }

  /// Configure to throw invalid email error.
  void simulateInvalidEmail() {
    nextFailure = InvalidEmail();
  }

  /// Configure to throw weak password error.
  void simulateWeakPassword() {
    nextFailure = WeakPassword();
  }

  /// Configure to throw user not found error.
  void simulateUserNotFound() {
    nextFailure = UserNotFound();
  }

  /// Configure to throw too many requests error.
  void simulateTooManyRequests() {
    nextFailure = TooManyRequests();
  }

  /// Configure to throw Google sign in unavailable error.
  void simulateGoogleUnavailable() {
    nextFailure = GoogleSignInUnavailable();
  }

  /// Configure to throw Apple sign in unavailable error.
  void simulateAppleUnavailable() {
    nextFailure = AppleSignInUnavailable();
  }

  /// Configure to throw user disabled error.
  void simulateUserDisabled() {
    nextFailure = UserDisabled();
  }

  /// Configure to throw operation not allowed error.
  void simulateOperationNotAllowed() {
    nextFailure = OperationNotAllowed();
  }

  /// Configure to throw unknown error.
  void simulateUnknownError([String? details]) {
    nextFailure = UnknownAuthFailure(details);
  }

  // ---------------------------------------------------------------------------
  // Internal Execution
  // ---------------------------------------------------------------------------

  Future<T> _execute<T>(T Function() onSuccess, void Function() onCount) async {
    onCount();
    if (artificialDelay != null) {
      await Future.delayed(artificialDelay!);
    }
    if (nextFailure != null) {
      throw nextFailure!;
    }
    return onSuccess();
  }

  // ---------------------------------------------------------------------------
  // AuthRepository Implementation
  // ---------------------------------------------------------------------------

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) => _execute(() {
    _currentUser = nextUser;
    _authStateController.add(_currentUser);
    return nextUser!;
  }, () => signUpCallCount++);

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) => _execute(() {
    _currentUser = nextUser;
    _authStateController.add(_currentUser);
    return nextUser!;
  }, () => signInCallCount++);

  @override
  Future<AuthUser> signInWithGoogle() => _execute(() {
    _currentUser = nextUser;
    _authStateController.add(_currentUser);
    return nextUser!;
  }, () => googleSignInCallCount++);

  @override
  Future<AuthUser> signInWithApple() => _execute(() {
    _currentUser = nextUser;
    _authStateController.add(_currentUser);
    return nextUser!;
  }, () => appleSignInCallCount++);

  @override
  Future<void> signOut() => _execute(() {
    _currentUser = null;
    _authStateController.add(null);
  }, () => signOutCallCount++);

  @override
  Future<AuthUser?> getCurrentUser() async {
    getCurrentUserCallCount++;
    return _currentUser;
  }

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  /// Dispose resources.
  void dispose() {
    _authStateController.close();
  }
}

// =============================================================================
// TEST DATA
// =============================================================================

const testUser = AuthUser(
  id: 'user-123',
  email: 'test@example.com',
  displayName: 'Test User',
  authMethod: AuthMethod.emailPassword,
);

const googleUser = AuthUser(
  id: 'google-456',
  email: 'google@example.com',
  displayName: 'Google User',
  photoUrl: 'https://example.com/photo.jpg',
  authMethod: AuthMethod.google,
);

const appleUser = AuthUser(
  id: 'apple-789',
  email: 'apple@example.com',
  displayName: 'Apple User',
  authMethod: AuthMethod.apple,
);

// =============================================================================
// TESTS
// =============================================================================

void main() {
  late FakeAuthRepository fakeRepository;
  late AuthController controller;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    controller = AuthController(fakeRepository);
  });

  tearDown(() {
    fakeRepository.dispose();
  });

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  group('AuthController - Initialization', () {
    test('initial state should be AuthIdle', () {
      expect(controller.state, isA<AuthIdle>());
    });

    test('should accept AuthRepository via constructor (DI)', () {
      final controller = AuthController(fakeRepository);
      expect(controller, isNotNull);
    });
  });

  // ===========================================================================
  // SUCCESS SCENARIOS
  // ===========================================================================

  group('AuthController - Success Scenarios', () {
    test('sign up success returns AuthSuccess with user', () async {
      fakeRepository.simulateSuccess(testUser);

      await controller.signUpWithEmail(
        email: 'new@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthSuccess>());
      expect((controller.state as AuthSuccess).user, equals(testUser));
      expect(fakeRepository.signUpCallCount, equals(1));
    });

    test('sign in success returns AuthSuccess with user', () async {
      fakeRepository.simulateSuccess(testUser);

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthSuccess>());
      expect(
        (controller.state as AuthSuccess).user.email,
        equals('test@example.com'),
      );
    });

    test(
      'Google sign in success returns user with Google auth method',
      () async {
        fakeRepository.simulateSuccess(googleUser);

        await controller.signInWithGoogle();

        expect(controller.state, isA<AuthSuccess>());
        final user = (controller.state as AuthSuccess).user;
        expect(user.authMethod, equals(AuthMethod.google));
        expect(user.photoUrl, isNotNull);
      },
    );

    test('Apple sign in success returns user with Apple auth method', () async {
      fakeRepository.simulateSuccess(appleUser);

      await controller.signInWithApple();

      expect(controller.state, isA<AuthSuccess>());
      expect(
        (controller.state as AuthSuccess).user.authMethod,
        equals(AuthMethod.apple),
      );
    });

    test('sign out success returns to AuthIdle', () async {
      // First sign in
      fakeRepository.simulateSuccess(testUser);
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'pass123',
      );

      // Then sign out
      fakeRepository.nextFailure = null;
      await controller.signOut();

      expect(controller.state, isA<AuthIdle>());
    });
  });

  // ===========================================================================
  // FAILURE SCENARIOS - CREDENTIALS
  // ===========================================================================

  group('AuthController - Credential Failures', () {
    test('InvalidCredentials shows correct error message', () async {
      fakeRepository.simulateInvalidCredentials();

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        equals(InvalidCredentials().message),
      );
    });

    test('wrong password shows invalid credentials error', () async {
      fakeRepository.simulateWrongPassword();

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        contains('Invalid email or password'),
      );
    });

    test('UserNotFound shows correct error message', () async {
      fakeRepository.simulateUserNotFound();

      await controller.signInWithEmail(
        email: 'nonexistent@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        equals(UserNotFound().message),
      );
    });

    test('UserDisabled shows correct error message', () async {
      fakeRepository.simulateUserDisabled();

      await controller.signInWithEmail(
        email: 'disabled@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());
      expect((controller.state as AuthError).message, contains('disabled'));
    });
  });

  // ===========================================================================
  // FAILURE SCENARIOS - VALIDATION
  // ===========================================================================

  group('AuthController - Validation Failures', () {
    test('InvalidEmail shows correct error message', () async {
      fakeRepository.simulateInvalidEmail();

      await controller.signUpWithEmail(
        email: 'not-an-email',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        equals(InvalidEmail().message),
      );
    });

    test('WeakPassword shows correct error message', () async {
      fakeRepository.simulateWeakPassword();

      await controller.signUpWithEmail(
        email: 'test@example.com',
        password: 'short',
      );

      expect(controller.state, isA<AuthError>());
      expect((controller.state as AuthError).message, contains('8 characters'));
    });
  });

  // ===========================================================================
  // FAILURE SCENARIOS - DUPLICATE EMAIL
  // ===========================================================================

  group('AuthController - Duplicate Email', () {
    test('EmailAlreadyInUse shows correct error message', () async {
      fakeRepository.simulateDuplicateEmail();

      await controller.signUpWithEmail(
        email: 'existing@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        equals(EmailAlreadyInUse().message),
      );
    });

    test('duplicate email error contains "already exists"', () async {
      fakeRepository.simulateDuplicateEmail();

      await controller.signUpWithEmail(
        email: 'existing@example.com',
        password: 'password123',
      );

      expect(
        (controller.state as AuthError).message,
        contains('already exists'),
      );
    });
  });

  // ===========================================================================
  // FAILURE SCENARIOS - NETWORK
  // ===========================================================================

  group('AuthController - Network Failures', () {
    test('NetworkError shows correct error message', () async {
      fakeRepository.simulateNetworkFailure();

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        equals(NetworkError().message),
      );
    });

    test('network error suggests checking connection', () async {
      fakeRepository.simulateNetworkFailure();

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(
        (controller.state as AuthError).message.toLowerCase(),
        contains('connection'),
      );
    });

    test('network error on sign out', () async {
      fakeRepository.simulateNetworkFailure();

      await controller.signOut();

      expect(controller.state, isA<AuthError>());
    });

    test('network error on Google sign in', () async {
      fakeRepository.simulateNetworkFailure();

      await controller.signInWithGoogle();

      expect(controller.state, isA<AuthError>());
      expect((controller.state as AuthError).message, contains('Network'));
    });
  });

  // ===========================================================================
  // FAILURE SCENARIOS - SOCIAL LOGIN CANCEL
  // ===========================================================================

  group('AuthController - Social Login Cancellation', () {
    test('Google sign in cancellation handled gracefully', () async {
      fakeRepository.simulateSocialLoginCancel();

      // Should not throw
      await controller.signInWithGoogle();

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        equals(AuthCancelled().message),
      );
    });

    test('Apple sign in cancellation handled gracefully', () async {
      fakeRepository.simulateSocialLoginCancel();

      // Should not throw
      await controller.signInWithApple();

      expect(controller.state, isA<AuthError>());
      expect((controller.state as AuthError).message, contains('cancelled'));
    });

    test('can retry after social login cancellation', () async {
      // First attempt - cancelled
      fakeRepository.simulateSocialLoginCancel();
      await controller.signInWithGoogle();
      expect(controller.state, isA<AuthError>());

      // Second attempt - success
      fakeRepository.simulateSuccess(googleUser);
      await controller.signInWithGoogle();
      expect(controller.state, isA<AuthSuccess>());
    });
  });

  // ===========================================================================
  // FAILURE SCENARIOS - SOCIAL LOGIN UNAVAILABLE
  // ===========================================================================

  group('AuthController - Social Login Unavailable', () {
    test('GoogleSignInUnavailable shows correct error message', () async {
      fakeRepository.simulateGoogleUnavailable();

      await controller.signInWithGoogle();

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        equals(GoogleSignInUnavailable().message),
      );
    });

    test('Google unavailable suggests alternative', () async {
      fakeRepository.simulateGoogleUnavailable();

      await controller.signInWithGoogle();

      expect(
        (controller.state as AuthError).message,
        contains('another method'),
      );
    });

    test('AppleSignInUnavailable shows correct error message', () async {
      fakeRepository.simulateAppleUnavailable();

      await controller.signInWithApple();

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        contains('not available'),
      );
    });
  });

  // ===========================================================================
  // FAILURE SCENARIOS - RATE LIMITING
  // ===========================================================================

  group('AuthController - Rate Limiting', () {
    test('TooManyRequests shows correct error message', () async {
      fakeRepository.simulateTooManyRequests();

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        equals(TooManyRequests().message),
      );
    });

    test('too many requests suggests waiting', () async {
      fakeRepository.simulateTooManyRequests();

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(
        (controller.state as AuthError).message.toLowerCase(),
        contains('wait'),
      );
    });
  });

  // ===========================================================================
  // FAILURE SCENARIOS - OTHER
  // ===========================================================================

  group('AuthController - Other Failures', () {
    test('OperationNotAllowed shows correct error message', () async {
      fakeRepository.simulateOperationNotAllowed();

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());
      expect((controller.state as AuthError).message, contains('not enabled'));
    });

    test('UnknownAuthFailure shows generic error message', () async {
      fakeRepository.simulateUnknownError('Some internal error');

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        equals(UnknownAuthFailure().message),
      );
    });

    test('unknown error does not expose technical details', () async {
      fakeRepository.simulateUnknownError('StackTrace: at line 42...');

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      final message = (controller.state as AuthError).message;
      expect(message, isNot(contains('StackTrace')));
      expect(message, isNot(contains('line 42')));
    });
  });

  // ===========================================================================
  // STATE TRANSITIONS
  // ===========================================================================

  group('AuthController - State Transitions', () {
    test('transitions: idle -> loading -> success', () async {
      fakeRepository.simulateSuccess(testUser);
      fakeRepository.artificialDelay = const Duration(milliseconds: 10);

      final states = <AuthState>[];
      controller.addListener((state) => states.add(state));

      expect(controller.state, isA<AuthIdle>());

      final future = controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      await Future.delayed(Duration.zero);
      expect(controller.state, isA<AuthLoading>());

      await future;
      expect(controller.state, isA<AuthSuccess>());
      expect(states, contains(isA<AuthLoading>()));
    });

    test('transitions: idle -> loading -> error', () async {
      fakeRepository.simulateNetworkFailure();

      final states = <AuthState>[];
      controller.addListener((state) => states.add(state));

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(states, contains(isA<AuthLoading>()));
      expect(controller.state, isA<AuthError>());
    });
  });

  // ===========================================================================
  // DUPLICATE REQUEST PREVENTION
  // ===========================================================================

  group('AuthController - Duplicate Request Prevention', () {
    test('ignores sign in while loading', () async {
      fakeRepository.simulateSuccess(testUser);
      fakeRepository.artificialDelay = const Duration(milliseconds: 100);

      final first = controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );
      final second = controller.signInWithEmail(
        email: 'other@example.com',
        password: 'otherpass123',
      );

      await Future.wait([first, second]);

      expect(fakeRepository.signInCallCount, equals(1));
    });

    test('ignores sign up while loading', () async {
      fakeRepository.simulateSuccess(testUser);
      fakeRepository.artificialDelay = const Duration(milliseconds: 100);

      await Future.wait([
        controller.signUpWithEmail(email: 'a@test.com', password: 'password1'),
        controller.signUpWithEmail(email: 'b@test.com', password: 'password2'),
        controller.signUpWithEmail(email: 'c@test.com', password: 'password3'),
      ]);

      expect(fakeRepository.signUpCallCount, equals(1));
    });

    test('ignores Google sign in while loading', () async {
      fakeRepository.simulateSuccess(googleUser);
      fakeRepository.artificialDelay = const Duration(milliseconds: 100);

      await Future.wait([
        controller.signInWithGoogle(),
        controller.signInWithGoogle(),
      ]);

      expect(fakeRepository.googleSignInCallCount, equals(1));
    });

    test('allows new request after completion', () async {
      fakeRepository.simulateSuccess(testUser);

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );
      await controller.signInWithEmail(
        email: 'other@example.com',
        password: 'password456',
      );

      expect(fakeRepository.signInCallCount, equals(2));
    });
  });

  // ===========================================================================
  // ERROR MESSAGE QUALITY
  // ===========================================================================

  group('AuthController - Error Message Quality', () {
    test('all failure messages are human-readable', () async {
      final failures = <AuthFailure>[
        InvalidCredentials(),
        InvalidEmail(),
        WeakPassword(),
        EmailAlreadyInUse(),
        UserNotFound(),
        NetworkError(),
        AuthCancelled(),
        TooManyRequests(),
        GoogleSignInUnavailable(),
        AppleSignInUnavailable(),
        UserDisabled(),
        OperationNotAllowed(),
        UnknownAuthFailure(),
      ];

      for (final failure in failures) {
        expect(
          failure.message.length,
          greaterThan(10),
          reason: '${failure.runtimeType} message too short',
        );
        expect(
          failure.message.endsWith('.'),
          isTrue,
          reason: '${failure.runtimeType} message should end with period',
        );
        expect(
          failure.message,
          isNot(contains('Exception')),
          reason: '${failure.runtimeType} should not contain "Exception"',
        );
        expect(
          failure.message,
          isNot(contains('Error:')),
          reason: '${failure.runtimeType} should not contain "Error:"',
        );
      }
    });
  });

  // ===========================================================================
  // ARCHITECTURE CONSTRAINTS
  // ===========================================================================

  group('AuthController - Architecture', () {
    test('works without Flutter UI dependencies', () {
      final controller = AuthController(fakeRepository);
      expect(controller, isNotNull);
      expect(controller.state, isA<AuthState>());
    });

    test('accepts repository via constructor injection', () {
      final repo1 = FakeAuthRepository();
      final repo2 = FakeAuthRepository();

      final controller1 = AuthController(repo1);
      final controller2 = AuthController(repo2);

      expect(identical(controller1, controller2), isFalse);
    });

    test('testable with fake repository', () async {
      fakeRepository.simulateSuccess(testUser);

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect((controller.state as AuthSuccess).user, equals(testUser));
    });
  });
}
