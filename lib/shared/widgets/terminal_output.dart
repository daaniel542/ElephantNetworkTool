import 'package:flutter/material.dart';

const _terminal = Color(0xFF020617);
const _terminalMuted = Color(0xFF94A3B8);
const _terminalText = Color(0xFFE2E8F0);

/// Scrollable, terminal-styled output for live network results.
///
/// The visual treatment mirrors the Figma component reference: near-black
/// panel, muted terminal title, and monospaced copy-friendly lines.
class TerminalOutput extends StatefulWidget {
  const TerminalOutput({
    super.key,
    required this.lines,
    this.minHeight = 200.0,
  });

  /// Lines to display. Pass the full accumulated list on each rebuild.
  final List<String> lines;

  /// Fixed visual height for the terminal panel.
  final double minHeight;

  @override
  State<TerminalOutput> createState() => _TerminalOutputState();
}

class _TerminalOutputState extends State<TerminalOutput> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(TerminalOutput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines.length != oldWidget.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.lines.isEmpty;

    return SizedBox(
      height: widget.minHeight,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: _terminal,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Output',
              style: TextStyle(
                color: _terminalMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isEmpty
                  ? const SelectableText(
                      'No results yet. Enter input and run the tool.',
                      style: TextStyle(
                        color: _terminalMuted,
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.45,
                        letterSpacing: 0,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: widget.lines.length,
                      itemBuilder: (context, index) {
                        return SelectableText(
                          widget.lines[index],
                          style: const TextStyle(
                            color: _terminalText,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.45,
                            letterSpacing: 0,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
