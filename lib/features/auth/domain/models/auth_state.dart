import 'user.dart';

/// Represents the current state of authentication.
///
/// This is a sealed class to ensure exhaustive pattern matching
/// and type-safe state handling.
sealed class AuthState {
  const AuthState();
}

/// Initial state - no authentication operation in progress.
class AuthStateIdle extends AuthState {
  const AuthStateIdle();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthStateIdle;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AuthState.idle';
}

/// Authentication operation is in progress.
class AuthStateLoading extends AuthState {
  const AuthStateLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthStateLoading;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AuthState.loading';
}

/// Authentication succeeded with the given user.
class AuthStateSuccess extends AuthState {
  final User user;

  const AuthStateSuccess(this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthStateSuccess &&
          runtimeType == other.runtimeType &&
          user == other.user;

  @override
  int get hashCode => user.hashCode;

  @override
  String toString() => 'AuthState.success(user: $user)';
}

/// Authentication failed with the given error message.
///
/// The [message] should be human-readable and suitable for display to users.
class AuthStateError extends AuthState {
  final String message;

  const AuthStateError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthStateError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'AuthState.error(message: $message)';
}

/// Extension for convenient state checks.
extension AuthStateX on AuthState {
  bool get isIdle => this is AuthStateIdle;
  bool get isLoading => this is AuthStateLoading;
  bool get isSuccess => this is AuthStateSuccess;
  bool get isError => this is AuthStateError;

  User? get user => switch (this) {
    AuthStateSuccess(:final user) => user,
    _ => null,
  };

  String? get errorMessage => switch (this) {
    AuthStateError(:final message) => message,
    _ => null,
  };
}
