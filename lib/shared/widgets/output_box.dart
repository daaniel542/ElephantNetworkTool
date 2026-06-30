import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A selectable, copyable text box for displaying operation results.
///
/// Used in the password generator and converter output panels. Content is
/// rendered in a monospaced font as required by PRD section 11.
class OutputBox extends StatelessWidget {
  const OutputBox({
    super.key,
    required this.text,
    this.placeholder = 'Output will appear here…',
    this.onCopy,
  });

  final String text;
  final String placeholder;

  /// Optional callback invoked after the text is copied. If null, the default
  /// [Clipboard.setData] behaviour is used and a SnackBar is shown.
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final isEmpty = text.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              isEmpty ? placeholder : text,
              style: TextStyle(
                fontFamily: 'monospace',
                color: isEmpty
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (!isEmpty)
            IconButton(
              tooltip: 'Copy to clipboard',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => _copy(context),
            ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    if (onCopy != null) {
      onCopy!();
    } else {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
