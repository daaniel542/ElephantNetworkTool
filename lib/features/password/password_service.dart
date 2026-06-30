import 'dart:math';

/// Thrown when [PasswordService.generate] cannot satisfy the given constraints.
class PasswordServiceException implements Exception {
  const PasswordServiceException(this.message);
  final String message;
  @override
  String toString() => 'PasswordServiceException: $message';
}

/// Generates cryptographically secure random passwords using [Random.secure()].
///
/// Security imperative from PRD section 10.2: [Random.secure()] is the ONLY
/// permitted source of randomness. Standard [Random] is strictly prohibited.
class PasswordService {
  static const _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const _digits = '0123456789';
  static const _symbols = r'!@#$%^&*()-_=+[]{}|;:,.<>?';

  /// Generate a password satisfying all supplied constraints.
  ///
  /// Throws [PasswordServiceException] if the effective character pool is empty
  /// after applying [excludedChars].
  String generate({
    required int length,
    required bool useUppercase,
    required bool useLowercase,
    required bool useDigits,
    required bool useSymbols,
    required String excludedChars,
  }) {
    // Validate length bounds.
    if (length < 4 || length > 128) {
      throw const PasswordServiceException(
        'Password length must be between 4 and 128 characters.',
      );
    }

    // Build the active character pool.
    final buffer = StringBuffer();
    if (useUppercase) buffer.write(_uppercase);
    if (useLowercase) buffer.write(_lowercase);
    if (useDigits) buffer.write(_digits);
    if (useSymbols) buffer.write(_symbols);

    if (buffer.isEmpty) {
      throw const PasswordServiceException('No character types selected.');
    }

    // Apply exclusion rules.
    final excluded = excludedChars.split('').toSet();
    final pool =
        buffer.toString().split('').where((c) => !excluded.contains(c)).toList();

    if (pool.isEmpty) {
      throw const PasswordServiceException(
        'Excluded characters removed all available characters.',
      );
    }

    // Pull cryptographically secure random entries.
    final rng = Random.secure();
    return List.generate(length, (_) => pool[rng.nextInt(pool.length)]).join();
  }
}
