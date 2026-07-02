import 'package:flutter/material.dart';

import 'traceroute_models.dart';

// ── Color tokens ──────────────────────────────────────────────────────
const _tableBg = Color(0xFF020617);
const _headerBg = Color(0xFF0F172A);
const _rowEven = Color(0xFF020617);
const _rowOdd = Color(0xFF0B1120);
const _headerText = Color(0xFF94A3B8);
const _cellText = Color(0xFFE2E8F0);
const _mutedText = Color(0xFF64748B);
const _successGreen = Color(0xFF22C55E);
const _reachedBlue = Color(0xFF3B82F6);
const _timeoutAmber = Color(0xFFF59E0B);
const _pendingGray = Color(0xFF64748B);
const _summaryBorder = Color(0xFF1E293B);
const _probeTimeout = Color(0xFF475569);

/// Renders traceroute hops as a clean static table with optional summary.
class TracerouteTable extends StatelessWidget {
  const TracerouteTable({
    super.key,
    required this.hops,
    required this.targetHost,
    this.summary,
    this.isTracing = false,
    this.error,
    this.minHeight = 342.0,
  });

  final List<TracerouteHop> hops;
  final String targetHost;
  final TracerouteSummary? summary;
  final bool isTracing;
  final String? error;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final isEmpty = hops.isEmpty && !isTracing && error == null;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _tableBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                const Text(
                  'Live Output',
                  style: TextStyle(
                    color: _headerText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                if (isTracing) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: _reachedBlue.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Text(
                'No results yet. Enter input and run the tool.',
                style: TextStyle(
                  color: _mutedText.withValues(alpha: 0.7),
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
            )
          else ...[
            // Trace header
            if (targetHost.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Trace to $targetHost  ·  max hops 30',
                  style: const TextStyle(
                    color: _cellText,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
            // Table
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildTable(),
              ),
            ),
            // Error
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  'Error: $error',
                  style: const TextStyle(
                    color: _timeoutAmber,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
              ),
            // Tracing indicator
            if (isTracing && hops.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: _mutedText.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Probing hop ${hops.length + 1}…',
                      style: TextStyle(
                        color: _mutedText.withValues(alpha: 0.7),
                        fontFamily: 'monospace',
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            // Summary
            if (summary != null && !isTracing)
              _buildSummary(summary!),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(44),   // Hop
        1: FlexColumnWidth(2.0),   // IP Address
        2: FixedColumnWidth(88),   // Status
        3: FlexColumnWidth(1),     // P1
        4: FlexColumnWidth(1),     // P2
        5: FlexColumnWidth(1),     // P3
        6: FlexColumnWidth(1),     // Avg
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _buildHeaderRow(),
        for (var i = 0; i < hops.length; i++) _buildHopRow(hops[i], i),
      ],
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: _headerBg),
      children: [
        _headerCell('HOP', align: TextAlign.center),
        _headerCell('IP ADDRESS'),
        _headerCell('STATUS', align: TextAlign.center),
        _headerCell('P1', align: TextAlign.right),
        _headerCell('P2', align: TextAlign.right),
        _headerCell('P3', align: TextAlign.right),
        _headerCell('AVG', align: TextAlign.right),
      ],
    );
  }

  Widget _headerCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          color: _headerText,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  TableRow _buildHopRow(TracerouteHop hop, int index) {
    final bg = index.isEven ? _rowEven : _rowOdd;

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        // Hop number
        _dataCell(
          hop.hopNumber.toString().padLeft(2, '0'),
          align: TextAlign.center,
          fontWeight: FontWeight.w600,
        ),
        // IP Address
        _dataCell(
          _displayAddress(hop),
          color: hop.status == TracerouteHopStatus.timeout
              ? _probeTimeout
              : _cellText,
        ),
        // Status badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: _StatusBadge(hop: hop),
          ),
        ),
        // P1
        _probeCell(hop.probe1),
        // P2
        _probeCell(hop.probe2),
        // P3
        _probeCell(hop.probe3),
        // Avg
        _dataCell(
          _formatDuration(hop.averageRtt, fallback: '-'),
          align: TextAlign.right,
          fontWeight: FontWeight.w600,
          color: _cellText,
        ),
      ],
    );
  }

  Widget _probeCell(Duration? probe) {
    if (probe == null) {
      return _dataCell('*', align: TextAlign.right, color: _probeTimeout);
    }
    return _dataCell(
      _formatDuration(probe),
      align: TextAlign.right,
      color: _cellText,
    );
  }

  Widget _dataCell(
    String text, {
    TextAlign align = TextAlign.left,
    FontWeight fontWeight = FontWeight.w400,
    Color color = _cellText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: fontWeight,
          fontFamily: 'monospace',
          height: 1.3,
          letterSpacing: 0,
        ),
      ),
    );
  }

  String _displayAddress(TracerouteHop hop) {
    if (hop.status == TracerouteHopStatus.timeout) return 'Request Timeout';
    if (hop.displayAddress.isEmpty) return 'Unknown';
    return hop.displayAddress;
  }

  String _formatDuration(Duration? duration, {String fallback = '*'}) {
    if (duration == null) return fallback;
    final micros = duration.inMicroseconds;
    if (micros % Duration.microsecondsPerMillisecond == 0) {
      return '${micros ~/ Duration.microsecondsPerMillisecond}ms';
    }
    return '${(micros / Duration.microsecondsPerMillisecond).toStringAsFixed(1)}ms';
  }

  Widget _buildSummary(TracerouteSummary summary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _headerBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _summaryBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TRACE SUMMARY',
              style: TextStyle(
                color: _headerText,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _summaryItem(
                  'Destination',
                  summary.destinationReached ?? 'Not reached',
                ),
                const SizedBox(width: 32),
                _summaryItem('Hops', summary.totalHops.toString()),
                const SizedBox(width: 32),
                _summaryItem(
                  'End-to-End',
                  _formatDuration(
                    summary.totalEndToEndLatency,
                    fallback: '-',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _mutedText.withValues(alpha: 0.8),
            fontSize: 11,
            fontFamily: 'monospace',
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: _cellText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

/// Small pill showing hop status with a dot + label.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.hop});

  final TracerouteHop hop;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _resolve();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _resolve() {
    if (hop.isDestination) return (_reachedBlue, 'DONE');
    return switch (hop.status) {
      TracerouteHopStatus.success => (_successGreen, 'OK'),
      TracerouteHopStatus.timeout => (_timeoutAmber, 'TIMEOUT'),
      TracerouteHopStatus.pending => (_pendingGray, 'WAIT'),
    };
  }
}
