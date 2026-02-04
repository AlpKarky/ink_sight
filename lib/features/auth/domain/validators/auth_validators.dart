/// Validation utilities for authentication inputs.
///
/// These validators are pure functions that can be easily tested
/// and used independently of any framework.

/// Validates an email address format.
///
/// Returns `null` if valid, or an error message if invalid.
String? validateEmail(String email) {
  if (email.isEmpty) {
    return 'Email is required.';
  }

  // RFC 5322 compliant email regex (simplified version)
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  if (!emailRegex.hasMatch(email)) {
    return 'Please enter a valid email address.';
  }

  return null;
}

/// Validates a password against security requirements.
///
/// Requirements:
/// - Minimum 8 characters
/// - At least 1 number
///
/// Returns `null` if valid, or an error message if invalid.
String? validatePassword(String password) {
  if (password.isEmpty) {
    return 'Password is required.';
  }

  if (password.length < 8) {
    return 'Password must be at least 8 characters.';
  }

  if (!password.contains(RegExp(r'[0-9]'))) {
    return 'Password must contain at least 1 number.';
  }

  return null;
}

/// Validates that password confirmation matches.
///
/// Returns `null` if valid, or an error message if invalid.
String? validatePasswordConfirmation(String password, String confirmation) {
  if (confirmation.isEmpty) {
    return 'Please confirm your password.';
  }

  if (password != confirmation) {
    return 'Passwords do not match.';
  }

  return null;
}

/// Result of validating sign-up credentials.
class SignUpValidationResult {
  final String? emailError;
  final String? passwordError;

  const SignUpValidationResult({this.emailError, this.passwordError});

  bool get isValid => emailError == null && passwordError == null;

  @override
  String toString() =>
      'SignUpValidationResult(emailError: $emailError, passwordError: $passwordError)';
}

/// Validates all sign-up fields at once.
SignUpValidationResult validateSignUpCredentials({
  required String email,
  required String password,
}) {
  return SignUpValidationResult(
    emailError: validateEmail(email),
    passwordError: validatePassword(password),
  );
}
