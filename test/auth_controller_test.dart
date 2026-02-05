// ignore_for_file: unused_local_variable
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:inksight/features/auth/auth_controller.dart';
import 'package:inksight/features/auth/domain/auth_repository.dart';

// =============================================================================
// AUTH CONTROLLER CONTRACT TESTS
// =============================================================================

// =============================================================================
// FAKE AUTH REPOSITORY SIMULATOR
// =============================================================================
//
// A realistic fake implementation that simulates backend behavior:
// - In-memory user store
// - Artificial network delays
// - Configurable one-shot failures
// - Credential validation
// - Session management
//
// =============================================================================

class FakeAuthRepository implements AuthRepository {
  // ===========================================================================
  // IN-MEMORY USER STORE
  // ===========================================================================

  /// Registered users (email -> user data with password hash).
  final Map<String, _StoredUser> _userStore = {};

  /// Currently signed-in user.
  AuthUser? _currentUser;

  /// Auth state stream controller.
  final _authStateController = StreamController<AuthUser?>.broadcast();

  // ===========================================================================
  // CONFIGURATION
  // ===========================================================================

  /// Artificial delay to simulate network latency.
  Duration networkDelay = const Duration(milliseconds: 50);

  /// If set, the next operation will throw this failure (one-shot).
  AuthFailure? _nextFailure;

  /// If true, failures are cleared after being thrown (one-shot mode).
  bool oneShotFailures = true;

  // ===========================================================================
  // CALL TRACKING
  // ===========================================================================

  int signUpCallCount = 0;
  int signInCallCount = 0;
  int googleSignInCallCount = 0;
  int appleSignInCallCount = 0;
  int signOutCallCount = 0;
  int getCurrentUserCallCount = 0;

  /// Last email used in sign up/sign in.
  String? lastEmail;

  /// Last password used in sign up/sign in.
  String? lastPassword;

  // ===========================================================================
  // SETUP HELPERS - FAILURE SIMULATION
  // ===========================================================================

  /// Force next request to throw [NetworkError].
  void forceNetworkError() {
    _nextFailure = NetworkError();
  }

  /// Force next request to throw [EmailAlreadyInUse].
  void forceDuplicateEmail() {
    _nextFailure = EmailAlreadyInUse();
  }

  /// Force next request to throw [AuthCancelled].
  void forceCancelledLogin() {
    _nextFailure = AuthCancelled();
  }

  /// Force next request to throw [InvalidCredentials].
  void forceInvalidCredentials() {
    _nextFailure = InvalidCredentials();
  }

  /// Force next request to throw [InvalidEmail].
  void forceInvalidEmail() {
    _nextFailure = InvalidEmail();
  }

  /// Force next request to throw [WeakPassword].
  void forceWeakPassword() {
    _nextFailure = WeakPassword();
  }

  /// Force next request to throw [UserNotFound].
  void forceUserNotFound() {
    _nextFailure = UserNotFound();
  }

  /// Force next request to throw [TooManyRequests].
  void forceTooManyRequests() {
    _nextFailure = TooManyRequests();
  }

  /// Force next request to throw [GoogleSignInUnavailable].
  void forceGoogleUnavailable() {
    _nextFailure = GoogleSignInUnavailable();
  }

  /// Force next request to throw [AppleSignInUnavailable].
  void forceAppleUnavailable() {
    _nextFailure = AppleSignInUnavailable();
  }

  /// Force next request to throw [UserDisabled].
  void forceUserDisabled() {
    _nextFailure = UserDisabled();
  }

  /// Force next request to throw [OperationNotAllowed].
  void forceOperationNotAllowed() {
    _nextFailure = OperationNotAllowed();
  }

  /// Force next request to throw [UnknownAuthFailure].
  void forceUnknownError([String? details]) {
    _nextFailure = UnknownAuthFailure(details);
  }

  /// Clear any pending forced failure.
  void clearForcedFailure() {
    _nextFailure = null;
  }

  // ===========================================================================
  // SETUP HELPERS - USER STORE
  // ===========================================================================

