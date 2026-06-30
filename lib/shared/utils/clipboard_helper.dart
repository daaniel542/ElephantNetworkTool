import 'package:flutter/services.dart';

/// Write-only clipboard helper.
///
/// Clipboard access must be write-only and triggered exclusively by explicit
/// user interaction (e.g. pressing a "Copy" button), per PRD section 11.
///
/// Reading from the clipboard is intentionally omitted to comply with the iOS
/// clipboard-guarding requirement.
abstract final class ClipboardHelper {
  /// Copy [text] to the system clipboard.
  ///
  /// Returns true on success, false if the platform throws.
  static Future<bool> copy(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (_) {
      return false;
    }
  }
}
