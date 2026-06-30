import 'package:flutter/material.dart';

/// A scrollable, terminal-styled output view for streaming network results.
///
/// Automatically scrolls to the bottom as new [lines] are appended,
/// simulating a live console pane as required by PRD section 10.1.
class TerminalOutput extends StatefulWidget {
  const TerminalOutput({
    super.key,
    required this.lines,
    this.minHeight = 200.0,
  });

  /// Lines to display. Pass the full accumulated list on each rebuild.
  final List<String> lines;

  /// Minimum height of the terminal pane.
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
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: widget.lines.isEmpty
            ? Text(
                'Awaiting output…',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 13,
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: widget.lines.length,
                itemBuilder: (_, index) => Text(
                  widget.lines[index],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF00FF88),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
      ),
    );
  }
}
