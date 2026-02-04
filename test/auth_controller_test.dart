// ignore_for_file: unused_local_variable
import 'package:flutter_test/flutter_test.dart';
import 'package:inksight/features/auth/auth_controller.dart';

// =============================================================================
// AUTH CONTROLLER CONTRACT TESTS
// =============================================================================

// =============================================================================
// FAKE REPOSITORY FOR TESTING
// =============================================================================

class FakeAuthRepository implements AuthRepository {
  User? nextUser;
  AuthException? nextException;
  Duration? artificialDelay;
  int signUpCallCount = 0;
  int signInCallCount = 0;
  int googleSignInCallCount = 0;
  int appleSignInCallCount = 0;
  int signOutCallCount = 0;

  void reset() {
    nextUser = null;
    nextException = null;
    artificialDelay = null;
    signUpCallCount = 0;
    signInCallCount = 0;
    googleSignInCallCount = 0;
    appleSignInCallCount = 0;
    signOutCallCount = 0;
  }

  Future<T> _execute<T>(
    T Function() action,
    void Function() countIncrement,
  ) async {
    countIncrement();
    if (artificialDelay != null) {
      await Future.delayed(artificialDelay!);
    }
    if (nextException != null) {
      throw nextException!;
    }
    return action();
  }

  @override
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) => _execute(() => nextUser!, () => signUpCallCount++);

  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) => _execute(() => nextUser!, () => signInCallCount++);

  @override
  Future<User> signInWithGoogle() =>
      _execute(() => nextUser!, () => googleSignInCallCount++);

  @override
  Future<User> signInWithApple() =>
      _execute(() => nextUser!, () => appleSignInCallCount++);

  @override
  Future<void> signOut() => _execute(() {}, () => signOutCallCount++);
}

// =============================================================================
// TEST DATA
// =============================================================================

const testUser = User(
  id: 'user-123',
  email: 'test@example.com',
  displayName: 'Test User',
  provider: AuthProvider.email,
);

const googleUser = User(
  id: 'google-456',
  email: 'google@example.com',
  displayName: 'Google User',
  provider: AuthProvider.google,
);

