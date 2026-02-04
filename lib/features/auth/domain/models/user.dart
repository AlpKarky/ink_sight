/// Represents an authenticated user in the system.
///
/// This is the domain model returned upon successful authentication.
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final AuthProvider provider;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          provider == other.provider;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      photoUrl.hashCode ^
      provider.hashCode;

  @override
  String toString() =>
      'User(id: $id, email: $email, displayName: $displayName, provider: $provider)';
}

/// The authentication provider used to sign in.
enum AuthProvider { email, google, apple }