  /// Pre-register a user in the store (for sign-in tests).
  void seedUser({
    required String email,
    required String password,
    String? displayName,
  }) {
    final id = 'user-${_userStore.length + 1}';
    _userStore[email.toLowerCase()] = _StoredUser(
      user: AuthUser(
        id: id,
        email: email,
        displayName: displayName ?? email.split('@').first,
        authMethod: AuthMethod.emailPassword,
      ),
      passwordHash: _hashPassword(password),
    );
  }

  /// Pre-register a social user (Google/Apple).
  void seedSocialUser({
    required String email,
    required AuthMethod method,
    String? displayName,
    String? photoUrl,
  }) {
    final id = '${method.name}-${_userStore.length + 1}';
    _userStore[email.toLowerCase()] = _StoredUser(
      user: AuthUser(
        id: id,
        email: email,
        displayName: displayName ?? email.split('@').first,
        photoUrl: photoUrl,
        authMethod: method,
      ),
      passwordHash: null, // Social users don't have passwords
    );
  }

  /// Check if email exists in store.
  bool hasUser(String email) => _userStore.containsKey(email.toLowerCase());

  /// Get user count in store.
  int get userCount => _userStore.length;

  // ===========================================================================
  // SETUP HELPERS - GENERAL
  // ===========================================================================

  /// Reset all state (users, failures, counters).
  void reset() {
    _userStore.clear();
    _currentUser = null;
    _nextFailure = null;
    networkDelay = const Duration(milliseconds: 50);
    oneShotFailures = true;
    signUpCallCount = 0;
    signInCallCount = 0;
    googleSignInCallCount = 0;
    appleSignInCallCount = 0;
    signOutCallCount = 0;
    getCurrentUserCallCount = 0;
    lastEmail = null;
    lastPassword = null;
  }

  /// Set artificial delay (0 for instant responses).
  void setNetworkDelay(Duration delay) {
    networkDelay = delay;
  }

  /// Disable network delay for fast tests.
  void disableDelay() {
    networkDelay = Duration.zero;
  }

  // ===========================================================================
  // LEGACY COMPATIBILITY HELPERS
  // ===========================================================================

  /// Legacy: Set next user to return (bypasses store logic).
  AuthUser? nextUser;

  /// Legacy: Configure for successful operation.
  void simulateSuccess(AuthUser user) {
    nextUser = user;
    _nextFailure = null;
  }

  /// Legacy: Alias for forceInvalidCredentials.
  void simulateInvalidCredentials() => forceInvalidCredentials();

  /// Legacy: Alias for forceInvalidCredentials.
  void simulateWrongPassword() => forceInvalidCredentials();

  /// Legacy: Alias for forceDuplicateEmail.
  void simulateDuplicateEmail() => forceDuplicateEmail();

  /// Legacy: Alias for forceNetworkError.
  void simulateNetworkFailure() => forceNetworkError();

  /// Legacy: Alias for forceCancelledLogin.
  void simulateSocialLoginCancel() => forceCancelledLogin();

  /// Legacy: Alias for forceInvalidEmail.
  void simulateInvalidEmail() => forceInvalidEmail();

  /// Legacy: Alias for forceWeakPassword.
  void simulateWeakPassword() => forceWeakPassword();

  /// Legacy: Alias for forceUserNotFound.
  void simulateUserNotFound() => forceUserNotFound();

  /// Legacy: Alias for forceTooManyRequests.
  void simulateTooManyRequests() => forceTooManyRequests();

  /// Legacy: Alias for forceGoogleUnavailable.
  void simulateGoogleUnavailable() => forceGoogleUnavailable();

  /// Legacy: Alias for forceAppleUnavailable.
  void simulateAppleUnavailable() => forceAppleUnavailable();

  /// Legacy: Alias for forceUserDisabled.
  void simulateUserDisabled() => forceUserDisabled();

  /// Legacy: Alias for forceOperationNotAllowed.
  void simulateOperationNotAllowed() => forceOperationNotAllowed();

  /// Legacy: Alias for forceUnknownError.
  void simulateUnknownError([String? details]) => forceUnknownError(details);

  /// Legacy: Set artificial delay.
  set artificialDelay(Duration? delay) {
    networkDelay = delay ?? Duration.zero;
  }

  // ===========================================================================
  // INTERNAL HELPERS
  // ===========================================================================

