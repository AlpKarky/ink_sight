import 'package:test/test.dart';
import 'package:inksight/features/auth/domain/validators/auth_validators.dart';

void main() {
  group('Email validation', () {
    group('valid emails', () {
      test('should accept standard email format', () {
        expect(validateEmail('user@example.com'), isNull);
      });

      test('should accept email with subdomain', () {
        expect(validateEmail('user@mail.example.com'), isNull);
      });

      test('should accept email with plus sign', () {
        expect(validateEmail('user+tag@example.com'), isNull);
      });

      test('should accept email with dots in local part', () {
        expect(validateEmail('first.last@example.com'), isNull);
      });

      test('should accept email with numbers', () {
        expect(validateEmail('user123@example.com'), isNull);
      });

      test('should accept email with hyphen in domain', () {
        expect(validateEmail('user@my-domain.com'), isNull);
      });

      test('should accept email with underscore', () {
        expect(validateEmail('user_name@example.com'), isNull);
      });

      test('should accept single character local part', () {
        expect(validateEmail('a@example.com'), isNull);
      });
    });

    group('invalid emails', () {
      test('should reject empty email', () {
        final error = validateEmail('');
        expect(error, isNotNull);
        expect(error, contains('required'));
      });

      test('should reject email without @ symbol', () {
        final error = validateEmail('userexample.com');
        expect(error, isNotNull);
        expect(error, contains('valid email'));
      });

      test('should reject email without domain', () {
        final error = validateEmail('user@');
        expect(error, isNotNull);
      });

      test('should reject email without local part', () {
        final error = validateEmail('@example.com');
        expect(error, isNotNull);
      });

      test('should reject email with spaces', () {
        final error = validateEmail('user @example.com');
        expect(error, isNotNull);
      });

      test('should reject email with multiple @ symbols', () {
        final error = validateEmail('user@@example.com');
        expect(error, isNotNull);
      });

      test('should reject email with double dots in domain', () {
        final error = validateEmail('user@example..com');
        expect(error, isNotNull);
      });

      test('should reject plaintext string', () {
        final error = validateEmail('not an email');
        expect(error, isNotNull);
      });
    });
  });

  group('Password validation', () {
    group('valid passwords', () {
      test('should accept password with 8 chars and 1 number', () {
        expect(validatePassword('password1'), isNull);
      });

      test('should accept password with multiple numbers', () {
        expect(validatePassword('pass123word'), isNull);
      });

      test('should accept password with special characters', () {
        expect(validatePassword('p@ssw0rd!'), isNull);
      });

      test('should accept very long password', () {
        expect(validatePassword('a' * 100 + '1'), isNull);
      });

      test('should accept password starting with number', () {
        expect(validatePassword('1password'), isNull);
      });

      test('should accept password ending with number', () {
        expect(validatePassword('password1'), isNull);
      });

      test('should accept password with only numbers if long enough', () {
        expect(validatePassword('12345678'), isNull);
      });

      test('should accept password with spaces', () {
        expect(validatePassword('pass word1'), isNull);
      });
    });

    group('invalid passwords', () {
      test('should reject empty password', () {
        final error = validatePassword('');
        expect(error, isNotNull);
        expect(error, contains('required'));
      });

      test('should reject password shorter than 8 characters', () {
        final error = validatePassword('pass1');
        expect(error, isNotNull);
        expect(error, contains('8 characters'));
      });

      test('should reject password with 7 characters', () {
        final error = validatePassword('passwor1');
        // This is exactly 8 chars, should pass
        expect(validatePassword('passwor1'), isNull);
        // 7 chars should fail
        expect(validatePassword('passwo1'), isNotNull);
      });

      test('should reject password without any number', () {
        final error = validatePassword('password');
        expect(error, isNotNull);
        expect(error, contains('number'));
      });

      test('should reject long password without number', () {
        final error = validatePassword('verylongpasswordwithoutnumber');
        expect(error, isNotNull);
        expect(error, contains('number'));
      });

      test('should reject password that is just spaces', () {
        final error = validatePassword('        ');
        expect(error, isNotNull);
      });
    });

    group('boundary conditions', () {
      test('should accept exactly 8 characters with number', () {
        expect(validatePassword('abcdefg1'), isNull);
      });

      test('should reject exactly 7 characters with number', () {
        expect(validatePassword('abcdef1'), isNotNull);
      });

      test('should require at least 1 number (not more)', () {
        expect(validatePassword('password1'), isNull);
        expect(validatePassword('password12'), isNull);
        expect(validatePassword('password'), isNotNull);
      });
    });
  });

  group('Password confirmation validation', () {
    test('should accept matching passwords', () {
      expect(
        validatePasswordConfirmation('password123', 'password123'),
        isNull,
      );
    });

    test('should reject empty confirmation', () {
      final error = validatePasswordConfirmation('password123', '');
      expect(error, isNotNull);
      expect(error, contains('confirm'));
    });

    test('should reject mismatched passwords', () {
      final error = validatePasswordConfirmation('password123', 'password124');
      expect(error, isNotNull);
      expect(error, contains('do not match'));
    });

    test('should be case sensitive', () {
      final error = validatePasswordConfirmation('Password1', 'password1');
      expect(error, isNotNull);
    });

    test('should detect whitespace differences', () {
      final error = validatePasswordConfirmation('password1', 'password1 ');
      expect(error, isNotNull);
    });
  });

  group('Sign up credentials validation', () {
    test('should return valid result for valid credentials', () {
      final result = validateSignUpCredentials(
        email: 'user@example.com',
        password: 'password123',
      );
      expect(result.isValid, isTrue);
      expect(result.emailError, isNull);
      expect(result.passwordError, isNull);
    });

    test('should return email error for invalid email', () {
      final result = validateSignUpCredentials(
        email: 'invalid-email',
        password: 'password123',
      );
      expect(result.isValid, isFalse);
      expect(result.emailError, isNotNull);
      expect(result.passwordError, isNull);
    });

    test('should return password error for invalid password', () {
      final result = validateSignUpCredentials(
        email: 'user@example.com',
        password: 'short',
      );
      expect(result.isValid, isFalse);
      expect(result.emailError, isNull);
      expect(result.passwordError, isNotNull);
    });

    test('should return both errors when both are invalid', () {
      final result = validateSignUpCredentials(
        email: 'invalid',
        password: 'short',
      );
      expect(result.isValid, isFalse);
      expect(result.emailError, isNotNull);
      expect(result.passwordError, isNotNull);
    });

    test('should return invalid for empty credentials', () {
      final result = validateSignUpCredentials(email: '', password: '');
      expect(result.isValid, isFalse);
      expect(result.emailError, isNotNull);
      expect(result.passwordError, isNotNull);
    });
  });

  group('Error message quality', () {
    test('email error messages should be user-friendly', () {
      final error = validateEmail('');
      expect(error, isNotNull);
      expect(error!.length, greaterThan(5));
      expect(error, isNot(contains('null')));
      expect(error, isNot(contains('Exception')));
    });

    test('password error messages should be user-friendly', () {
      final error = validatePassword('short');
      expect(error, isNotNull);
      expect(error!.length, greaterThan(10));
      expect(error, isNot(contains('null')));
      expect(error, isNot(contains('Exception')));
    });

    test('password error should explain requirements', () {
      final error = validatePassword('password');
      expect(error, isNotNull);
      expect(error, contains('number'));
    });

    test('confirmation error should be clear', () {
      final error = validatePasswordConfirmation('pass1', 'pass2');
      expect(error, isNotNull);
      expect(error!.toLowerCase(), contains('match'));
    });
  });
}
