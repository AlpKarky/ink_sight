import 'package:mocktail/mocktail.dart';
import 'package:inksight/features/auth/domain/models/user.dart';
import 'package:inksight/features/auth/domain/repositories/auth_repository.dart';

/// Mock implementation of [AuthRepository] for testing.
///
/// Uses mocktail for flexible mocking of authentication operations.
class MockAuthRepository extends Mock implements AuthRepository {}

/// Fake user data for testing.
class FakeUsers {
  static const testUser = User(
    id: 'test-user-id-123',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: null,
    provider: AuthProvider.email,
  );

  static const googleUser = User(
    id: 'google-user-id-456',
    email: 'google@example.com',
    displayName: 'Google User',
    photoUrl: 'https://example.com/photo.jpg',
    provider: AuthProvider.google,
  );

  static const appleUser = User(
    id: 'apple-user-id-789',
    email: 'apple@example.com',
    displayName: 'Apple User',
    photoUrl: null,
    provider: AuthProvider.apple,
  );
}

/// Test credentials constants.
class TestCredentials {
  // Valid credentials
  static const validEmail = 'valid@example.com';
  static const validPassword = 'password123';

  // Invalid email formats
  static const invalidEmailNoAt = 'invalidemail.com';
  static const invalidEmailNoDomain = 'invalid@';
  static const invalidEmailEmpty = '';
  static const invalidEmailSpaces = 'invalid email@example.com';

  // Invalid passwords
  static const passwordTooShort = 'pass1';
  static const passwordNoNumber = 'passwordonly';
  static const passwordEmpty = '';

  // Non-existent user
  static const nonExistentEmail = 'nonexistent@example.com';

  // Already registered user
  static const existingEmail = 'existing@example.com';

  // Wrong password
  static const wrongPassword = 'wrongpass123';
}

/// Helper extensions for setting up mock behaviors.
extension MockAuthRepositoryExtensions on MockAuthRepository {
  /// Sets up successful email sign up.
  void setupSignUpSuccess({User? user}) {
    when(
      () => signUpWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => user ?? FakeUsers.testUser);
  }

  /// Sets up email sign up failure with specific error.
  void setupSignUpFailure(AuthException exception) {
    when(
      () => signUpWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(exception);
  }

  /// Sets up email sign up to throw for specific email (email already exists scenario).
  void setupSignUpEmailAlreadyExists(String existingEmail) {
    when(
      () => signUpWithEmail(
        email: existingEmail,
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const AuthException(
        code: AuthErrorCode.emailAlreadyInUse,
        message: 'An account with this email already exists.',
      ),
    );
  }

  /// Sets up successful email sign in.
  void setupSignInSuccess({User? user}) {
    when(
      () => signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => user ?? FakeUsers.testUser);
  }

  /// Sets up email sign in failure with specific error.
  void setupSignInFailure(AuthException exception) {
    when(
      () => signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(exception);
  }

  /// Sets up sign in to fail for wrong credentials.
  void setupSignInWrongCredentials() {
    when(
      () => signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const AuthException(
        code: AuthErrorCode.invalidCredentials,
        message: 'Invalid email or password. Please check your credentials.',
      ),
    );
  }

  /// Sets up successful Google sign in.
  void setupGoogleSignInSuccess({User? user}) {
    when(
      () => signInWithGoogle(),
    ).thenAnswer((_) async => user ?? FakeUsers.googleUser);
  }

  /// Sets up Google sign in failure.
  void setupGoogleSignInFailure(AuthException exception) {
    when(() => signInWithGoogle()).thenThrow(exception);
  }

  /// Sets up Google sign in cancellation.
  void setupGoogleSignInCancelled() {
    when(() => signInWithGoogle()).thenThrow(
      const AuthException(
        code: AuthErrorCode.socialSignInCancelled,
        message: 'Sign in was cancelled.',
      ),
    );
  }

  /// Sets up successful Apple sign in.
  void setupAppleSignInSuccess({User? user}) {
    when(
      () => signInWithApple(),
    ).thenAnswer((_) async => user ?? FakeUsers.appleUser);
  }

  /// Sets up Apple sign in failure.
  void setupAppleSignInFailure(AuthException exception) {
    when(() => signInWithApple()).thenThrow(exception);
  }

  /// Sets up Apple sign in not supported (e.g., Android device).
  void setupAppleSignInNotSupported() {
    when(() => signInWithApple()).thenThrow(
      const AuthException(
        code: AuthErrorCode.appleSignInNotSupported,
        message: 'Apple sign in is not available on this device.',
      ),
    );
  }

  /// Sets up successful sign out.
  void setupSignOutSuccess() {
    when(() => signOut()).thenAnswer((_) async {});
  }

  /// Sets up sign out failure.
  void setupSignOutFailure(AuthException exception) {
    when(() => signOut()).thenThrow(exception);
  }

  /// Sets up a delayed response to simulate network latency.
  void setupSignInWithDelay(Duration delay, {User? user}) {
    when(
      () => signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {
      await Future.delayed(delay);
      return user ?? FakeUsers.testUser;
    });
  }

  /// Sets up Google sign in with delay.
  void setupGoogleSignInWithDelay(Duration delay, {User? user}) {
    when(() => signInWithGoogle()).thenAnswer((_) async {
      await Future.delayed(delay);
      return user ?? FakeUsers.googleUser;
    });
  }
}
