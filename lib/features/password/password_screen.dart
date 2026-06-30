import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../shared/utils/clipboard_helper.dart';
import 'password_controller.dart';

const _background = Color(0xFFF8FAFC);
const _surface = Colors.white;
const _primary = Color(0xFF2563EB);
const _text = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _label = Color(0xFF334155);
const _border = Color(0xFFE2E8F0);
const _controlBorder = Color(0xFFCBD5E1);
const _successBg = Color(0xFFDCFCE7);
const _successText = Color(0xFF166534);

class PasswordScreen extends StatelessWidget {
  const PasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PasswordController>(
      builder: (context, controller, _) {
        return _ToolPage(
          title: 'Password Generator',
          subtitle: 'Create secure passwords using local device randomness.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 920;
              final settings = _PasswordSettingsCard(controller: controller);
              final output = _GeneratedPasswordCard(controller: controller);

              if (!isWide) {
                return Column(
                  children: [settings, const SizedBox(height: 20), output],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 500, child: settings),
                  const SizedBox(width: 32),
                  Expanded(child: output),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _PasswordSettingsCard extends StatelessWidget {
  const _PasswordSettingsCard({required this.controller});

  final PasswordController controller;

  @override
  Widget build(BuildContext context) {
    return _Card(
      minHeight: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Password Settings'),
          const SizedBox(height: 6),
          const _BodyText('Choose length, character types, and exclusions.'),
          const SizedBox(height: 34),
          const _FieldLabel('Password Length'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _primary,
                    inactiveTrackColor: _border,
                    thumbColor: _surface,
                    overlayColor: _primary.withValues(alpha: 0.12),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 11,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 18,
                    ),
                  ),
                  child: Slider(
                    value: controller.length.toDouble(),
                    min: 4,
                    max: 128,
                    divisions: 124,
                    label: controller.length.toString(),
                    onChanged: (value) => controller.setLength(value.round()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _LengthInput(
                value: controller.length,
                onChanged: controller.setLength,
              ),
            ],
          ),
          const SizedBox(height: 30),
          const _FieldLabel('Character Types'),
          const SizedBox(height: 14),
          _CheckRow(
            label: 'Uppercase Letters',
            value: controller.useUppercase,
            onChanged: controller.toggleUppercase,
          ),
          _CheckRow(
            label: 'Lowercase Letters',
            value: controller.useLowercase,
            onChanged: controller.toggleLowercase,
          ),
          _CheckRow(
            label: 'Numbers',
            value: controller.useDigits,
            onChanged: controller.toggleDigits,
          ),
          _CheckRow(
            label: 'Special Symbols',
            value: controller.useSymbols,
            onChanged: controller.toggleSymbols,
          ),
          const SizedBox(height: 24),
          const _FieldLabel('Excluded Characters'),
          const SizedBox(height: 8),
          _TextInput(
            initialValue: controller.excludedChars,
            hintText: 'ex. lIO0',
            onChanged: controller.setExcludedChars,
          ),
          const SizedBox(height: 14),
          const _Caption(
            'Avoid confusing characters like lowercase l, uppercase I, O, and zero.',
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Generate Password',
            onPressed: controller.generate,
            width: 200,
          ),
        ],
      ),
    );
  }
}

class _GeneratedPasswordCard extends StatelessWidget {
  const _GeneratedPasswordCard({required this.controller});

  final PasswordController controller;

  @override
  Widget build(BuildContext context) {
    final hasPassword = controller.generatedPassword.isNotEmpty;

    return _Card(
      minHeight: 227,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _CardTitle('Generated Password')),
              _StatusBadge(
                label: hasPassword ? 'Strong' : 'Ready',
                background: hasPassword ? _successBg : const Color(0xFFDBEAFE),
                foreground: hasPassword
                    ? _successText
                    : const Color(0xFF1D4ED8),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _OutputField(
                  text: hasPassword
                      ? controller.generatedPassword
                      : 'No password generated yet.',
                  isPlaceholder: !hasPassword,
                ),
              ),
              const SizedBox(width: 12),
              _SecondaryButton(
                label: 'Copy',
                width: 84,
                onPressed: hasPassword
                    ? () => ClipboardHelper.copyWithFeedback(
                        context,
                        controller.generatedPassword,
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _Caption('Passwords are generated locally and are not stored.'),
        ],
      ),
    );
  }
}

class _ToolPage extends StatelessWidget {
  const _ToolPage({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: const BoxDecoration(
              color: _surface,
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1056),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.minHeight});

  final Widget child;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 14,
        height: 1.35,
        letterSpacing: 0,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _label,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 12,
        height: 1.35,
        letterSpacing: 0,
      ),
    );
  }
}

class _LengthInput extends StatefulWidget {
  const _LengthInput({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_LengthInput> createState() => _LengthInputState();
}

class _LengthInputState extends State<_LengthInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _LengthInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _setText(widget.value.toString());
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commit();
    }
  }

  void _handleChanged(String rawValue) {
    final value = int.tryParse(rawValue);
    if (value == null) {
      return;
    }

    widget.onChanged(value.clamp(4, 128));
  }

  void _commit() {
    final value = int.tryParse(_controller.text);
    final normalized = (value ?? widget.value).clamp(4, 128);

    widget.onChanged(normalized);
    _setText(normalized.toString());
  }

  void _setText(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 42,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        cursorColor: _primary,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        onChanged: _handleChanged,
        onEditingComplete: _commit,
        style: const TextStyle(
          color: _text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        decoration: _inputDecoration().copyWith(
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: value,
                onChanged: (next) => onChanged(next ?? false),
                activeColor: _primary,
                side: const BorderSide(color: _controlBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: _label,
                fontSize: 14,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.initialValue,
    required this.hintText,
    required this.onChanged,
  });

  final String initialValue;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      cursorColor: _primary,
      style: const TextStyle(color: _text, fontSize: 14, letterSpacing: 0),
      decoration: _inputDecoration(hintText: hintText),
    );
  }
}

class _OutputField extends StatelessWidget {
  const _OutputField({required this.text, required this.isPlaceholder});

  final String text;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _controlBorder),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          color: isPlaceholder ? _muted : _text,
          fontSize: 17,
          height: 1.35,
          fontFamily: 'monospace',
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primary,
          foregroundColor: _surface,
          disabledBackgroundColor: _primary.withValues(alpha: 0.42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    required this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _label,
          disabledForegroundColor: _muted.withValues(alpha: 0.45),
          side: BorderSide(
            color: onPressed == null
                ? _controlBorder.withValues(alpha: 0.55)
                : _controlBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: _muted.withValues(alpha: 0.62),
      fontSize: 14,
      letterSpacing: 0,
    ),
    filled: true,
    fillColor: _surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _controlBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _primary),
    ),
  );
}
