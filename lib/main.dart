// =============================================================================
// TEMPORARY PREVIEW - AUTH FLOW
// =============================================================================
// This is development-only composition code for previewing the auth UI.
// This file may be deleted or replaced later.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/ui/sign_in_page.dart';

void main() {
  runApp(const InkSightPreview());
}

/// Temporary preview app for auth flow development.
class InkSightPreview extends StatefulWidget {
  const InkSightPreview({super.key});

  @override
  State<InkSightPreview> createState() => _InkSightPreviewState();
}

class _InkSightPreviewState extends State<InkSightPreview> {
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthController(_FakeAuthRepository());
    _controller.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAuthStateChanged(AuthState state) {
    // Show snackbar on error
    if (state is AuthError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _handleSignInSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign in successful!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleSignUpTap() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign Up tapped (not implemented in preview)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InkSight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: SignInPage(
        controller: _controller,
        onSignInSuccess: _handleSignInSuccess,
        onSignUpTap: _handleSignUpTap,
      ),
    );
  }
}

// =============================================================================
// FAKE AUTH REPOSITORY - INLINE PREVIEW IMPLEMENTATION
// =============================================================================

/// Fake repository that simulates auth operations with artificial delays.
/// Always succeeds after a short delay.
class _FakeAuthRepository implements AuthRepository {
  static const _delay = Duration(milliseconds: 800);

  AuthUser? _currentUser;
  final _authStateController = StreamController<AuthUser?>.broadcast();

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(_delay);
    final user = AuthUser(
      id: 'fake-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      authMethod: AuthMethod.emailPassword,
    );
    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(_delay);
    final user = AuthUser(
      id: 'fake-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      authMethod: AuthMethod.emailPassword,
    );
    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await Future.delayed(_delay);
    final user = AuthUser(
      id: 'google-${DateTime.now().millisecondsSinceEpoch}',
      email: 'preview@google.com',
      displayName: 'Google User',
      authMethod: AuthMethod.google,
    );
    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithApple() async {
    await Future.delayed(_delay);
    final user = AuthUser(
      id: 'apple-${DateTime.now().millisecondsSinceEpoch}',
      email: 'preview@icloud.com',
      displayName: 'Apple User',
      authMethod: AuthMethod.apple,
    );
    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(_delay);
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<AuthUser?> getCurrentUser() async => _currentUser;

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;
}
