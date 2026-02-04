import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'auth_controller.dart';

/// Sign In screen with production-quality UX.
///
/// Connects to [AuthController] for authentication operations.
/// All auth logic is delegated to the controller - this widget
/// only handles UI state and local form validation.
class SignInPage extends StatefulWidget {
  final AuthController controller;
  final VoidCallback? onSignUpTap;
  final VoidCallback? onSignInSuccess;

  const SignInPage({
    super.key,
    required this.controller,
    this.onSignUpTap,
    this.onSignInSuccess,
  });

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _hasInteractedWithEmail = false;
  bool _hasInteractedWithPassword = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onAuthStateChanged);
    _emailController.addListener(_validateEmailRealTime);
    _passwordController.addListener(_validatePasswordRealTime);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onAuthStateChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onAuthStateChanged(AuthState state) {
    if (!mounted) return;

    switch (state) {
      case AuthSuccess():
        widget.onSignInSuccess?.call();
      case AuthError(:final message):
        _showErrorSnackbar(message);
      case AuthIdle():
      case AuthLoading():
        break;
    }
    setState(() {});
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // LOCAL VALIDATION (UI only - no auth logic)
  // ===========================================================================

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  void _validateEmailRealTime() {
    if (!_hasInteractedWithEmail) return;
    setState(() {
      _emailError = _validateEmail(_emailController.text);
    });
  }

  void _validatePasswordRealTime() {
    if (!_hasInteractedWithPassword) return;
    setState(() {
      _passwordError = _validatePassword(_passwordController.text);
    });
  }

  bool get _isFormValid {
    return _validateEmail(_emailController.text) == null &&
        _validatePassword(_passwordController.text) == null;
  }

  bool get _isLoading => widget.controller.state is AuthLoading;

  // ===========================================================================
  // ACTIONS (delegate to controller)
  // ===========================================================================

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleSignIn() async {
    _dismissKeyboard();

    setState(() {
      _hasInteractedWithEmail = true;
      _hasInteractedWithPassword = true;
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
    });

    if (!_isFormValid) return;

    await widget.controller.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _handleGoogleSignIn() async {
    _dismissKeyboard();
    await widget.controller.signInWithGoogle();
  }

  Future<void> _handleAppleSignIn() async {
    _dismissKeyboard();
    await widget.controller.signInWithApple();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),

                        // =====================================================
                        // LOGO / TITLE
                        // =====================================================
                        _buildHeader(theme),

                        const SizedBox(height: 48),

                        // =====================================================
                        // EMAIL FIELD
                        // =====================================================
                        _buildEmailField(colorScheme),

                        const SizedBox(height: 16),

                        // =====================================================
                        // PASSWORD FIELD
                        // =====================================================
                        _buildPasswordField(colorScheme),

                        const SizedBox(height: 24),

                        // =====================================================
                        // SIGN IN BUTTON
                        // =====================================================
                        _buildSignInButton(colorScheme),

                        const SizedBox(height: 32),

                        // =====================================================
                        // DIVIDER
                        // =====================================================
                        _buildDivider(theme),

                        const SizedBox(height: 32),

                        // =====================================================
                        // SOCIAL BUTTONS
                        // =====================================================
                        _buildGoogleButton(colorScheme),

                        if (_isAppleSignInAvailable) ...[
                          const SizedBox(height: 12),
                          _buildAppleButton(colorScheme),
                        ],

                        const Spacer(flex: 3),

                        // =====================================================
                        // SIGN UP LINK
                        // =====================================================
                        _buildSignUpLink(theme),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // App Icon/Logo placeholder
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.draw_outlined,
            size: 40,
            color: theme.colorScheme.onPrimaryContainer,
            semanticLabel: 'InkSight logo',
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          onFieldSubmitted: (_) {
            _passwordFocusNode.requestFocus();
          },
          onTapOutside: (_) {
            if (_emailFocusNode.hasFocus) {
              setState(() => _hasInteractedWithEmail = true);
              _validateEmailRealTime();
            }
          },
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email',
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: _emailError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(ColorScheme colorScheme) {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      enabled: !_isLoading,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) => _handleSignIn(),
      onTapOutside: (_) {
        if (_passwordFocusNode.hasFocus) {
          setState(() => _hasInteractedWithPassword = true);
          _validatePasswordRealTime();
        }
      },
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock_outlined),
        errorText: _passwordError,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
        ),
      ),
    );
  }

  Widget _buildSignInButton(ColorScheme colorScheme) {
    final isEnabled = !_isLoading && _isFormValid;

    return SizedBox(
      height: 56, // 48px minimum + padding
      child: FilledButton(
        onPressed: isEnabled ? _handleSignIn : null,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.onPrimary,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
      ],
    );
  }

  Widget _buildGoogleButton(ColorScheme colorScheme) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colorScheme.outline),
        ),
        icon: _buildGoogleIcon(),
        label: const Text(
          'Continue with Google',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    // Simple Google "G" icon using colors
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAppleButton(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleAppleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide.none,
        ),
        icon: Icon(
          Icons.apple,
          size: 24,
          color: isDark ? Colors.black : Colors.white,
          semanticLabel: 'Apple logo',
        ),
        label: Text(
          'Continue with Apple',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : widget.onSignUpTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            'Sign Up',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  bool get _isAppleSignInAvailable {
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      // Platform not available (web)
      return false;
    }
  }
}
