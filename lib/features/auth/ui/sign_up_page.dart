import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../auth_controller.dart';

/// Sign Up screen with production-quality UX.
///
/// Connects to [AuthController] for authentication operations.
/// All auth logic is delegated to the controller - this widget
/// only handles UI state and local form validation.
class SignUpPage extends StatefulWidget {
  final AuthController controller;
  final VoidCallback? onSignInTap;
  final VoidCallback? onSignUpSuccess;

  const SignUpPage({
    super.key,
    required this.controller,
    this.onSignInTap,
    this.onSignUpSuccess,
  });

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasInteractedWithEmail = false;
  bool _hasInteractedWithPassword = false;
  bool _hasInteractedWithConfirmPassword = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onAuthStateChanged);
    _emailController.addListener(_validateEmailRealTime);
    _passwordController.addListener(_validatePasswordRealTime);
    _confirmPasswordController.addListener(_validateConfirmPasswordRealTime);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onAuthStateChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _onAuthStateChanged(AuthState state) {
    if (!mounted) return;

    switch (state) {
      case AuthSuccess():
        widget.onSignUpSuccess?.call();
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
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least 1 number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
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
    if (_hasInteractedWithPassword) {
      setState(() {
        _passwordError = _validatePassword(_passwordController.text);
      });
    }
    // Also revalidate confirm password if it's been touched
    if (_hasInteractedWithConfirmPassword) {
      setState(() {
        _confirmPasswordError = _validateConfirmPassword(
          _confirmPasswordController.text,
        );
      });
    } else {
      setState(() {}); // Trigger rebuild for password strength
    }
  }

  void _validateConfirmPasswordRealTime() {
    if (!_hasInteractedWithConfirmPassword) return;
    setState(() {
      _confirmPasswordError = _validateConfirmPassword(
        _confirmPasswordController.text,
      );
    });
  }

  bool get _isFormValid {
    return _validateEmail(_emailController.text) == null &&
        _validatePassword(_passwordController.text) == null &&
        _validateConfirmPassword(_confirmPasswordController.text) == null;
  }

  bool get _isLoading => widget.controller.state is AuthLoading;

  // ===========================================================================
  // PASSWORD STRENGTH
  // ===========================================================================

  _PasswordStrength get _passwordStrength {
    final password = _passwordController.text;
    if (password.isEmpty) return _PasswordStrength.none;

    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) return _PasswordStrength.weak;
    if (score <= 4) return _PasswordStrength.medium;
    return _PasswordStrength.strong;
  }

  // ===========================================================================
  // ACTIONS (delegate to controller)
  // ===========================================================================

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleSignUp() async {
    _dismissKeyboard();

    setState(() {
      _hasInteractedWithEmail = true;
      _hasInteractedWithPassword = true;
      _hasInteractedWithConfirmPassword = true;
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _confirmPasswordError = _validateConfirmPassword(
        _confirmPasswordController.text,
      );
    });

    if (!_isFormValid) return;

    await widget.controller.signUpWithEmail(
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
                        const SizedBox(height: 32),

                        // =====================================================
                        // LOGO / TITLE
                        // =====================================================
                        _buildHeader(theme),

                        const SizedBox(height: 40),

                        // =====================================================
                        // EMAIL FIELD
                        // =====================================================
                        _buildEmailField(colorScheme),

                        const SizedBox(height: 16),

                        // =====================================================
                        // PASSWORD FIELD
                        // =====================================================
                        _buildPasswordField(colorScheme),

                        // =====================================================
                        // PASSWORD STRENGTH & RULES
                        // =====================================================
                        _buildPasswordStrengthIndicator(theme),

                        const SizedBox(height: 16),

                        // =====================================================
                        // CONFIRM PASSWORD FIELD
                        // =====================================================
                        _buildConfirmPasswordField(colorScheme),

                        const SizedBox(height: 24),

                        // =====================================================
                        // SIGN UP BUTTON
                        // =====================================================
                        _buildSignUpButton(colorScheme),

                        const SizedBox(height: 16),

                        // =====================================================
                        // TERMS & PRIVACY
                        // =====================================================
                        _buildTermsText(theme),

                        const SizedBox(height: 24),

                        // =====================================================
                        // DIVIDER
                        // =====================================================
                        _buildDivider(theme),

                        const SizedBox(height: 24),

                        // =====================================================
                        // SOCIAL BUTTONS
                        // =====================================================
                        _buildGoogleButton(colorScheme),

                        if (_isAppleSignInAvailable) ...[
                          const SizedBox(height: 12),
                          _buildAppleButton(colorScheme),
                        ],

                        const Spacer(),

                        // =====================================================
                        // SIGN IN LINK
                        // =====================================================
                        _buildSignInLink(theme),

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
          'Create Account',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign up to get started',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField(ColorScheme colorScheme) {
    return TextFormField(
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
    );
  }

  Widget _buildPasswordField(ColorScheme colorScheme) {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      enabled: !_isLoading,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
      onFieldSubmitted: (_) {
        _confirmPasswordFocusNode.requestFocus();
      },
      onTapOutside: (_) {
        if (_passwordFocusNode.hasFocus) {
          setState(() => _hasInteractedWithPassword = true);
          _validatePasswordRealTime();
        }
      },
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Create a password',
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

  Widget _buildPasswordStrengthIndicator(ThemeData theme) {
    final password = _passwordController.text;
    if (password.isEmpty) {
      return _buildPasswordRulesHint(theme);
    }

    final strength = _passwordStrength;
    final (color, label) = switch (strength) {
      _PasswordStrength.none => (Colors.grey, ''),
      _PasswordStrength.weak => (Colors.red, 'Weak'),
      _PasswordStrength.medium => (Colors.orange, 'Medium'),
      _PasswordStrength.strong => (Colors.green, 'Strong'),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strength bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: switch (strength) {
                      _PasswordStrength.none => 0,
                      _PasswordStrength.weak => 0.33,
                      _PasswordStrength.medium => 0.66,
                      _PasswordStrength.strong => 1.0,
                    },
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: color,
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Requirements checklist
          _buildRequirementRow(
            theme,
            'At least 8 characters',
            password.length >= 8,
          ),
          _buildRequirementRow(
            theme,
            'Contains a number',
            password.contains(RegExp(r'[0-9]')),
          ),
          _buildRequirementRow(
            theme,
            'Contains uppercase letter',
            password.contains(RegExp(r'[A-Z]')),
          ),
          _buildRequirementRow(
            theme,
            'Contains special character',
            password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRulesHint(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Password must be at least 8 characters with at least 1 number',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildRequirementRow(ThemeData theme, String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isMet ? Colors.green : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField(ColorScheme colorScheme) {
    return TextFormField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocusNode,
      enabled: !_isLoading,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.newPassword],
      onFieldSubmitted: (_) => _handleSignUp(),
      onTapOutside: (_) {
        if (_confirmPasswordFocusNode.hasFocus) {
          setState(() => _hasInteractedWithConfirmPassword = true);
          _validateConfirmPasswordRealTime();
        }
      },
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Re-enter your password',
        prefixIcon: const Icon(Icons.lock_outlined),
        errorText: _confirmPasswordError,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
          tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
        ),
      ),
    );
  }

  Widget _buildSignUpButton(ColorScheme colorScheme) {
    final isEnabled = !_isLoading && _isFormValid;

    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: isEnabled ? _handleSignUp : null,
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
                'Create Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildTermsText(ThemeData theme) {
    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        children: const [
          TextSpan(text: 'By signing up, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: TextStyle(
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
            // TODO: Add onTap with TapGestureRecognizer when implementing
          ),
          TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
            // TODO: Add onTap with TapGestureRecognizer when implementing
          ),
          TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
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

  Widget _buildSignInLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : widget.onSignInTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            'Sign In',
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
      return false;
    }
  }
}

// ===========================================================================
// PRIVATE TYPES
// ===========================================================================

enum _PasswordStrength { none, weak, medium, strong }
