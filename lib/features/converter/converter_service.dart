import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'converter_controller.dart';

/// Thrown when [ConverterService.execute] encounters invalid input.
class ConverterServiceException implements Exception {
  const ConverterServiceException(this.message);
  final String message;
  @override
  String toString() => 'ConverterServiceException: $message';
}

/// Handles Base64 (encode/decode), Hex (encode/decode), MD5, SHA-1, SHA-256.
///
/// All operations are wrapped in try/catch blocks so malformed input produces
/// user-friendly [ConverterServiceException]s rather than runtime crashes,
/// per PRD section 10.3.
class ConverterService {
  /// Execute [operation] against [input] and return the result string.
  ///
  /// Throws [ConverterServiceException] on invalid input.
  String execute({
    required String input,
    required ConverterOperation operation,
  }) {
    try {
      switch (operation) {
        case ConverterOperation.base64Encode:
          return base64.encode(utf8.encode(input));

        case ConverterOperation.base64Decode:
          try {
            final bytes = base64.decode(input.trim());
            return utf8.decode(bytes);
          } catch (_) {
            throw const ConverterServiceException('Invalid Base64 input.');
          }

        case ConverterOperation.hexEncode:
          return hex.encode(utf8.encode(input));

        case ConverterOperation.hexDecode:
          try {
            final bytes = hex.decode(input.trim().replaceAll(' ', ''));
            return utf8.decode(bytes);
          } catch (_) {
            throw const ConverterServiceException('Invalid hex input.');
          }

        case ConverterOperation.md5:
          final digest = md5.convert(utf8.encode(input));
          return digest.toString();

        case ConverterOperation.sha1:
          final digest = sha1.convert(utf8.encode(input));
          return digest.toString();

        case ConverterOperation.sha256:
          final digest = sha256.convert(utf8.encode(input));
          return digest.toString();
      }
    } on ConverterServiceException {
      rethrow;
    } catch (e) {
      throw ConverterServiceException('Unexpected error: $e');
    }
  }
}
