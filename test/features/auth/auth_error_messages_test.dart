import 'package:test/test.dart';
import 'package:inksight/features/auth/domain/repositories/auth_repository.dart';

void main() {
  group('Human-readable error messages', () {
    test('all error codes should have human-readable messages', () {
      for (final code in AuthErrorCode.values) {
        final message = getHumanReadableAuthError(code);
        expect(message, isNotEmpty);
        expect(
          message.length,
          greaterThan(10),
          reason: 'Message for $code should be descriptive',
        );
      }
    });

    test('messages should not contain technical terms', () {
      for (final code in AuthErrorCode.values) {
        final message = getHumanReadableAuthError(code);
        expect(
          message,
          isNot(contains('Exception')),
          reason: 'Message for $code should not mention Exception',
        );
        expect(
          message,
          isNot(contains('null')),
          reason: 'Message for $code should not mention null',
        );
        expect(
          message,
          isNot(contains('Error:')),
          reason: 'Message for $code should not start with Error:',
        );
      }
    });

    test('messages should end with proper punctuation', () {
      for (final code in AuthErrorCode.values) {
        final message = getHumanReadableAuthError(code);
        expect(
          message.endsWith('.') ||
              message.endsWith('!') ||
              message.endsWith('?'),
          isTrue,
          reason: 'Message for $code should end with punctuation',
        );
      }
    });

    group('specific error code messages', () {
      test('invalidEmail should mention email', () {
        final message = getHumanReadableAuthError(AuthErrorCode.invalidEmail);
        expect(message.toLowerCase(), contains('email'));
      });

      test('weakPassword should explain requirements', () {
        final message = getHumanReadableAuthError(AuthErrorCode.weakPassword);
        expect(message, contains('8'));
        expect(message, contains('number'));
      });

      test('emailAlreadyInUse should explain the issue', () {
        final message = getHumanReadableAuthError(
          AuthErrorCode.emailAlreadyInUse,
        );
        expect(message.toLowerCase(), contains('already'));
      });

      test('userNotFound should suggest signing up', () {
        final message = getHumanReadableAuthError(AuthErrorCode.userNotFound);
        expect(message.toLowerCase(), contains('sign up'));
      });

      test('wrongPassword should be encouraging', () {
        final message = getHumanReadableAuthError(AuthErrorCode.wrongPassword);
        expect(message.toLowerCase(), contains('try again'));
      });

      test('networkError should mention connection', () {
        final message = getHumanReadableAuthError(AuthErrorCode.networkError);
        expect(message.toLowerCase(), contains('connection'));
      });

      test('socialSignInCancelled should be neutral', () {
        final message = getHumanReadableAuthError(
          AuthErrorCode.socialSignInCancelled,
        );
        expect(message.toLowerCase(), contains('cancel'));
        expect(
          message.length,
          lessThan(50),
          reason: 'Cancellation message should be brief',
        );
      });

      test('googleSignInUnavailable should suggest alternative', () {
        final message = getHumanReadableAuthError(
          AuthErrorCode.googleSignInUnavailable,
        );
        expect(
          message.toLowerCase(),
          anyOf(
            contains('another'),
            contains('alternative'),
            contains('other'),
          ),
        );
      });

      test('appleSignInNotSupported should explain limitation', () {
        final message = getHumanReadableAuthError(
          AuthErrorCode.appleSignInNotSupported,
        );
        expect(message.toLowerCase(), contains('not available'));
      });

      test('tooManyRequests should ask to wait', () {
        final message = getHumanReadableAuthError(
          AuthErrorCode.tooManyRequests,
        );
        expect(message.toLowerCase(), contains('wait'));
      });
    });
  });

  group('AuthException', () {
    test('should contain code and message', () {
      const exception = AuthException(
        code: AuthErrorCode.invalidEmail,
        message: 'Test message',
      );
      expect(exception.code, equals(AuthErrorCode.invalidEmail));
      expect(exception.message, equals('Test message'));
    });

    test('toString should include both code and message', () {
      const exception = AuthException(
        code: AuthErrorCode.networkError,
        message: 'Network failure',
      );
      final string = exception.toString();
      expect(string, contains('networkError'));
      expect(string, contains('Network failure'));
    });

    test('should implement Exception interface', () {
      const exception = AuthException(
        code: AuthErrorCode.unknown,
        message: 'Unknown error',
      );
      expect(exception, isA<Exception>());
    });
  });

  group('Error code coverage', () {
    test('should have error codes for all email/password scenarios', () {
      expect(AuthErrorCode.values, contains(AuthErrorCode.invalidEmail));
      expect(AuthErrorCode.values, contains(AuthErrorCode.weakPassword));
      expect(AuthErrorCode.values, contains(AuthErrorCode.emailAlreadyInUse));
      expect(AuthErrorCode.values, contains(AuthErrorCode.userNotFound));
      expect(AuthErrorCode.values, contains(AuthErrorCode.wrongPassword));
      expect(AuthErrorCode.values, contains(AuthErrorCode.invalidCredentials));
    });

    test('should have error codes for social sign-in scenarios', () {
      expect(
        AuthErrorCode.values,
        contains(AuthErrorCode.socialSignInCancelled),
      );
      expect(AuthErrorCode.values, contains(AuthErrorCode.socialSignInFailed));
      expect(
        AuthErrorCode.values,
        contains(AuthErrorCode.googleSignInUnavailable),
      );
      expect(
        AuthErrorCode.values,
        contains(AuthErrorCode.appleSignInUnavailable),
      );
      expect(
        AuthErrorCode.values,
        contains(AuthErrorCode.appleSignInNotSupported),
      );
    });

    test('should have error codes for general errors', () {
      expect(AuthErrorCode.values, contains(AuthErrorCode.networkError));
      expect(AuthErrorCode.values, contains(AuthErrorCode.tooManyRequests));
      expect(AuthErrorCode.values, contains(AuthErrorCode.operationNotAllowed));
      expect(AuthErrorCode.values, contains(AuthErrorCode.unknown));
    });
  });
}
