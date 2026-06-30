import 'package:flutter/foundation.dart';
import 'password_service.dart';

/// Controller for the Password Generator screen.
///
/// Holds all configurable inputs (length, character set toggles, exclusion
/// list) and exposes the generated password string. Generation is delegated
/// to [PasswordService] which uses [Random.secure()] internally.
class PasswordController extends ChangeNotifier {
  PasswordController({required PasswordService service}) : _service = service;

  final PasswordService _service;

  // -------------------------------------------------------------------------
  // Configuration state
  // -------------------------------------------------------------------------

  /// Desired password length. Clamped to [4, 128]. Default: 16.
  int length = 16;

  /// Include uppercase A-Z.
  bool useUppercase = true;

  /// Include lowercase a-z.
  bool useLowercase = true;

  /// Include digits 0-9.
  bool useDigits = true;

  /// Include special/symbol characters.
  bool useSymbols = false;

  /// Characters explicitly excluded from the pool (e.g. "lIO0" by default).
  String excludedChars = 'lIO0';

  // -------------------------------------------------------------------------
  // Output state
  // -------------------------------------------------------------------------

  /// The last generated password, or empty string before first generation.
  String generatedPassword = '';

  /// Validation or generation error message.
  String? error;

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  /// Generate a new password using the current configuration.
  void generate() {
    error = null;

    try {
      generatedPassword = _service.generate(
        length: length,
        useUppercase: useUppercase,
        useLowercase: useLowercase,
        useDigits: useDigits,
        useSymbols: useSymbols,
        excludedChars: excludedChars,
      );
    } on PasswordServiceException catch (e) {
      generatedPassword = '';
      error = e.message;
    }

    notifyListeners();
  }

  /// Update [length] and notify listeners.
  void setLength(int value) {
    length = value.clamp(4, 128);
    notifyListeners();
  }

  /// Update [excludedChars] and notify listeners.
  void setExcludedChars(String value) {
    excludedChars = value;
    notifyListeners();
  }
}