const appleUser = User(
  id: 'apple-789',
  email: 'apple@example.com',
  displayName: 'Apple User',
  provider: AuthProvider.apple,
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

  group('AuthController - Initialization', () {
    test('initial state should be AuthIdle', () {
      final controller = AuthController(fakeRepository);
      expect(controller.state, isA<AuthIdle>());
    });

    test(
      'should accept AuthRepository via constructor (dependency injection)',
      () {
        final controller = AuthController(fakeRepository);
        expect(controller, isNotNull);
      },
    );
  });

  group('AuthController - Email/Password Sign Up', () {
    test(
      'should emit AuthLoading then AuthSuccess on successful sign up',
      () async {
        fakeRepository.nextUser = testUser;

        await controller.signUpWithEmail(
          email: 'new@example.com',
          password: 'password123',
        );

        expect(controller.state, isA<AuthSuccess>());
        expect((controller.state as AuthSuccess).user, equals(testUser));
      },
    );

    test('should call repository signUpWithEmail exactly once', () async {
      fakeRepository.nextUser = testUser;

      await controller.signUpWithEmail(
        email: 'new@example.com',
        password: 'password123',
      );

      expect(fakeRepository.signUpCallCount, equals(1));
    });

    test('should emit AuthError when email already exists', () async {
      fakeRepository.nextException = const AuthException(
        'email-already-in-use',
        'An account with this email already exists.',
      );

      await controller.signUpWithEmail(
        email: 'existing@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        contains('already exists'),
      );
    });
  });

  group('AuthController - Email/Password Sign In', () {
    test(
      'should emit AuthLoading then AuthSuccess on successful sign in',
      () async {
        fakeRepository.nextUser = testUser;

        await controller.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(controller.state, isA<AuthSuccess>());
        expect(
          (controller.state as AuthSuccess).user.email,
          equals('test@example.com'),
        );
      },
    );

    test('should emit AuthError when user not found', () async {
      fakeRepository.nextException = const AuthException(
        'user-not-found',
        'No account found with this email.',
      );

      await controller.signInWithEmail(
        email: 'nonexistent@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());
      expect((controller.state as AuthError).message, contains('No account'));
    });

    test('should emit AuthError when password is wrong', () async {
      fakeRepository.nextException = const AuthException(
        'wrong-password',
        'Incorrect password. Please try again.',
      );

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        contains('Incorrect password'),
      );
    });
  });

  group('AuthController - Google Sign In', () {
    test(
      'should emit AuthLoading then AuthSuccess on successful Google sign in',
      () async {
        fakeRepository.nextUser = googleUser;

        await controller.signInWithGoogle();

        expect(controller.state, isA<AuthSuccess>());
        expect(
          (controller.state as AuthSuccess).user.provider,
          equals(AuthProvider.google),
        );
      },
    );

    test('should handle Google sign in cancellation gracefully', () async {
      fakeRepository.nextException = const AuthException(
        'cancelled',
        'Sign in was cancelled.',
      );

      await controller.signInWithGoogle();

      expect(controller.state, isA<AuthError>());
      expect((controller.state as AuthError).message, contains('cancelled'));
    });

    test(
      'should emit user-friendly error when Google services unavailable',
      () async {
        fakeRepository.nextException = const AuthException(
          'google-unavailable',
          'Google sign in is currently unavailable. Please try another method.',
        );

        await controller.signInWithGoogle();

        expect(controller.state, isA<AuthError>());
        final message = (controller.state as AuthError).message;
        expect(message, isNot(contains('Exception')));
        expect(message, contains('unavailable'));
      },
    );
  });

  group('AuthController - Apple Sign In', () {
    test(
      'should emit AuthLoading then AuthSuccess on successful Apple sign in',
      () async {
        fakeRepository.nextUser = appleUser;

        await controller.signInWithApple();

        expect(controller.state, isA<AuthSuccess>());
        expect(
          (controller.state as AuthSuccess).user.provider,
          equals(AuthProvider.apple),
        );
      },
    );

    test('should handle Apple sign in cancellation gracefully', () async {
      fakeRepository.nextException = const AuthException(
        'cancelled',
        'Sign in was cancelled.',
      );

      await controller.signInWithApple();

      expect(controller.state, isA<AuthError>());
    });

    test(
      'should emit user-friendly error when Apple sign in not supported',
      () async {
        fakeRepository.nextException = const AuthException(
          'not-supported',
          'Apple sign in is not available on this device.',
        );

        await controller.signInWithApple();

        expect(controller.state, isA<AuthError>());
        final message = (controller.state as AuthError).message;
        expect(message, contains('not available'));
      },
    );
  });

  group('AuthController - Sign Out', () {
    test(
      'should emit AuthLoading then AuthIdle on successful sign out',
      () async {
        // First sign in
        fakeRepository.nextUser = testUser;
        await controller.signInWithEmail(
          email: 'test@example.com',
          password: 'pass123',
        );

        // Then sign out
        fakeRepository.nextException = null;
        await controller.signOut();

        expect(controller.state, isA<AuthIdle>());
      },
    );

    test('should emit AuthError if sign out fails', () async {
      fakeRepository.nextException = const AuthException(
        'network-error',
        'Failed to sign out. Please try again.',
      );

      await controller.signOut();

      expect(controller.state, isA<AuthError>());
    });
  });

  group('AuthController - Validation Errors', () {
    test('should emit AuthError for invalid email format', () async {
      fakeRepository.nextException = const AuthException(
        'invalid-email',
        'Please enter a valid email address.',
      );

      await controller.signUpWithEmail(
        email: 'not-an-email',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());
      expect((controller.state as AuthError).message, contains('valid email'));
    });

    test(
      'should emit AuthError for weak password (less than 8 chars)',
      () async {
        fakeRepository.nextException = const AuthException(
          'weak-password',
          'Password must be at least 8 characters with at least 1 number.',
        );

        await controller.signUpWithEmail(
          email: 'test@example.com',
          password: 'short',
        );

        expect(controller.state, isA<AuthError>());
        expect(
          (controller.state as AuthError).message,
          contains('8 characters'),
        );
      },
    );

    test('should emit AuthError for password without number', () async {
      fakeRepository.nextException = const AuthException(
        'weak-password',
        'Password must be at least 8 characters with at least 1 number.',
      );

      await controller.signUpWithEmail(
        email: 'test@example.com',
        password: 'nonumberpassword',
      );

      expect(controller.state, isA<AuthError>());
      expect((controller.state as AuthError).message, contains('number'));
    });
  });

  group('AuthController - State Transitions', () {
    test('should transition: idle -> loading -> success', () async {
      fakeRepository.nextUser = testUser;
      fakeRepository.artificialDelay = const Duration(milliseconds: 10);

      final states = <AuthState>[];
      controller.addListener((state) => states.add(state));

      expect(controller.state, isA<AuthIdle>()); // initial

      final future = controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Should be loading immediately after call
      await Future.delayed(Duration.zero);
      expect(controller.state, isA<AuthLoading>());

      await future;
      expect(controller.state, isA<AuthSuccess>());
    });

    test('should transition: idle -> loading -> error on failure', () async {
      fakeRepository.nextException = const AuthException(
        'network-error',
        'Network error. Please check your connection.',
      );

      final states = <AuthState>[];
      controller.addListener((state) => states.add(state));

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Verify we went through loading to error
      expect(states, contains(isA<AuthLoading>()));
      expect(controller.state, isA<AuthError>());
    });
  });

  group('AuthController - Duplicate Request Prevention', () {
    test('should ignore sign in request while already loading', () async {
      fakeRepository.nextUser = testUser;
      fakeRepository.artificialDelay = const Duration(milliseconds: 100);

      // Start first request
      final first = controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Try to start second request immediately (while first is loading)
      final second = controller.signInWithEmail(
        email: 'other@example.com',
        password: 'otherpass123',
      );

      await Future.wait([first, second]);

      // Repository should only be called once
      expect(fakeRepository.signInCallCount, equals(1));
    });

    test('should ignore sign up request while already loading', () async {
      fakeRepository.nextUser = testUser;
      fakeRepository.artificialDelay = const Duration(milliseconds: 100);

      final futures = [
        controller.signUpWithEmail(email: 'a@test.com', password: 'password1'),
        controller.signUpWithEmail(email: 'b@test.com', password: 'password2'),
        controller.signUpWithEmail(email: 'c@test.com', password: 'password3'),
      ];

      await Future.wait(futures);

      expect(fakeRepository.signUpCallCount, equals(1));
    });

    test(
      'should ignore Google sign in request while already loading',
      () async {
        fakeRepository.nextUser = googleUser;
        fakeRepository.artificialDelay = const Duration(milliseconds: 100);

        await Future.wait([
          controller.signInWithGoogle(),
          controller.signInWithGoogle(),
          controller.signInWithGoogle(),
        ]);

        expect(fakeRepository.googleSignInCallCount, equals(1));
      },
    );

    test('should ignore Apple sign in request while already loading', () async {
      fakeRepository.nextUser = appleUser;
      fakeRepository.artificialDelay = const Duration(milliseconds: 100);

      await Future.wait([
        controller.signInWithApple(),
        controller.signInWithApple(),
      ]);

      expect(fakeRepository.appleSignInCallCount, equals(1));
    });

    test('should allow new request after previous completes', () async {
      fakeRepository.nextUser = testUser;

      // First request completes
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Second request should now be allowed
      await controller.signInWithEmail(
        email: 'other@example.com',
        password: 'password456',
      );

      expect(fakeRepository.signInCallCount, equals(2));
    });
  });

  group('AuthController - Error Message Quality', () {
    test(
      'error messages should not contain technical exception details',
      () async {
        fakeRepository.nextException = const AuthException(
          'unknown',
          'An unexpected error occurred. Please try again.',
        );

        await controller.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        final message = (controller.state as AuthError).message;
        expect(message, isNot(contains('Exception')));
        expect(message, isNot(contains('Error:')));
        expect(message, isNot(contains('null')));
        expect(message, isNot(contains('stack')));
      },
    );

    test('error messages should be human-readable sentences', () async {
      fakeRepository.nextException = const AuthException(
        'network-error',
        'Network error. Please check your connection and try again.',
      );

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      final message = (controller.state as AuthError).message;
      expect(message.length, greaterThan(10));
      expect(message.endsWith('.'), isTrue);
    });

    test('network errors should suggest checking connection', () async {
      fakeRepository.nextException = const AuthException(
        'network-error',
        'Network error. Please check your connection and try again.',
      );

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      final message = (controller.state as AuthError).message;
      expect(message.toLowerCase(), contains('connection'));
    });
  });

  group('AuthController - Social Login Graceful Failure', () {
    test('Google cancellation should not throw unhandled exception', () async {
      fakeRepository.nextException = const AuthException(
        'cancelled',
        'Sign in was cancelled.',
      );

      // This should NOT throw
      await controller.signInWithGoogle();

      expect(controller.state, isA<AuthError>());
    });

    test('Apple cancellation should not throw unhandled exception', () async {
      fakeRepository.nextException = const AuthException(
        'cancelled',
        'Sign in was cancelled.',
      );

      // This should NOT throw
      await controller.signInWithApple();

      expect(controller.state, isA<AuthError>());
    });

    test('should recover from social login failure and allow retry', () async {
      // First attempt fails
      fakeRepository.nextException = const AuthException(
        'cancelled',
        'Sign in was cancelled.',
      );

      await controller.signInWithGoogle();
      expect(controller.state, isA<AuthError>());

      // Second attempt succeeds
      fakeRepository.nextException = null;
      fakeRepository.nextUser = googleUser;

      await controller.signInWithGoogle();
      expect(controller.state, isA<AuthSuccess>());
    });
  });

  group('AuthController - Architecture Constraints', () {
    test('controller must work without Flutter UI dependencies', () {
      final controller = AuthController(fakeRepository);
      expect(controller, isNotNull);
      expect(controller.state, isA<AuthState>());
    });

    test('controller must accept repository via constructor injection', () {
      final repo1 = FakeAuthRepository();
      final repo2 = FakeAuthRepository();

      final controller1 = AuthController(repo1);
      final controller2 = AuthController(repo2);

      expect(identical(controller1, controller2), isFalse);
    });

    test('controller must be testable with fake repository', () async {
      fakeRepository.nextUser = testUser;

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect((controller.state as AuthSuccess).user, equals(testUser));
    });
  });
}
