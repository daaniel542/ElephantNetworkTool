import 'package:flutter/material.dart';

import 'ping_event.dart';

// ── Color tokens (shared with TracerouteTable palette) ────────────────
const _tableBg = Color(0xFF020617);
const _headerBg = Color(0xFF0F172A);
const _rowEven = Color(0xFF020617);
const _rowOdd = Color(0xFF0B1120);
const _headerText = Color(0xFF94A3B8);
const _cellText = Color(0xFFE2E8F0);
const _mutedText = Color(0xFF64748B);
const _successGreen = Color(0xFF22C55E);
const _errorRed = Color(0xFFEF4444);
const _summaryBorder = Color(0xFF1E293B);
const _primaryBlue = Color(0xFF3B82F6);

/// Renders live ping responses as a styled table matching the TracerouteTable UI.
class PingTable extends StatelessWidget {
  const PingTable({
    super.key,
    required this.host,
    required this.pingCount,
    required this.timeoutMs,
    required this.ttl,
    required this.rows,
    this.summary,
    this.isPinging = false,
    this.error,
    this.stoppedByUser = false,
    this.minHeight = 342.0,
  });

  final String host;
  final int pingCount;
  final int timeoutMs;
  final int ttl;
  final List<PingEvent> rows;
  final PingSummary? summary;
  final bool isPinging;
  final String? error;
  final bool stoppedByUser;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final hasStarted = rows.isNotEmpty || isPinging || summary != null || error != null;

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
                if (isPinging) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: _primaryBlue.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!hasStarted)
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
            // Header line
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'PING $host  ·  $pingCount packets  ·  timeout ${timeoutMs}ms  ·  ttl $ttl',
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
            if (rows.isNotEmpty)
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
                    color: _errorRed,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
              ),
            // Live indicator
            if (isPinging && rows.isNotEmpty)
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
                      'Waiting for reply ${rows.length + 1} of $pingCount…',
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
            // Stopped indicator
            if (stoppedByUser && !isPinging && summary == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(
                  '— Ping stopped by user —',
                  style: TextStyle(
                    color: _mutedText.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
              ),
            // Summary card
            if (summary != null && !isPinging) _buildSummary(summary!),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(44),   // SEQ
        1: FlexColumnWidth(2.0),   // IP
        2: FixedColumnWidth(76),   // STATUS
        3: FixedColumnWidth(52),   // TTL
        4: FlexColumnWidth(1.0),   // LATENCY
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _buildHeaderRow(),
        for (var i = 0; i < rows.length; i++) _buildRow(rows[i], i),
      ],
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: _headerBg),
      children: [
        _headerCell('SEQ', align: TextAlign.center),
        _headerCell('IP ADDRESS'),
        _headerCell('STATUS', align: TextAlign.center),
        _headerCell('TTL', align: TextAlign.center),
        _headerCell('LATENCY', align: TextAlign.right),
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

  TableRow _buildRow(PingEvent event, int index) {
    final bg = index.isEven ? _rowEven : _rowOdd;
    return switch (event) {
      PingResponse() => _buildResponseRow(event, index, bg),
      PingError() => _buildErrorRow(event, index, bg),
      PingSummary() => _buildHeaderRow(), // shouldn't appear here
    };
  }

  TableRow _buildResponseRow(PingResponse r, int index, Color bg) {
    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        _dataCell('#${(r.seq ?? index) + 1}', align: TextAlign.center, fontWeight: FontWeight.w600),
        _dataCell(r.ip ?? host),
        // Status badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: _badge(_successGreen, 'OK'),
          ),
        ),
        _dataCell(r.ttl?.toString() ?? '—', align: TextAlign.center),
        _dataCell(_fmtDuration(r.time), align: TextAlign.right),
      ],
    );
  }

  TableRow _buildErrorRow(PingError e, int index, Color bg) {
    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        _dataCell('#${(e.seq ?? index) + 1}', align: TextAlign.center, fontWeight: FontWeight.w600),
        _dataCell(e.ip ?? host, color: _mutedText),
        // Status badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: _badge(_errorRed, 'FAIL'),
          ),
        ),
        _dataCell('—', align: TextAlign.center, color: _mutedText),
        _dataCell(e.message ?? 'Timeout', align: TextAlign.right, color: _mutedText),
      ],
    );
  }

  Widget _badge(Color color, String label) {
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

  String _fmtDuration(Duration? d) {
    if (d == null) return '—';
    final micros = d.inMicroseconds;
    if (micros % Duration.microsecondsPerMillisecond == 0) {
      return '${micros ~/ Duration.microsecondsPerMillisecond}ms';
    }
    return '${(micros / Duration.microsecondsPerMillisecond).toStringAsFixed(1)}ms';
  }

  Widget _buildSummary(PingSummary s) {
    final stats = s.stats;
    final lost = s.transmitted > s.received ? s.transmitted - s.received : 0;
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
              'PING SUMMARY',
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
                _summaryItem('Sent', s.transmitted.toString()),
                const SizedBox(width: 28),
                _summaryItem('Received', s.received.toString()),
                const SizedBox(width: 28),
                _summaryItem('Lost', '$lost (${s.packetLoss.toStringAsFixed(0)}%)'),
                if (stats?.avg != null) ...[
                  const SizedBox(width: 28),
                  _summaryItem('Avg RTT', _fmtDuration(stats!.avg)),
                ],
                if (stats?.min != null && stats?.max != null) ...[
                  const SizedBox(width: 28),
                  _summaryItem('Min / Max', '${_fmtDuration(stats!.min)} / ${_fmtDuration(stats.max)}'),
                ],
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
