import 'package:flutter/material.dart';

import 'dns_service.dart';

// ── Color tokens (shared with TracerouteTable palette) ────────────────
const _tableBg = Color(0xFF020617);
const _headerBg = Color(0xFF0F172A);
const _rowEven = Color(0xFF020617);
const _rowOdd = Color(0xFF0B1120);
const _headerText = Color(0xFF94A3B8);
const _cellText = Color(0xFFE2E8F0);
const _mutedText = Color(0xFF64748B);
const _successGreen = Color(0xFF22C55E);
const _primaryBlue = Color(0xFF3B82F6);
const _errorRed = Color(0xFFEF4444);
const _summaryBorder = Color(0xFF1E293B);

/// Renders DNS lookup results as a styled table matching the TracerouteTable UI.
class DnsPanel extends StatelessWidget {
  const DnsPanel({
    super.key,
    required this.domain,
    required this.recordType,
    required this.records,
    this.isLoading = false,
    this.error,
    this.hasResult = false,
    this.minHeight = 342.0,
  });

  final String domain;
  final DnsRecordType recordType;
  final List<DnsRecord> records;
  final bool isLoading;
  final String? error;
  final bool hasResult;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final isEmpty = !hasResult && !isLoading && error == null;

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
                if (isLoading) ...[
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
          else if (isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Text(
                'Resolving ${recordType.name.toUpperCase()} records for ${domain.trim()}…',
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
            // Lookup header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'DNS LOOKUP  ·  ${domain.trim()}  ·  ${recordType.name.toUpperCase()}',
                style: const TextStyle(
                  color: _cellText,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
            // Error state
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Text(
                  'Error: $error',
                  style: const TextStyle(
                    color: _errorRed,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
              )
            // No records found
            else if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _headerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _summaryBorder),
                  ),
                  child: Text(
                    'No ${recordType.name.toUpperCase()} records found for ${domain.trim()}.',
                    style: TextStyle(
                      color: _mutedText.withValues(alpha: 0.8),
                      fontFamily: 'monospace',
                      fontSize: 13,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              )
            // Records table grows with records
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildTable(),
                ),
              ),
              // Summary — always at bottom
              _buildSummary(),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(36),   // #
        1: FixedColumnWidth(60),   // TYPE
        2: FlexColumnWidth(3.0),   // VALUE
        3: FixedColumnWidth(72),   // TTL
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _buildHeaderRow(),
        for (var i = 0; i < records.length; i++) _buildRecordRow(records[i], i),
      ],
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: _headerBg),
      children: [
        _headerCell('#', align: TextAlign.center),
        _headerCell('TYPE'),
        _headerCell('VALUE'),
        _headerCell('TTL', align: TextAlign.right),
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

  TableRow _buildRecordRow(DnsRecord record, int index) {
    final bg = index.isEven ? _rowEven : _rowOdd;
    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        _dataCell('${index + 1}', align: TextAlign.center, fontWeight: FontWeight.w600),
        // Type badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _typeBadge(record.type),
          ),
        ),
        _dataCell(_cleanValue(record.value)),
        _dataCell('${record.ttl}s', align: TextAlign.right, color: _mutedText),
      ],
    );
  }

  Widget _typeBadge(String type) {
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    return switch (type) {
      'A' => _successGreen,
      'AAAA' => _primaryBlue,
      'CNAME' => const Color(0xFFA78BFA),
      'MX' => const Color(0xFFFBBF24),
      'TXT' => const Color(0xFF38BDF8),
      'NS' => const Color(0xFFF97316),
      _ => _mutedText,
    };
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

  /// Strip surrounding quotes from TXT values.
  String _cleanValue(String value) {
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _headerBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _summaryBorder),
        ),
        child: Row(
          children: [
            _summaryItem('Domain', domain.trim()),
            const SizedBox(width: 32),
            _summaryItem('Type', recordType.name.toUpperCase()),
            const SizedBox(width: 32),
            _summaryItem('Records', records.length.toString()),
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
