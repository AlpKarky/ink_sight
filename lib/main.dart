// =============================================================================
// TEMPORARY PREVIEW - AUTH FLOW
// =============================================================================
// This is development-only composition code for previewing the auth UI.
// This file may be deleted or replaced later.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/providers/auth_view_model.dart';
import 'features/auth/ui/auth_gate.dart';

void main() {
    runApp(
     ProviderScope(
      child: MaterialApp(
        title: 'InkSight',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: AuthGate(), 
      ),
    ),
  );
}

// =============================================================================
// FAKE AUTH REPOSITORY - INLINE PREVIEW IMPLEMENTATION
// =============================================================================

/// Fake repository that simulates auth operations with artificial delays.
/// Always succeeds after a short delay.
class FakeAuthRepository implements AuthRepository {
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
