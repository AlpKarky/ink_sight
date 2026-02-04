import 'package:test/test.dart';
import 'package:inksight/features/auth/domain/models/user.dart';
import 'package:inksight/features/auth/domain/models/auth_state.dart';

void main() {
  group('User model', () {
    test('should create user with all required fields', () {
      const user = User(
        id: 'test-id',
        email: 'test@example.com',
        provider: AuthProvider.email,
      );
      expect(user.id, equals('test-id'));
      expect(user.email, equals('test@example.com'));
      expect(user.provider, equals(AuthProvider.email));
    });

    test('should create user with optional fields', () {
      const user = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        provider: AuthProvider.google,
      );
      expect(user.displayName, equals('Test User'));
      expect(user.photoUrl, equals('https://example.com/photo.jpg'));
    });

    test('optional fields should default to null', () {
      const user = User(
        id: 'test-id',
        email: 'test@example.com',
        provider: AuthProvider.email,
      );
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
    });

    group('equality', () {
      test('users with same values should be equal', () {
        const user1 = User(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test',
          provider: AuthProvider.email,
        );
        const user2 = User(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test',
          provider: AuthProvider.email,
        );
        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('users with different ids should not be equal', () {
        const user1 = User(
          id: 'id-1',
          email: 'test@example.com',
          provider: AuthProvider.email,
        );
        const user2 = User(
          id: 'id-2',
          email: 'test@example.com',
          provider: AuthProvider.email,
        );
        expect(user1, isNot(equals(user2)));
      });

      test('users with different emails should not be equal', () {
        const user1 = User(
          id: 'test-id',
          email: 'user1@example.com',
          provider: AuthProvider.email,
        );
        const user2 = User(
          id: 'test-id',
          email: 'user2@example.com',
          provider: AuthProvider.email,
        );
        expect(user1, isNot(equals(user2)));
      });

      test('users with different providers should not be equal', () {
        const user1 = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
        );
        const user2 = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.google,
        );
        expect(user1, isNot(equals(user2)));
      });
    });

    test('toString should include key information', () {
      const user = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        provider: AuthProvider.google,
      );
      final string = user.toString();
      expect(string, contains('test-id'));
      expect(string, contains('test@example.com'));
      expect(string, contains('Test User'));
      expect(string, contains('google'));
    });
  });

  group('AuthProvider enum', () {
    test('should have all expected providers', () {
      expect(AuthProvider.values, contains(AuthProvider.email));
      expect(AuthProvider.values, contains(AuthProvider.google));
      expect(AuthProvider.values, contains(AuthProvider.apple));
    });

    test('should have exactly 3 providers', () {
      expect(AuthProvider.values.length, equals(3));
    });
  });

  group('AuthState', () {
    group('AuthStateIdle', () {
      test('should be equal to another idle state', () {
        const state1 = AuthStateIdle();
        const state2 = AuthStateIdle();
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('toString should return descriptive string', () {
        expect(const AuthStateIdle().toString(), contains('idle'));
      });
    });

    group('AuthStateLoading', () {
      test('should be equal to another loading state', () {
        const state1 = AuthStateLoading();
        const state2 = AuthStateLoading();
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('toString should return descriptive string', () {
        expect(const AuthStateLoading().toString(), contains('loading'));
      });
    });

    group('AuthStateSuccess', () {
      test('should contain user', () {
        const user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
        );
        final state = AuthStateSuccess(user);
        expect(state.user, equals(user));
      });

      test('should be equal when users are equal', () {
        const user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
        );
        final state1 = AuthStateSuccess(user);
        final state2 = AuthStateSuccess(user);
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('should not be equal when users differ', () {
        const user1 = User(
          id: 'id-1',
          email: 'test@example.com',
          provider: AuthProvider.email,
        );
        const user2 = User(
          id: 'id-2',
          email: 'test@example.com',
          provider: AuthProvider.email,
        );
        final state1 = AuthStateSuccess(user1);
        final state2 = AuthStateSuccess(user2);
        expect(state1, isNot(equals(state2)));
      });

      test('toString should include user info', () {
        const user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
        );
        final state = AuthStateSuccess(user);
        expect(state.toString(), contains('success'));
        expect(state.toString(), contains('user'));
      });
    });

    group('AuthStateError', () {
      test('should contain message', () {
        const state = AuthStateError('Test error message');
        expect(state.message, equals('Test error message'));
      });

      test('should be equal when messages are equal', () {
        const state1 = AuthStateError('Same message');
        const state2 = AuthStateError('Same message');
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('should not be equal when messages differ', () {
        const state1 = AuthStateError('Message 1');
        const state2 = AuthStateError('Message 2');
        expect(state1, isNot(equals(state2)));
      });

      test('toString should include message', () {
        const state = AuthStateError('Test error');
        expect(state.toString(), contains('error'));
        expect(state.toString(), contains('Test error'));
      });
    });

    group('state type checking', () {
      test('different state types should not be equal', () {
        const idle = AuthStateIdle();
        const loading = AuthStateLoading();
        const success = AuthStateSuccess(
          User(id: 'id', email: 'email', provider: AuthProvider.email),
        );
        const error = AuthStateError('error');

        expect(idle, isNot(equals(loading)));
        expect(idle, isNot(equals(success)));
        expect(idle, isNot(equals(error)));
        expect(loading, isNot(equals(success)));
        expect(loading, isNot(equals(error)));
        expect(success, isNot(equals(error)));
      });
    });

    group('sealed class pattern matching', () {
      test('should support exhaustive switch', () {
        AuthState state = const AuthStateIdle();

        final result = switch (state) {
          AuthStateIdle() => 'idle',
          AuthStateLoading() => 'loading',
          AuthStateSuccess(:final user) => 'success: ${user.email}',
          AuthStateError(:final message) => 'error: $message',
        };

        expect(result, equals('idle'));
      });

      test('should destructure success state', () {
        const user = User(
          id: 'test-id',
          email: 'test@example.com',
          provider: AuthProvider.email,
        );
        AuthState state = AuthStateSuccess(user);

        final email = switch (state) {
          AuthStateSuccess(:final user) => user.email,
          _ => null,
        };

        expect(email, equals('test@example.com'));
      });

      test('should destructure error state', () {
        AuthState state = const AuthStateError('Test error message');

        final message = switch (state) {
          AuthStateError(:final message) => message,
          _ => null,
        };

        expect(message, equals('Test error message'));
      });
    });
  });

  group('AuthStateX extension', () {
    const user = User(
      id: 'test-id',
      email: 'test@example.com',
      provider: AuthProvider.email,
    );

    test('user getter should return user only from success state', () {
      expect(const AuthStateIdle().user, isNull);
      expect(const AuthStateLoading().user, isNull);
      expect(AuthStateSuccess(user).user, equals(user));
      expect(const AuthStateError('error').user, isNull);
    });

    test('errorMessage getter should return message only from error state', () {
      expect(const AuthStateIdle().errorMessage, isNull);
      expect(const AuthStateLoading().errorMessage, isNull);
      expect(AuthStateSuccess(user).errorMessage, isNull);
      expect(const AuthStateError('test').errorMessage, equals('test'));
    });
  });
}
