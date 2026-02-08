// =============================================================================
// AUTH GATE
// =============================================================================
// Root widget that controls navigation based on authentication state.
// Uses Navigator 2.0's declarative Pages API for state-driven navigation.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';
import '../domain/auth_repository.dart';
import '../providers/auth_view_model.dart';
import 'sign_in_page.dart';

/// Auth gate that controls navigation using Navigator 2.0's declarative Pages API.
///
/// Navigation is derived entirely from [authViewModelProvider] state:
/// - AsyncValue.loading → Loading screen
/// - AsyncValue.data(AuthIdle/AuthError) → LoginScreen (unauthenticated)
/// - AsyncValue.data(AuthLoading) → Loading screen (auth in progress)
/// - AsyncValue.data(AuthSuccess) → HomeScreen (authenticated)
/// - AsyncValue.error → Error screen
///
/// No imperative Navigator.push/pop calls are used. Screen selection happens
/// at the root level based on auth state changes.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(authViewModelProvider);

    // Handle AsyncValue.loading (provider initializing)
    if (asyncState.isLoading && !asyncState.hasValue) {
      return const _LoadingScreen();
    }

    // Handle AsyncValue.error (provider error)
    if (asyncState.hasError && !asyncState.hasValue) {
      return _ErrorScreen(message: asyncState.error.toString());
    }

    final authState = asyncState.value ?? const AuthIdle();

    // Handle AuthLoading (auth operation in progress)
    if (authState is AuthLoading) {
      return const _LoadingScreen();
    }

    // Use Navigator 2.0 declarative Pages API
    // Pages list is derived from auth state - no imperative navigation
    return Navigator(
      key: const ValueKey('auth-navigator'),
      pages: _buildPages(authState),
      onDidRemovePage: _handlePageRemoved,
    );
  }

  /// Build the pages list based on current auth state.
  /// This is the core of Navigator 2.0's declarative approach.
  List<Page<dynamic>> _buildPages(AuthState authState) {
    return [
      if (authState is AuthSuccess)
        MaterialPage<void>(
          key: const ValueKey('home'),
          name: '/home',
          child: HomeScreen(user: authState.user),
        )
      else
        const MaterialPage<void>(
          key: ValueKey('login'),
          name: '/login',
          child: SignInPage(),
        ),
    ];
  }

  /// Handle page removal.
  /// This is called when a page is popped from the navigator.
  /// In this auth flow, page changes are driven by auth state, not user actions.
  void _handlePageRemoved(Page<dynamic> page) {
    // Pages are managed by auth state, no additional handling needed
  }
}

// =============================================================================
// SCREENS
// =============================================================================

/// Loading screen shown during auth operations or provider initialization.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Error screen shown when provider encounters an error.
class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Error: $message'),
      ),
    );
  }
}

/// Placeholder home screen for authenticated users.
/// Will be replaced with actual home screen later.
class HomeScreen extends StatelessWidget {
  final AuthUser user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome!'),
            const SizedBox(height: 8),
            Text('Signed in as: ${user.email}'),
            if (user.displayName != null) ...[
              const SizedBox(height: 4),
              Text(user.displayName!),
            ],
          ],
        ),
      ),
    );
  }
}