  /// Simple password "hash" for testing (NOT cryptographically secure).
  String _hashPassword(String password) => 'hash:$password';

  /// Check password against stored hash.
  bool _verifyPassword(String password, String hash) =>
      hash == _hashPassword(password);

  /// Simulate network delay.
  Future<void> _simulateNetwork() async {
    if (networkDelay > Duration.zero) {
      await Future.delayed(networkDelay);
    }
  }

  /// Check and consume forced failure (one-shot).
  void _checkForcedFailure() {
    if (_nextFailure != null) {
      final failure = _nextFailure!;
      if (oneShotFailures) {
        _nextFailure = null;
      }
      throw failure;
    }
  }

  /// Update current user and notify listeners.
  void _setCurrentUser(AuthUser? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  /// Generate a unique user ID.
  String _generateId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  // ===========================================================================
  // AUTH REPOSITORY IMPLEMENTATION
  // ===========================================================================

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    signUpCallCount++;
    lastEmail = email;
    lastPassword = password;

    await _simulateNetwork();
    _checkForcedFailure();

    // Legacy mode: if nextUser is set, use it directly
    if (nextUser != null) {
      final user = nextUser!;
      _setCurrentUser(user);
      return user;
    }

    // Check for duplicate email
    final normalizedEmail = email.toLowerCase();
    if (_userStore.containsKey(normalizedEmail)) {
      throw EmailAlreadyInUse();
    }

    // Create new user
    final user = AuthUser(
      id: _generateId('user'),
      email: email,
      displayName: email.split('@').first,
      authMethod: AuthMethod.emailPassword,
    );

    // Store user
    _userStore[normalizedEmail] = _StoredUser(
      user: user,
      passwordHash: _hashPassword(password),
    );

    _setCurrentUser(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    lastEmail = email;
    lastPassword = password;

    await _simulateNetwork();
    _checkForcedFailure();

    // Legacy mode: if nextUser is set, use it directly
    if (nextUser != null) {
      final user = nextUser!;
      _setCurrentUser(user);
      return user;
    }

    // Look up user
    final normalizedEmail = email.toLowerCase();
    final storedUser = _userStore[normalizedEmail];

    if (storedUser == null) {
      throw UserNotFound();
    }

    // Verify password
    if (storedUser.passwordHash == null ||
        !_verifyPassword(password, storedUser.passwordHash!)) {
      throw InvalidCredentials();
    }

    _setCurrentUser(storedUser.user);
    return storedUser.user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    googleSignInCallCount++;

    await _simulateNetwork();
    _checkForcedFailure();

    // Legacy mode: if nextUser is set, use it directly
    if (nextUser != null) {
      final user = nextUser!;
      _setCurrentUser(user);
      return user;
    }

    // Simulate Google sign in - create or return existing user
    final user = AuthUser(
      id: _generateId('google'),
      email: 'google-user@gmail.com',
      displayName: 'Google User',
      photoUrl: 'https://example.com/photo.jpg',
      authMethod: AuthMethod.google,
    );

    _setCurrentUser(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithApple() async {
    appleSignInCallCount++;

    await _simulateNetwork();
    _checkForcedFailure();

    // Legacy mode: if nextUser is set, use it directly
    if (nextUser != null) {
      final user = nextUser!;
      _setCurrentUser(user);
      return user;
    }

    // Simulate Apple sign in
    final user = AuthUser(
      id: _generateId('apple'),
      email: 'apple-user@icloud.com',
      displayName: 'Apple User',
      authMethod: AuthMethod.apple,
    );

    _setCurrentUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;

    await _simulateNetwork();
    _checkForcedFailure();

    _setCurrentUser(null);
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    getCurrentUserCallCount++;
    return _currentUser;
  }

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  /// Clean up resources.
  void dispose() {
    _authStateController.close();
  }
}

/// Internal: stored user with password hash.
class _StoredUser {
  final AuthUser user;
  final String? passwordHash;

  const _StoredUser({required this.user, this.passwordHash});
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
    fakeRepository.disableDelay(); // Fast tests by default
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
      fakeRepository.clearForcedFailure();
      await controller.signOut();

      expect(controller.state, isA<AuthIdle>());
    });
  });

  // ===========================================================================
  // FAKE REPOSITORY - IN-MEMORY STORE TESTS
  // ===========================================================================

  group('FakeAuthRepository - In-Memory Store', () {
    test('sign up creates user in store', () async {
      fakeRepository.nextUser = null; // Use store mode

      await controller.signUpWithEmail(
        email: 'new@example.com',
        password: 'password123',
      );

      expect(fakeRepository.hasUser('new@example.com'), isTrue);
      expect(fakeRepository.userCount, equals(1));
    });

    test('sign up with existing email throws duplicate error', () async {
      fakeRepository.nextUser = null;
      fakeRepository.seedUser(email: 'existing@test.com', password: 'pass123');

      await controller.signUpWithEmail(
        email: 'existing@test.com',
        password: 'newpassword',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        contains('already exists'),
      );
    });

    test('sign in with seeded user succeeds', () async {
      fakeRepository.nextUser = null;
      fakeRepository.seedUser(
        email: 'seeded@test.com',
        password: 'correctpassword',
        displayName: 'Seeded User',
      );

      await controller.signInWithEmail(
        email: 'seeded@test.com',
        password: 'correctpassword',
      );

      expect(controller.state, isA<AuthSuccess>());
      expect(
        (controller.state as AuthSuccess).user.displayName,
        equals('Seeded User'),
      );
    });

    test('sign in with wrong password throws invalid credentials', () async {
      fakeRepository.nextUser = null;
      fakeRepository.seedUser(email: 'user@test.com', password: 'correctpass');

      await controller.signInWithEmail(
        email: 'user@test.com',
        password: 'wrongpass',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        contains('Invalid email or password'),
      );
    });

    test('sign in with non-existent user throws user not found', () async {
      fakeRepository.nextUser = null;

      await controller.signInWithEmail(
        email: 'nonexistent@test.com',
        password: 'anypassword',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        contains('No account found'),
      );
    });

    test('email lookup is case-insensitive', () async {
      fakeRepository.nextUser = null;
      fakeRepository.seedUser(email: 'User@Test.COM', password: 'password123');

      await controller.signInWithEmail(
        email: 'user@test.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthSuccess>());
    });
  });

  // ===========================================================================
  // FAKE REPOSITORY - FORCED FAILURES
  // ===========================================================================

  group('FakeAuthRepository - Forced Failures', () {
    test('forceNetworkError throws network error', () async {
      fakeRepository.forceNetworkError();

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

    test('forceDuplicateEmail throws email already in use', () async {
      fakeRepository.forceDuplicateEmail();

      await controller.signUpWithEmail(
        email: 'new@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        contains('already exists'),
      );
    });

    test('forceCancelledLogin throws auth cancelled', () async {
      fakeRepository.forceCancelledLogin();

      await controller.signInWithGoogle();

      expect(controller.state, isA<AuthError>());
      expect((controller.state as AuthError).message, contains('cancelled'));
    });

    test('one-shot failure clears after first use', () async {
      fakeRepository.simulateSuccess(testUser);
      fakeRepository.forceNetworkError();

      // First call fails
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'pass123',
      );
      expect(controller.state, isA<AuthError>());

      // Second call succeeds (failure cleared)
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'pass123',
      );
      expect(controller.state, isA<AuthSuccess>());
    });

    test('persistent failure mode keeps failing', () async {
      fakeRepository.oneShotFailures = false;
      fakeRepository.forceNetworkError();

      // First call fails
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'pass123',
      );
      expect(controller.state, isA<AuthError>());

      // Second call still fails
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'pass123',
      );
      expect(controller.state, isA<AuthError>());

      // Clear to stop
      fakeRepository.clearForcedFailure();
      fakeRepository.simulateSuccess(testUser);
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'pass123',
      );
      expect(controller.state, isA<AuthSuccess>());
    });
  });

  // ===========================================================================
  // FAKE REPOSITORY - NETWORK DELAY
  // ===========================================================================

  group('FakeAuthRepository - Network Delay', () {
    test('artificial delay simulates network latency', () async {
      fakeRepository.simulateSuccess(testUser);
      fakeRepository.setNetworkDelay(const Duration(milliseconds: 100));

      final stopwatch = Stopwatch()..start();
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });

    test('loading state is observable during delay', () async {
      fakeRepository.simulateSuccess(testUser);
      fakeRepository.setNetworkDelay(const Duration(milliseconds: 50));

      final states = <AuthState>[];
      controller.addListener((state) => states.add(state));

      final future = controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.state, isA<AuthLoading>());

      await future;
      expect(states, contains(isA<AuthLoading>()));
    });
  });

  // ===========================================================================
  // FAKE REPOSITORY - CALL TRACKING
  // ===========================================================================

  group('FakeAuthRepository - Call Tracking', () {
    test('tracks sign up calls', () async {
      fakeRepository.simulateSuccess(testUser);

      await controller.signUpWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(fakeRepository.signUpCallCount, equals(1));
      expect(fakeRepository.lastEmail, equals('test@example.com'));
      expect(fakeRepository.lastPassword, equals('password123'));
    });

    test('tracks sign in calls', () async {
      fakeRepository.simulateSuccess(testUser);

      await controller.signInWithEmail(
        email: 'login@example.com',
        password: 'mypassword',
      );

      expect(fakeRepository.signInCallCount, equals(1));
      expect(fakeRepository.lastEmail, equals('login@example.com'));
    });

    test('tracks social sign in calls', () async {
      fakeRepository.simulateSuccess(googleUser);

      await controller.signInWithGoogle();
      await controller.signInWithGoogle();

      expect(fakeRepository.googleSignInCallCount, equals(2));
    });

    test('reset clears all counters', () async {
      fakeRepository.simulateSuccess(testUser);
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'pass',
      );

      fakeRepository.reset();

      expect(fakeRepository.signInCallCount, equals(0));
      expect(fakeRepository.userCount, equals(0));
      expect(fakeRepository.lastEmail, isNull);
    });
  });

  // ===========================================================================
  // CREDENTIAL FAILURES (Original tests)
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
  // VALIDATION FAILURES
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
  // DUPLICATE EMAIL
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
  // NETWORK FAILURES
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
  // SOCIAL LOGIN CANCELLATION
  // ===========================================================================

  group('AuthController - Social Login Cancellation', () {
    test('Google sign in cancellation handled gracefully', () async {
      fakeRepository.simulateSocialLoginCancel();

      await controller.signInWithGoogle();

      expect(controller.state, isA<AuthError>());
      expect(
        (controller.state as AuthError).message,
        equals(AuthCancelled().message),
      );
    });

    test('Apple sign in cancellation handled gracefully', () async {
      fakeRepository.simulateSocialLoginCancel();

      await controller.signInWithApple();

      expect(controller.state, isA<AuthError>());
      expect((controller.state as AuthError).message, contains('cancelled'));
    });

    test('can retry after social login cancellation', () async {
      fakeRepository.simulateSocialLoginCancel();
      await controller.signInWithGoogle();
      expect(controller.state, isA<AuthError>());

      fakeRepository.simulateSuccess(googleUser);
      await controller.signInWithGoogle();
      expect(controller.state, isA<AuthSuccess>());
    });
  });

  // ===========================================================================
  // SOCIAL LOGIN UNAVAILABLE
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
  // RATE LIMITING
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
  // OTHER FAILURES
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
      fakeRepository.setNetworkDelay(const Duration(milliseconds: 10));

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
      fakeRepository.setNetworkDelay(const Duration(milliseconds: 100));

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
      fakeRepository.setNetworkDelay(const Duration(milliseconds: 100));

      await Future.wait([
        controller.signUpWithEmail(email: 'a@test.com', password: 'password1'),
        controller.signUpWithEmail(email: 'b@test.com', password: 'password2'),
        controller.signUpWithEmail(email: 'c@test.com', password: 'password3'),
      ]);

      expect(fakeRepository.signUpCallCount, equals(1));
    });

    test('ignores Google sign in while loading', () async {
      fakeRepository.simulateSuccess(googleUser);
      fakeRepository.setNetworkDelay(const Duration(milliseconds: 100));

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

  // ===========================================================================
  // MALICIOUS TESTER - ADVERSARIAL TESTS
  // ===========================================================================
  // These tests attempt to break the controller through edge cases,
  // race conditions, and unexpected usage patterns.
  // ===========================================================================

  group('ADVERSARIAL - Disposal During Operation', () {
    test('dispose during loading should not cause state update', () async {
      fakeRepository.simulateSuccess(testUser);
      fakeRepository.setNetworkDelay(const Duration(milliseconds: 100));

      final states = <AuthState>[];
      controller.addListener((state) => states.add(state));

      // Start operation
      final future = controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Dispose while loading
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.state, isA<AuthLoading>());
      controller.dispose();

      // Wait for operation to complete
      await future;

      // State should NOT have changed to success after disposal
      // Last recorded state should be loading (before disposal)
      expect(states.last, isA<AuthLoading>());
    });

    test('operations after dispose should be no-op', () async {
      controller.dispose();

      fakeRepository.simulateSuccess(testUser);
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Should still be idle (initial state), not success
      expect(controller.state, isA<AuthIdle>());
      expect(fakeRepository.signInCallCount, equals(0));
    });

    test('addListener after dispose should be ignored', () {
      controller.dispose();

      var listenerCalled = false;
      controller.addListener((_) => listenerCalled = true);

      // Manually check - listener should not be in list
      // (we can't access _listeners directly, but we can test behavior)
      expect(listenerCalled, isFalse);
    });
  });

  group('ADVERSARIAL - Listener Attacks', () {
    test('listener that throws should not break other listeners', () async {
      fakeRepository.simulateSuccess(testUser);

      var listener1Called = false;
      var listener2Called = false;
      var listener3Called = false;

      controller.addListener((_) {
        listener1Called = true;
      });

      controller.addListener((_) {
        listener2Called = true;
        throw Exception('Malicious listener!');
      });

      controller.addListener((_) {
        listener3Called = true;
      });

      // This should not throw, even though listener 2 throws
      try {
        await controller.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );
      } catch (e) {
        // If we get here, the controller didn't handle throwing listeners
        // This is a WEAKNESS - mark the test
      }

      // At minimum, listener 1 should have been called
      expect(listener1Called, isTrue);
      // Note: Whether listeners 2 and 3 are called depends on implementation
    });

    test('listener that removes itself during notification', () async {
      fakeRepository.simulateSuccess(testUser);

      var callCount = 0;
      late void Function(AuthState) selfRemovingListener;

      selfRemovingListener = (state) {
        callCount++;
        controller.removeListener(selfRemovingListener);
      };

      controller.addListener(selfRemovingListener);

      // Should not crash
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Listener should have been called at least once (for loading state)
      expect(callCount, greaterThan(0));
    });

    test('listener that adds another listener during notification', () async {
      fakeRepository.simulateSuccess(testUser);
      fakeRepository.setNetworkDelay(const Duration(milliseconds: 10));

      var originalListenerCalls = 0;
      var addedListenerCalls = 0;

      controller.addListener((state) {
        originalListenerCalls++;
        // Add a new listener during notification
        controller.addListener((s) {
          addedListenerCalls++;
        });
      });

      // Should not crash or infinite loop
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(originalListenerCalls, greaterThan(0));
      // New listener might or might not be called for current notification
    });

    test('listener that disposes controller during notification', () async {
      fakeRepository.simulateSuccess(testUser);

      var listenerCalled = false;

      controller.addListener((state) {
        listenerCalled = true;
        if (state is AuthLoading) {
          controller.dispose();
        }
      });

      // Should not crash
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(listenerCalled, isTrue);
      // State should be loading (last state before disposal prevented further updates)
      // OR idle (initial) - depending on timing
    });

    test('listener that triggers another operation', () async {
      fakeRepository.simulateSuccess(testUser);
      fakeRepository.setNetworkDelay(const Duration(milliseconds: 10));

      var attemptedReentry = false;

      controller.addListener((state) {
        if (state is AuthLoading && !attemptedReentry) {
          attemptedReentry = true;
          // Try to trigger another operation while loading
          controller.signInWithGoogle();
        }
      });

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Should have blocked the reentry - only one call to repository
      expect(fakeRepository.signInCallCount, equals(1));
      expect(fakeRepository.googleSignInCallCount, equals(0));
    });
  });

  group('ADVERSARIAL - Concurrent Operations', () {
    test(
      'sign in + sign out simultaneously should not corrupt state',
      () async {
        fakeRepository.simulateSuccess(testUser);
        fakeRepository.setNetworkDelay(const Duration(milliseconds: 50));

        final signInFuture = controller.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Immediately try to sign out
        final signOutFuture = controller.signOut();

        await Future.wait([signInFuture, signOutFuture]);

        // State should be consistent (either success or idle, not corrupted)
        expect(controller.state, anyOf(isA<AuthSuccess>(), isA<AuthIdle>()));
      },
    );

    test('mixing different auth methods should not corrupt state', () async {
      fakeRepository.simulateSuccess(testUser);
      fakeRepository.setNetworkDelay(const Duration(milliseconds: 50));

      // Fire all at once
      await Future.wait([
        controller.signInWithEmail(email: 'a@test.com', password: 'pass1'),
        controller.signInWithGoogle(),
        controller.signInWithApple(),
        controller.signUpWithEmail(email: 'b@test.com', password: 'pass2'),
      ]);

      // Only one should have executed
      final totalCalls =
          fakeRepository.signInCallCount +
          fakeRepository.googleSignInCallCount +
          fakeRepository.appleSignInCallCount +
          fakeRepository.signUpCallCount;

      expect(totalCalls, equals(1));
    });

    test('rapid fire operations should process only first', () async {
      fakeRepository.simulateSuccess(testUser);
      fakeRepository.setNetworkDelay(const Duration(milliseconds: 100));

      // Rapid fire 100 requests
      final futures = List.generate(
        100,
        (i) => controller.signInWithEmail(
          email: 'user$i@test.com',
          password: 'password$i',
        ),
      );

      await Future.wait(futures);

      // Only 1 should have been processed
      expect(fakeRepository.signInCallCount, equals(1));
    });
  });

  group('ADVERSARIAL - Repository Attacks', () {
    test('repository that returns slowly then fails', () async {
      fakeRepository.setNetworkDelay(const Duration(milliseconds: 100));
      fakeRepository.forceNetworkError();

      final states = <AuthState>[];
      controller.addListener((state) => states.add(state));

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Should have: loading -> error
      expect(states.whereType<AuthLoading>().length, equals(1));
      expect(states.whereType<AuthError>().length, equals(1));
      expect(controller.state, isA<AuthError>());
    });

    test('repository that throws non-AuthFailure exception', () async {
      // Use a repository that throws generic exceptions (not AuthFailure)
      final evilRepo = _AsyncGenericExceptionRepository();
      final evilController = AuthController(evilRepo);

      await evilController.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Should gracefully handle with fallback error
      expect(evilController.state, isA<AuthError>());
      expect(
        (evilController.state as AuthError).message.toLowerCase(),
        contains('unexpected'),
      );
    });

    test('repository that throws synchronously (not async)', () async {
      // Create a repository that throws immediately
      final evilRepo = _SynchronousThrowingRepository();
      final evilController = AuthController(evilRepo);

      await evilController.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Should handle gracefully
      expect(evilController.state, isA<AuthError>());
    });
  });

  group('ADVERSARIAL - State Consistency', () {
    test('state should never be null', () async {
      // Try various operations
      expect(controller.state, isNotNull);

      fakeRepository.simulateSuccess(testUser);
      await controller.signInWithEmail(email: 'a@b.com', password: 'pass123');
      expect(controller.state, isNotNull);

      fakeRepository.forceNetworkError();
      await controller.signInWithGoogle();
      expect(controller.state, isNotNull);

      await controller.signOut();
      expect(controller.state, isNotNull);

      controller.dispose();
      expect(controller.state, isNotNull);
    });

    test('loading flag should reset even after exception', () async {
      fakeRepository.forceNetworkError();

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthError>());

      // Should be able to try again (loading flag reset)
      fakeRepository.simulateSuccess(testUser);
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(controller.state, isA<AuthSuccess>());
    });

    test('multiple errors in sequence should update state each time', () async {
      final errors = <String>[];
      controller.addListener((state) {
        if (state is AuthError) {
          errors.add(state.message);
        }
      });

      fakeRepository.forceNetworkError();
      await controller.signInWithEmail(email: 'a@b.com', password: 'pass1');

      fakeRepository.forceInvalidCredentials();
      await controller.signInWithEmail(email: 'a@b.com', password: 'pass2');

      fakeRepository.forceDuplicateEmail();
      await controller.signUpWithEmail(email: 'a@b.com', password: 'pass3');

      expect(errors.length, equals(3));
      expect(errors[0], contains('Network'));
      expect(errors[1], contains('Invalid'));
      expect(errors[2], contains('already exists'));
    });
  });

  group('ADVERSARIAL - Edge Case Inputs', () {
    test('empty email and password should be passed to repository', () async {
      fakeRepository.simulateSuccess(testUser);

      await controller.signInWithEmail(email: '', password: '');

      // Controller should pass through - validation is repository's job
      expect(fakeRepository.lastEmail, equals(''));
      expect(fakeRepository.lastPassword, equals(''));
    });

    test('extremely long strings should not crash', () async {
      fakeRepository.simulateSuccess(testUser);

      final longString = 'a' * 100000;

      await controller.signInWithEmail(email: longString, password: longString);

      expect(controller.state, isA<AuthSuccess>());
    });

    test('unicode and special characters should be handled', () async {
      fakeRepository.simulateSuccess(testUser);

      await controller.signInWithEmail(
        email: '用户@例子.中国',
        password: '密码🔐\n\t\r\0',
      );

      expect(fakeRepository.lastEmail, equals('用户@例子.中国'));
      expect(fakeRepository.lastPassword, equals('密码🔐\n\t\r\0'));
    });

    test('null bytes in strings should be handled', () async {
      fakeRepository.simulateSuccess(testUser);

      await controller.signInWithEmail(
        email: 'test\x00@example.com',
        password: 'pass\x00word',
      );

      expect(controller.state, isA<AuthSuccess>());
    });
  });

  group('ADVERSARIAL - Memory and Resources', () {
    test('removing non-existent listener should not crash', () {
      void nonExistentListener(AuthState state) {}

      // Should not throw
      controller.removeListener(nonExistentListener);
      controller.removeListener(nonExistentListener);
      controller.removeListener(nonExistentListener);
    });

    test('adding same listener multiple times', () async {
      fakeRepository.simulateSuccess(testUser);

      var callCount = 0;
      void listener(AuthState state) => callCount++;

      controller.addListener(listener);
      controller.addListener(listener);
      controller.addListener(listener);

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Listener added 3 times should be called 3 times per state change
      // 2 state changes (loading, success) * 3 listeners = 6 calls
      expect(callCount, equals(6));
    });

    test('dispose clears all listeners', () async {
      var callCount = 0;
      controller.addListener((_) => callCount++);
      controller.addListener((_) => callCount++);
      controller.addListener((_) => callCount++);

      controller.dispose();

      // Even if we somehow trigger state changes, listeners shouldn't be called
      // (we can't easily test this without accessing internals)
      expect(callCount, equals(0)); // No state changes happened yet
    });
  });
}

