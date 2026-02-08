import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main.dart';
import '../domain/auth_repository.dart';

/// Provides the auth repository instance.
/// Currently returns FakeAuthRepository for development.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FakeAuthRepository();
});
