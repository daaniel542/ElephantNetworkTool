import 'package:flutter/material.dart';

/// A styled primary action button with built-in loading and disabled states.
///
/// When [isLoading] is true the button shows a spinner and ignores taps.
/// When [onPressed] is null the button renders in a visually disabled state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  /// Optional override for the button background colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.primary;

    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(backgroundColor: effectiveColor),
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : (icon != null ? Icon(icon) : const SizedBox.shrink()),
      label: Text(label),
    );
  }
}