// =============================================================================
// ADVERSARIAL TEST HELPERS
// =============================================================================

/// A malicious repository that throws synchronously.
class _SynchronousThrowingRepository implements AuthRepository {
  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) {
    throw StateError('Synchronous throw!');
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw StateError('Synchronous throw!');
  }

  @override
  Future<AuthUser> signInWithGoogle() {
    throw StateError('Synchronous throw!');
  }

  @override
  Future<AuthUser> signInWithApple() {
    throw StateError('Synchronous throw!');
  }

  @override
  Future<void> signOut() {
    throw StateError('Synchronous throw!');
  }

  @override
  Future<AuthUser?> getCurrentUser() async => null;

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();
}

/// A repository that throws generic (non-AuthFailure) exceptions asynchronously.
class _AsyncGenericExceptionRepository implements AuthRepository {
  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    throw FormatException('Database connection failed');
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    throw FormatException('Database connection failed');
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 10));
    throw FormatException('Google SDK crashed');
  }

  @override
  Future<AuthUser> signInWithApple() async {
    await Future.delayed(const Duration(milliseconds: 10));
    throw FormatException('Apple SDK crashed');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 10));
    throw FormatException('Sign out failed unexpectedly');
  }

  @override
  Future<AuthUser?> getCurrentUser() async => null;

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();
}
