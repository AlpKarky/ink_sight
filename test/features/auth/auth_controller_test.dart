import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inksight/features/auth/application/auth_controller.dart';
import 'package:inksight/features/auth/domain/models/auth_state.dart';
import 'package:inksight/features/auth/domain/models/user.dart';
import 'package:inksight/features/auth/domain/repositories/auth_repository.dart';

import 'mocks/mock_auth_repository.dart';
import 'helpers/auth_test_helpers.dart';

void main() {
  late MockAuthRepository mockRepository;
  late AuthController controller;

  setUp(() {
    mockRepository = MockAuthRepository();
    controller = AuthController(mockRepository);
  });

  tearDown(() {
    controller.dispose();
  });

  group('AuthController initialization', () {
    test('initial state should be idle', () {
      expect(controller.state, isA<AuthStateIdle>());
    });

    test('isOperationInProgress should be false initially', () {
      expect(controller.isOperationInProgress, isFalse);
    });
  });

  group('Email/Password Sign Up', () {
    group('successful sign up', () {
      test(
        'should emit loading then success with user on valid credentials',
        () async {
          // Arrange
          mockRepository.setupSignUpSuccess(user: FakeUsers.testUser);
          final states = <AuthState>[];
          controller.addListener((state) => states.add(state));

          // Act
          await controller.signUpWithEmail(
            email: TestCredentials.validEmail,
            password: TestCredentials.validPassword,
          );

          // Assert
          expect(states, [isA<AuthStateLoading>(), isA<AuthStateSuccess>()]);
          expect(
            (controller.state as AuthStateSuccess).user,
            equals(FakeUsers.testUser),
          );
          verify(
            () => mockRepository.signUpWithEmail(
              email: TestCredentials.validEmail,
              password: TestCredentials.validPassword,
            ),
          ).called(1);
        },
      );

      test(
        'should set isOperationInProgress to false after completion',
        () async {
          mockRepository.setupSignUpSuccess();

          await controller.signUpWithEmail(
            email: TestCredentials.validEmail,
            password: TestCredentials.validPassword,
          );

          expect(controller.isOperationInProgress, isFalse);
        },
      );
    });

    group('sign up failures', () {
      test('should emit error state when email already exists', () async {
        // Arrange
        mockRepository.setupSignUpFailure(TestAuthExceptions.emailAlreadyInUse);

        // Act
        await controller.signUpWithEmail(
          email: TestCredentials.existingEmail,
          password: TestCredentials.validPassword,
        );

        // Assert
        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          equals('An account with this email already exists.'),
        );
      });

      test('should emit error state for invalid email format', () async {
        mockRepository.setupSignUpFailure(TestAuthExceptions.invalidEmail);

        await controller.signUpWithEmail(
          email: TestCredentials.invalidEmailNoAt,
          password: TestCredentials.validPassword,
        );

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('valid email'),
        );
      });

      test('should emit error state for weak password', () async {
        mockRepository.setupSignUpFailure(TestAuthExceptions.weakPassword);

        await controller.signUpWithEmail(
          email: TestCredentials.validEmail,
          password: TestCredentials.passwordTooShort,
        );

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('8 characters'),
        );
      });

      test('should emit error state for network error', () async {
        mockRepository.setupSignUpFailure(TestAuthExceptions.networkError);

        await controller.signUpWithEmail(
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('Network error'),
        );
      });

      test('should handle unexpected exceptions gracefully', () async {
        when(
          () => mockRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('Unexpected error'));

        await controller.signUpWithEmail(
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          equals('An unexpected error occurred. Please try again.'),
        );
      });
    });
  });

  group('Email/Password Sign In', () {
    group('successful sign in', () {
      test(
        'should emit loading then success with user on valid credentials',
        () async {
          mockRepository.setupSignInSuccess(user: FakeUsers.testUser);
          final states = <AuthState>[];
          controller.addListener((state) => states.add(state));

          await controller.signInWithEmail(
            email: TestCredentials.validEmail,
            password: TestCredentials.validPassword,
          );

          expect(states, [isA<AuthStateLoading>(), isA<AuthStateSuccess>()]);
          expect(
            (controller.state as AuthStateSuccess).user.email,
            equals(FakeUsers.testUser.email),
          );
        },
      );

      test('should return user with correct provider type', () async {
        mockRepository.setupSignInSuccess(user: FakeUsers.testUser);

        await controller.signInWithEmail(
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );

        final user = (controller.state as AuthStateSuccess).user;
        expect(user.provider, equals(AuthProvider.email));
      });
    });

    group('sign in failures', () {
      test('should emit error when user not found', () async {
        mockRepository.setupSignInFailure(TestAuthExceptions.userNotFound);

        await controller.signInWithEmail(
          email: TestCredentials.nonExistentEmail,
          password: TestCredentials.validPassword,
        );

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('No account found'),
        );
      });

      test('should emit error for wrong password', () async {
        mockRepository.setupSignInFailure(TestAuthExceptions.wrongPassword);

        await controller.signInWithEmail(
          email: TestCredentials.validEmail,
          password: TestCredentials.wrongPassword,
        );

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('Incorrect password'),
        );
      });

      test('should emit error for invalid credentials', () async {
        mockRepository.setupSignInWrongCredentials();

        await controller.signInWithEmail(
          email: TestCredentials.validEmail,
          password: TestCredentials.wrongPassword,
        );

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('Invalid email or password'),
        );
      });

      test('should emit error for network error', () async {
        mockRepository.setupSignInFailure(TestAuthExceptions.networkError);

        await controller.signInWithEmail(
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('Network error'),
        );
      });

      test('should emit error for too many requests', () async {
        mockRepository.setupSignInFailure(TestAuthExceptions.tooManyRequests);

        await controller.signInWithEmail(
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('Too many attempts'),
        );
      });
    });
  });

  group('Google Sign In', () {
    group('successful sign in', () {
      test('should emit loading then success with Google user', () async {
        mockRepository.setupGoogleSignInSuccess(user: FakeUsers.googleUser);
        final states = <AuthState>[];
        controller.addListener((state) => states.add(state));

        await controller.signInWithGoogle();

        expect(states, [isA<AuthStateLoading>(), isA<AuthStateSuccess>()]);
        final user = (controller.state as AuthStateSuccess).user;
        expect(user.provider, equals(AuthProvider.google));
        expect(user.email, equals(FakeUsers.googleUser.email));
      });

      test('should return user with photo URL when available', () async {
        mockRepository.setupGoogleSignInSuccess(user: FakeUsers.googleUser);

        await controller.signInWithGoogle();

        final user = (controller.state as AuthStateSuccess).user;
        expect(user.photoUrl, isNotNull);
        expect(user.photoUrl, equals('https://example.com/photo.jpg'));
      });
    });

    group('Google sign in failures', () {
      test('should handle user cancellation gracefully', () async {
        mockRepository.setupGoogleSignInCancelled();

        await controller.signInWithGoogle();

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          equals('Sign in was cancelled.'),
        );
      });

      test('should handle Google services unavailable', () async {
        mockRepository.setupGoogleSignInFailure(
          TestAuthExceptions.googleUnavailable,
        );

        await controller.signInWithGoogle();

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('unavailable'),
        );
      });

      test('should handle generic Google sign in failure', () async {
        mockRepository.setupGoogleSignInFailure(
          TestAuthExceptions.googleSignInFailed,
        );

        await controller.signInWithGoogle();

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('failed'),
        );
      });

      test('should handle network error during Google sign in', () async {
        mockRepository.setupGoogleSignInFailure(
          TestAuthExceptions.networkError,
        );

        await controller.signInWithGoogle();

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('Network error'),
        );
      });
    });
  });

  group('Apple Sign In', () {
    group('successful sign in', () {
      test('should emit loading then success with Apple user', () async {
        mockRepository.setupAppleSignInSuccess(user: FakeUsers.appleUser);
        final states = <AuthState>[];
        controller.addListener((state) => states.add(state));

        await controller.signInWithApple();

        expect(states, [isA<AuthStateLoading>(), isA<AuthStateSuccess>()]);
        final user = (controller.state as AuthStateSuccess).user;
        expect(user.provider, equals(AuthProvider.apple));
        expect(user.email, equals(FakeUsers.appleUser.email));
      });
    });

    group('Apple sign in failures', () {
      test('should handle user cancellation gracefully', () async {
        mockRepository.setupAppleSignInFailure(
          TestAuthExceptions.socialSignInCancelled,
        );

        await controller.signInWithApple();

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          equals('Sign in was cancelled.'),
        );
      });

      test('should handle Apple sign in not supported on device', () async {
        mockRepository.setupAppleSignInNotSupported();

        await controller.signInWithApple();

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('not available on this device'),
        );
      });

      test('should handle generic Apple sign in failure', () async {
        mockRepository.setupAppleSignInFailure(
          TestAuthExceptions.appleSignInFailed,
        );

        await controller.signInWithApple();

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('failed'),
        );
      });

      test('should handle network error during Apple sign in', () async {
        mockRepository.setupAppleSignInFailure(TestAuthExceptions.networkError);

        await controller.signInWithApple();

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('Network error'),
        );
      });
    });
  });

  group('Sign Out', () {
    test('should emit loading then idle on successful sign out', () async {
      mockRepository.setupSignOutSuccess();
      final states = <AuthState>[];
      controller.addListener((state) => states.add(state));

      await controller.signOut();

      expect(states, [isA<AuthStateLoading>(), isA<AuthStateIdle>()]);
      expect(controller.state, isA<AuthStateIdle>());
    });

    test('should emit error on sign out failure', () async {
      mockRepository.setupSignOutFailure(TestAuthExceptions.networkError);

      await controller.signOut();

      expect(controller.state, isA<AuthStateError>());
    });

    test('should handle unexpected sign out error gracefully', () async {
      when(() => mockRepository.signOut()).thenThrow(Exception('Unexpected'));

      await controller.signOut();

      expect(controller.state, isA<AuthStateError>());
      expect(
        (controller.state as AuthStateError).message,
        equals('Failed to sign out. Please try again.'),
      );
    });
  });

  group('State transitions', () {
    test(
      'state should transition idle -> loading -> success on successful operation',
      () async {
        mockRepository.setupSignInSuccess();
        final states = <AuthState>[controller.state]; // Include initial state
        controller.addListener((state) => states.add(state));

        await controller.signInWithEmail(
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );

        expect(states.length, equals(3));
        expect(states[0], isA<AuthStateIdle>());
        expect(states[1], isA<AuthStateLoading>());
        expect(states[2], isA<AuthStateSuccess>());
      },
    );

    test(
      'state should transition idle -> loading -> error on failed operation',
      () async {
        mockRepository.setupSignInFailure(TestAuthExceptions.networkError);
        final states = <AuthState>[controller.state];
        controller.addListener((state) => states.add(state));

        await controller.signInWithEmail(
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );

        expect(states.length, equals(3));
        expect(states[0], isA<AuthStateIdle>());
        expect(states[1], isA<AuthStateLoading>());
        expect(states[2], isA<AuthStateError>());
      },
    );

    test('resetState should return to idle from error state', () {
      // Manually set to error state for testing
      controller = AuthController(mockRepository);
      mockRepository.setupSignInFailure(TestAuthExceptions.networkError);

      // Simulate error state by triggering failed sign in synchronously
      controller
          .signInWithEmail(
            email: TestCredentials.validEmail,
            password: TestCredentials.validPassword,
          )
          .then((_) {
            controller.resetState();
            expect(controller.state, isA<AuthStateIdle>());
          });
    });
  });

  group('Duplicate request prevention', () {
    test(
      'should not trigger duplicate sign in requests when already loading',
      () async {
        // Setup a delayed response
        mockRepository.setupSignInWithDelay(
          const Duration(milliseconds: 100),
          user: FakeUsers.testUser,
        );

        // Trigger first request
        final firstRequest = controller.signInWithEmail(
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );

        // Immediately try to trigger second request while first is loading
        final secondRequest = controller.signInWithEmail(
          email: 'other@example.com',
          password: 'otherpass123',
        );

        // Wait for both to complete
        await Future.wait([firstRequest, secondRequest]);

        // Verify only one call was made to repository
        verify(
          () => mockRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).called(1);
      },
    );

    test(
      'should not trigger duplicate sign up requests when already loading',
      () async {
        mockRepository.setupSignUpSuccess();

        // Use a completer to control when the first request completes
        var callCount = 0;
        when(
          () => mockRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return FakeUsers.testUser;
        });

        // Trigger multiple requests rapidly
        final futures = [
          controller.signUpWithEmail(
            email: TestCredentials.validEmail,
            password: TestCredentials.validPassword,
          ),
          controller.signUpWithEmail(
            email: TestCredentials.validEmail,
            password: TestCredentials.validPassword,
          ),
          controller.signUpWithEmail(
            email: TestCredentials.validEmail,
            password: TestCredentials.validPassword,
          ),
        ];

        await Future.wait(futures);

        // Only one actual call should have been made
        expect(callCount, equals(1));
      },
    );

    test('should not trigger duplicate Google sign in requests', () async {
      mockRepository.setupGoogleSignInWithDelay(
        const Duration(milliseconds: 100),
      );

      final first = controller.signInWithGoogle();
      final second = controller.signInWithGoogle();
      final third = controller.signInWithGoogle();

      await Future.wait([first, second, third]);

      verify(() => mockRepository.signInWithGoogle()).called(1);
    });

    test('should not trigger duplicate Apple sign in requests', () async {
      var callCount = 0;
      when(() => mockRepository.signInWithApple()).thenAnswer((_) async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return FakeUsers.appleUser;
      });

      await Future.wait([
        controller.signInWithApple(),
        controller.signInWithApple(),
      ]);

      expect(callCount, equals(1));
    });

    test('should not trigger duplicate sign out requests', () async {
      var callCount = 0;
      when(() => mockRepository.signOut()).thenAnswer((_) async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await Future.wait([
        controller.signOut(),
        controller.signOut(),
        controller.signOut(),
      ]);

      expect(callCount, equals(1));
    });

    test('should allow new request after previous completes', () async {
      mockRepository.setupSignInSuccess();

      // First request
      await controller.signInWithEmail(
        email: TestCredentials.validEmail,
        password: TestCredentials.validPassword,
      );

      // Reset state for second attempt
      controller.resetState();

      // Second request should now be allowed
      await controller.signInWithEmail(
        email: TestCredentials.validEmail,
        password: TestCredentials.validPassword,
      );

      verify(
        () => mockRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).called(2);
    });

    test('isOperationInProgress should be true during loading', () async {
      mockRepository.setupSignInWithDelay(const Duration(milliseconds: 100));

      final future = controller.signInWithEmail(
        email: TestCredentials.validEmail,
        password: TestCredentials.validPassword,
      );

      // Check immediately after starting
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.isOperationInProgress, isTrue);
      expect(controller.state, isA<AuthStateLoading>());

      await future;

      expect(controller.isOperationInProgress, isFalse);
    });
  });

  group('Error messages are human-readable', () {
    test('invalid email error should be user-friendly', () async {
      mockRepository.setupSignUpFailure(TestAuthExceptions.invalidEmail);

      await controller.signUpWithEmail(
        email: TestCredentials.invalidEmailNoAt,
        password: TestCredentials.validPassword,
      );

      final message = (controller.state as AuthStateError).message;
      expect(message, isNot(contains('Exception')));
      expect(message, isNot(contains('Error:')));
      expect(message.length, greaterThan(10));
      expect(message, contains('email'));
    });

    test('weak password error should be user-friendly', () async {
      mockRepository.setupSignUpFailure(TestAuthExceptions.weakPassword);

      await controller.signUpWithEmail(
        email: TestCredentials.validEmail,
        password: TestCredentials.passwordTooShort,
      );

      final message = (controller.state as AuthStateError).message;
      expect(message, contains('8 characters'));
      expect(message, contains('1 number'));
    });

    test('email already exists error should be user-friendly', () async {
      mockRepository.setupSignUpFailure(TestAuthExceptions.emailAlreadyInUse);

      await controller.signUpWithEmail(
        email: TestCredentials.existingEmail,
        password: TestCredentials.validPassword,
      );

      final message = (controller.state as AuthStateError).message;
      expect(message, contains('already exists'));
      expect(message, isNot(contains('AuthException')));
    });

    test('wrong password error should be user-friendly', () async {
      mockRepository.setupSignInFailure(TestAuthExceptions.wrongPassword);

      await controller.signInWithEmail(
        email: TestCredentials.validEmail,
        password: TestCredentials.wrongPassword,
      );

      final message = (controller.state as AuthStateError).message;
      expect(message.toLowerCase(), contains('incorrect'));
      expect(message.toLowerCase(), contains('password'));
    });

    test('network error should be user-friendly', () async {
      mockRepository.setupSignInFailure(TestAuthExceptions.networkError);

      await controller.signInWithEmail(
        email: TestCredentials.validEmail,
        password: TestCredentials.validPassword,
      );

      final message = (controller.state as AuthStateError).message;
      expect(message.toLowerCase(), contains('network'));
      expect(message.toLowerCase(), contains('connection'));
    });

    test('social sign in cancelled should be user-friendly', () async {
      mockRepository.setupGoogleSignInCancelled();

      await controller.signInWithGoogle();

      final message = (controller.state as AuthStateError).message;
      expect(message.toLowerCase(), contains('cancelled'));
      expect(message, isNot(contains('Exception')));
    });

    test('unexpected error should not expose technical details', () async {
      when(
        () => mockRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(StateError('Internal state corruption'));

      await controller.signInWithEmail(
        email: TestCredentials.validEmail,
        password: TestCredentials.validPassword,
      );

      final message = (controller.state as AuthStateError).message;
      expect(message, isNot(contains('StateError')));
      expect(message, isNot(contains('Internal')));
      expect(message, isNot(contains('corruption')));
      expect(
        message,
        equals('An unexpected error occurred. Please try again.'),
      );
    });
  });

  group('Social login failure handling', () {
    test(
      'Google sign in cancellation should not show as error to user',
      () async {
        mockRepository.setupGoogleSignInCancelled();

        await controller.signInWithGoogle();

        // Should still be an error state but with friendly message
        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          equals('Sign in was cancelled.'),
        );
      },
    );

    test(
      'Apple sign in unavailable on Android should show appropriate message',
      () async {
        mockRepository.setupAppleSignInNotSupported();

        await controller.signInWithApple();

        expect(controller.state, isA<AuthStateError>());
        expect(
          (controller.state as AuthStateError).message,
          contains('not available'),
        );
      },
    );

    test('Google services unavailable should suggest alternative', () async {
      mockRepository.setupGoogleSignInFailure(
        TestAuthExceptions.googleUnavailable,
      );

      await controller.signInWithGoogle();

      expect(controller.state, isA<AuthStateError>());
      final message = (controller.state as AuthStateError).message;
      expect(message, contains('unavailable'));
      expect(message, contains('another method'));
    });
  });

  group('AuthState extension methods', () {
    test('isIdle should return true only for idle state', () {
      expect(const AuthStateIdle().isIdle, isTrue);
      expect(const AuthStateLoading().isIdle, isFalse);
      expect(AuthStateSuccess(FakeUsers.testUser).isIdle, isFalse);
      expect(const AuthStateError('error').isIdle, isFalse);
    });

    test('isLoading should return true only for loading state', () {
      expect(const AuthStateIdle().isLoading, isFalse);
      expect(const AuthStateLoading().isLoading, isTrue);
      expect(AuthStateSuccess(FakeUsers.testUser).isLoading, isFalse);
      expect(const AuthStateError('error').isLoading, isFalse);
    });

    test('isSuccess should return true only for success state', () {
      expect(const AuthStateIdle().isSuccess, isFalse);
      expect(const AuthStateLoading().isSuccess, isFalse);
      expect(AuthStateSuccess(FakeUsers.testUser).isSuccess, isTrue);
      expect(const AuthStateError('error').isSuccess, isFalse);
    });

    test('isError should return true only for error state', () {
      expect(const AuthStateIdle().isError, isFalse);
      expect(const AuthStateLoading().isError, isFalse);
      expect(AuthStateSuccess(FakeUsers.testUser).isError, isFalse);
      expect(const AuthStateError('error').isError, isTrue);
    });

    test('user should return user only for success state', () {
      expect(const AuthStateIdle().user, isNull);
      expect(const AuthStateLoading().user, isNull);
      expect(
        AuthStateSuccess(FakeUsers.testUser).user,
        equals(FakeUsers.testUser),
      );
      expect(const AuthStateError('error').user, isNull);
    });

    test('errorMessage should return message only for error state', () {
      expect(const AuthStateIdle().errorMessage, isNull);
      expect(const AuthStateLoading().errorMessage, isNull);
      expect(AuthStateSuccess(FakeUsers.testUser).errorMessage, isNull);
      expect(
        const AuthStateError('test error').errorMessage,
        equals('test error'),
      );
    });
  });

  group('Edge cases', () {
    test('should handle empty email gracefully', () async {
      mockRepository.setupSignInFailure(TestAuthExceptions.invalidEmail);

      await controller.signInWithEmail(
        email: '',
        password: TestCredentials.validPassword,
      );

      expect(controller.state, isA<AuthStateError>());
    });

    test('should handle empty password gracefully', () async {
      mockRepository.setupSignInFailure(TestAuthExceptions.weakPassword);

      await controller.signInWithEmail(
        email: TestCredentials.validEmail,
        password: '',
      );

      expect(controller.state, isA<AuthStateError>());
    });

    test('should handle whitespace-only email', () async {
      mockRepository.setupSignInFailure(TestAuthExceptions.invalidEmail);

      await controller.signInWithEmail(
        email: '   ',
        password: TestCredentials.validPassword,
      );

      expect(controller.state, isA<AuthStateError>());
    });

    test('should handle very long email', () async {
      final longEmail = '${'a' * 500}@example.com';
      mockRepository.setupSignInFailure(TestAuthExceptions.invalidEmail);

      await controller.signInWithEmail(
        email: longEmail,
        password: TestCredentials.validPassword,
      );

      expect(controller.state, isA<AuthStateError>());
    });
  });
}
