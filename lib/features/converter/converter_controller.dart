import 'package:flutter/foundation.dart';
import 'converter_service.dart';

/// Supported converter operations per PRD section 10.3.
enum ConverterOperation {
  base64Encode,
  base64Decode,
  hexEncode,
  hexDecode,
  md5,
  sha1,
  sha256,
}

/// Controller for the Encoding / Hashing Converter screen.
///
/// Holds the raw input text, the selected operation, and the result string.
/// All computation is delegated to [ConverterService].
class ConverterController extends ChangeNotifier {
  ConverterController({required ConverterService service}) : _service = service;

  final ConverterService _service;

  // -------------------------------------------------------------------------
  // Input state
  // -------------------------------------------------------------------------

  /// The text payload entered by the user. Capped at 50 000 chars in the UI.
  String inputText = '';

  /// Currently selected operation.
  ConverterOperation operation = ConverterOperation.base64Encode;

  // -------------------------------------------------------------------------
  // Output state
  // -------------------------------------------------------------------------

  /// Result of the last convert / hash operation.
  String outputText = '';

  /// Error message if the last operation failed.
  String? error;

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  /// Execute the selected operation against [inputText].
  void convert() {
    error = null;
    outputText = '';

    try {
      outputText = _service.execute(
        input: inputText,
        operation: operation,
      );
    } on ConverterServiceException catch (e) {
      error = e.message;
    }

    notifyListeners();
  }

  /// Update [inputText] (enforcing the 50 000-char cap) and notify listeners.
  void setInput(String value) {
    inputText = value.length > 50000 ? value.substring(0, 50000) : value;
    notifyListeners();
  }

  /// Update [operation] and notify listeners.
  void setOperation(ConverterOperation op) {
    operation = op;
    notifyListeners();
  }
}
