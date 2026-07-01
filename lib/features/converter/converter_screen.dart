import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../shared/utils/clipboard_helper.dart';
import 'converter_controller.dart';
import 'converter_service.dart';

const _background = Color(0xFFF8FAFC);
const _surface = Colors.white;
const _primary = Color(0xFF2563EB);
const _text = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _label = Color(0xFF334155);
const _border = Color(0xFFE2E8F0);
const _controlBorder = Color(0xFFCBD5E1);
const _errorBg = Color(0xFFFEF2F2);
const _errorBorder = Color(0xFFFECACA);
const _errorText = Color(0xFFB91C1C);

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final TextEditingController _inputController = TextEditingController();
  ConverterController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<ConverterController>();
    if (_controller == controller) return;

    _controller = controller;
    _inputController.text = controller.inputText;
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConverterController>();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return _ToolPage(
          title: 'Encoding/Decoding',
          subtitle: 'Encode, decode, and hash text locally.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final input = _InputCard(
                controller: controller,
                inputController: _inputController,
              );
              final output = _OutputCard(controller: controller);

              if (!isWide) {
                return Column(
                  children: [input, const SizedBox(height: 20), output],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 500, child: input),
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

class _InputCard extends StatelessWidget {
  const _InputCard({required this.controller, required this.inputController});

  final ConverterController controller;
  final TextEditingController inputController;

  @override
  Widget build(BuildContext context) {
    return _Card(
      minHeight: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Input'),
          const SizedBox(height: 6),
          const _BodyText('Paste text, encoded content, or values to hash.'),
          const SizedBox(height: 34),
          const _FieldLabel('Input Text'),
          const SizedBox(height: 10),
          _TextArea(
            controller: inputController,
            onChanged: controller.setInput,
          ),
          const SizedBox(height: 26),
          const _FieldLabel('Operation'),
          const SizedBox(height: 8),
          _OperationDropdown(
            value: controller.operation,
            onChanged: controller.setOperation,
          ),
          const SizedBox(height: 36),
          _PrimaryButton(
            label: 'Convert',
            width: 150,
            onPressed: controller.convert,
          ),
        ],
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({required this.controller});

  final ConverterController controller;

  @override
  Widget build(BuildContext context) {
    final hasError = controller.error != null;
    final output = hasError
        ? controller.error!
        : controller.outputText.isEmpty
        ? 'Output will appear here.'
        : controller.outputText;

    return _Card(
      minHeight: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Output'),
          const SizedBox(height: 6),
          const _BodyText(
            'Copy-friendly results. All Hashing/Encoding/Decoding is done locally.',
          ),
          const SizedBox(height: 34),
          _OutputArea(
            text: output,
            isPlaceholder: controller.outputText.isEmpty && !hasError,
            isError: hasError,
          ),
          const SizedBox(height: 36),
          _SecondaryButton(
            label: 'Copy Output',
            width: 150,
            onPressed: controller.outputText.isEmpty
                ? null
                : () => ClipboardHelper.copyWithFeedback(
                    context,
                    controller.outputText,
                  ),
          ),
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
  const _Card({required this.child, required this.minHeight});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
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

class _TextArea extends StatelessWidget {
  const _TextArea({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        expands: true,
        minLines: null,
        maxLines: null,
        textAlignVertical: TextAlignVertical.top,
        inputFormatters: [
          LengthLimitingTextInputFormatter(ConverterController.maxInputLength),
        ],
        cursorColor: _primary,
        style: const TextStyle(
          color: _text,
          fontSize: 14,
          height: 1.4,
          letterSpacing: 0,
        ),
        decoration: _inputDecoration(
          borderRadius: 12,
          contentPadding: const EdgeInsets.all(18),
          hintText: 'ex. hello internet',
        ),
      ),
    );
  }
}

class _OutputArea extends StatelessWidget {
  const _OutputArea({
    required this.text,
    required this.isPlaceholder,
    required this.isError,
  });

  final String text;
  final bool isPlaceholder;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isError ? _errorBg : _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isError ? _errorBorder : _controlBorder),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          text,
          style: TextStyle(
            color: isError
                ? _errorText
                : isPlaceholder
                ? _muted
                : _text,
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.45,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _OperationDropdown extends StatefulWidget {
  const _OperationDropdown({required this.value, required this.onChanged});

  final ConverterOperation value;
  final ValueChanged<ConverterOperation> onChanged;

  @override
  State<_OperationDropdown> createState() => _OperationDropdownState();
}

class _OperationDropdownState extends State<_OperationDropdown> {
  bool _isOpen = false;

  void _select(ConverterOperation operation) {
    widget.onChanged(operation);
    setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DropdownButtonFrame(
          width: 260,
          label: _operationLabel(widget.value),
          isOpen: _isOpen,
          onTap: () => setState(() => _isOpen = !_isOpen),
        ),
        if (_isOpen) ...[
          const SizedBox(height: 8),
          _InlineOptionPanel(
            width: 360,
            children: [
              for (final operation in ConverterOperation.values)
                _InlineOptionButton(
                  label: _operationLabel(operation),
                  selected: operation == widget.value,
                  onTap: () => _select(operation),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InlineOptionPanel extends StatelessWidget {
  const _InlineOptionPanel({required this.width, required this.children});

  final double width;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Wrap(spacing: 8, runSpacing: 8, children: children),
    );
  }
}

class _InlineOptionButton extends StatelessWidget {
  const _InlineOptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _controlBorder : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? _primary : _label,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, color: _primary, size: 15),
            ],
          ],
        ),
      ),
    );
  }
}

class _DropdownButtonFrame extends StatelessWidget {
  const _DropdownButtonFrame({
    required this.width,
    required this.label,
    required this.isOpen,
    required this.onTap,
  });

  final double width;
  final String label;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: width,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isOpen ? _primary : _controlBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _text,
                  fontSize: 14,
                  letterSpacing: 0,
                ),
              ),
            ),
            Icon(
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: _muted,
              size: 18,
            ),
          ],
        ),
      ),
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

String _operationLabel(ConverterOperation operation) {
  return switch (operation) {
    ConverterOperation.base64Encode => 'Text to Base64',
    ConverterOperation.base64Decode => 'Base64 to Text',
    ConverterOperation.hexEncode => 'Text to Hex',
    ConverterOperation.hexDecode => 'Hex to Text',
    ConverterOperation.md5 => 'MD5 Hash',
    ConverterOperation.sha1 => 'SHA-1 Hash',
    ConverterOperation.sha256 => 'SHA-256 Hash',
  };
}

InputDecoration _inputDecoration({
  String? hintText,
  double borderRadius = 10,
  EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 15,
  ),
}) {
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
    contentPadding: contentPadding,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(color: _controlBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(color: _primary),
    ),
  );
}
