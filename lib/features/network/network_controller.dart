import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dns_service.dart';
import 'ping_event.dart';
import 'ping_service.dart';
import 'traceroute_service.dart';

enum NetworkToolMode { ping, dns, trace }

const _traceHopWidth = 3;
const _traceTtlWidth = 3;
const _traceStatusWidth = 7;
const _traceAddressWidth = 16;
const _traceMetricWidth = 8;

final _traceTableHeader =
    '${_traceRow('Hop', 'TTL', 'Status', 'IP', 'P1', 'P2', 'P3', 'Avg')}\n'
    '${_traceRow('-' * _traceHopWidth, '-' * _traceTtlWidth, '-' * _traceStatusWidth, '-' * _traceAddressWidth, '-' * _traceMetricWidth, '-' * _traceMetricWidth, '-' * _traceMetricWidth, '-' * _traceMetricWidth)}';

String _traceRow(
  String hop,
  String ttl,
  String status,
  String address,
  String probe1,
  String probe2,
  String probe3,
  String average,
) {
  return '${_traceTextCell(hop, _traceHopWidth)} | '
      '${_traceRightCell(ttl, _traceTtlWidth)} | '
      '${_traceTextCell(status, _traceStatusWidth)} | '
      '${_traceTextCell(address, _traceAddressWidth)} | '
      '${_traceMetricCell(probe1)} | '
      '${_traceMetricCell(probe2)} | '
      '${_traceMetricCell(probe3)} | '
      '${_traceMetricCell(average)}';
}

String _traceTextCell(String value, int width) {
  if (value.length <= width) return value.padRight(width);
  return value.substring(0, width);
}

String _traceRightCell(String value, int width) {
  if (value.length <= width) return value.padLeft(width);
  return value.substring(0, width);
}

String _traceMetricCell(String value) {
  return _traceRightCell(value, _traceMetricWidth);
}

/// Controller for the Network screen.
///
/// Owns UI state, validates inputs, debounces async actions, and translates
/// typed service results into terminal-friendly lines.
class NetworkController extends ChangeNotifier {
  NetworkController({
    required PingService pingService,
    required DnsService dnsService,
    required TracerouteService tracerouteService,
  }) : _pingService = pingService,
       _dnsService = dnsService,
       _tracerouteService = tracerouteService;

  final PingService _pingService;
  final DnsService _dnsService;
  final TracerouteService _tracerouteService;
  StreamSubscription<TracerouteHop>? _traceSubscription;

  bool _isDisposed = false;

  NetworkToolMode activeMode = NetworkToolMode.ping;

  /// Host or IP address entered by the user.
  String pingHost = '';

  /// Number of ICMP packets to send when continuous mode is disabled.
  int pingCount = PingDefaults.count;

  /// Per-packet timeout in milliseconds.
  int pingTimeoutMs = PingDefaults.timeoutMs;

  /// Time-to-live/hop limit for outgoing ping packets.
  int pingTtl = PingDefaults.ttl;

  /// Whether a ping stream is currently active.
  bool isPinging = false;

  /// Accumulated terminal output lines from the active ping session.
  final List<String> pingOutput = [];

  /// Structured ping result rows (responses + errors) for the table UI.
  final List<PingEvent> pingRows = [];

  /// Summary data from the completed ping session.
  PingSummary? pingSummaryData;

  /// Optional error message to display in the ping panel.
  String? pingError;

  /// Domain entered by the user.
  String dnsDomain = '';

  /// Currently selected DNS record type.
  DnsRecordType dnsRecordType = DnsRecordType.a;

  /// Whether a DNS lookup is currently in flight.
  bool isDnsLoading = false;

  /// Results returned by the last successful DNS lookup.
  List<DnsRecord> dnsResults = [];

  /// Optional error message to display in the DNS panel.
  String? dnsError;

  /// Whether the user has completed at least one DNS lookup in this session.
  bool hasDnsLookupResult = false;

  /// Hostname or IP address entered by the user for traceroute.
  String traceHost = '';

  /// Whether a traceroute stream is currently active.
  bool isTracing = false;

  /// Accumulated terminal output lines from the active traceroute session.
  final List<String> traceOutput = [];

  /// Structured hop rows from the active or most recent traceroute session.
  final List<TracerouteHop> traceHops = [];

  /// Derived totals from the most recent completed traceroute session.
  TracerouteSummary? traceSummary;

  /// Optional error message to display in the trace panel.
  String? traceError;

  bool get isBusy => isPinging || isDnsLoading || isTracing;

  List<String> get activeOutputLines {
    return switch (activeMode) {
      NetworkToolMode.ping => _pingLines,
      NetworkToolMode.dns => _dnsLines,
      NetworkToolMode.trace => _traceLines,
    };
  }

  String get activeOutputText => activeOutputLines.join('\n');

  List<String> get _pingLines {
    final lines = <String>[...pingOutput.expand((line) => line.split('\n'))];
    if (pingError != null) {
      lines.add('Error: $pingError');
    }
    return lines;
  }

  List<String> get _dnsLines {
    if (dnsError != null) {
      return ['Error: $dnsError'];
    }
    if (dnsResults.isEmpty) {
      if (!hasDnsLookupResult) {
        return const [];
      }
      return [
        'DNS Lookup',
        'Domain : ${dnsDomain.trim()}',
        'Type   : ${dnsRecordType.queryValue}',
        'Status : No records found',
        '',
        'No ${dnsRecordType.queryValue} records found for ${dnsDomain.trim()}.',
      ];
    }

    final lines = [
      'DNS Lookup',
      'Domain : ${dnsDomain.trim()}',
      'Type   : ${dnsRecordType.queryValue}',
      'Records: ${dnsResults.length}',
    ];

    for (var i = 0; i < dnsResults.length; i += 1) {
      lines.add('');
      lines.addAll(_formatDnsRecord(i + 1, dnsResults[i]));
    }

    return lines;
  }

  List<String> get _traceLines {
    final lines = <String>[...traceOutput.expand((line) => line.split('\n'))];
    if (traceError != null) {
      lines.add('Error: $traceError');
    }
    return lines;
  }

  void setActiveMode(NetworkToolMode mode) {
    if (activeMode == mode) return;
    if (activeMode == NetworkToolMode.trace && mode != NetworkToolMode.trace) {
      unawaited(stopTraceroute());
    }
    activeMode = mode;
    _notify();
  }

  void setPingHost(String value) {
    pingHost = value;
  }

  void setPingCount(int value) {
    pingCount = value
        .clamp(PingDefaults.minCount, PingDefaults.maxCount)
        .toInt();
    _notify();
  }

  void setPingTimeoutMs(int value) {
    pingTimeoutMs = value
        .clamp(PingDefaults.minTimeoutMs, PingDefaults.maxTimeoutMs)
        .toInt();
    _notify();
  }

  void setPingTtl(int value) {
    pingTtl = value.clamp(PingDefaults.minTtl, PingDefaults.maxTtl).toInt();
    _notify();
  }

  void setDnsDomain(String value) {
    dnsDomain = value;
  }

  void setDnsRecordType(DnsRecordType value) {
    if (dnsRecordType == value) return;
    dnsRecordType = value;
    _notify();
  }

  void setTraceHost(String value) {
    traceHost = value;
  }

  /// Start streaming ping packets to [pingHost].
  Future<void> startPing() async {
    final host = pingHost.trim();
    if (isPinging) return;

    await stopTraceroute(addStopLine: false);
    pingOutput.clear();
    pingRows.clear();
    pingSummaryData = null;
    pingError = null;

    if (host.isEmpty) {
      pingError = 'Ping failed. Please check the host.';
      _notify();
      return;
    }

    isPinging = true;
    pingOutput
      ..add('PING $host ($pingCount packets)')
      ..add('  timeout=${pingTimeoutMs}ms  ttl=$pingTtl')
      ..add('────────────────────────────────────────');
    _notify();

    try {
      await for (final event in _pingService.ping(
        host: host,
        count: pingCount,
        timeout: Duration(milliseconds: pingTimeoutMs),
        ttl: pingTtl,
      )) {
        pingOutput.addAll(_formatPingEvent(event, host));
        if (event is PingSummary) {
          pingSummaryData = event;
        } else {
          pingRows.add(event);
        }
        _notify();
      }
    } catch (_) {
      pingError = 'Ping failed. Please check the host.';
    } finally {
      _pingService.stopPing();
      isPinging = false;
      _notify();
    }
  }

  /// Abort an active ping stream.
  void stopPing() {
    if (!isPinging) return;

    _pingService.stopPing();
    isPinging = false;
    pingOutput.add('--- Ping stopped by user ---');
    // Mark as stopped so the UI can show a stopped indicator.
    pingSummaryData = null;
    _notify();
  }

  /// Execute a DNS lookup for [dnsDomain] using [dnsRecordType].
  Future<void> lookupDns() async {
    final domain = dnsDomain.trim();
    if (isDnsLoading) return;

    await stopTraceroute(addStopLine: false);
    dnsResults = [];
    dnsError = null;
    hasDnsLookupResult = false;

    if (domain.isEmpty) {
      dnsError = 'DNS lookup failed. Please check the domain.';
      hasDnsLookupResult = true;
      _notify();
      return;
    }

    isDnsLoading = true;
    _notify();

    try {
      dnsResults = await _dnsService.lookup(
        domain: domain,
        type: dnsRecordType,
      );
    } on DnsServiceException catch (e) {
      dnsError = e.message;
    } catch (_) {
      dnsError = 'DNS lookup failed. Please check the domain.';
    } finally {
      hasDnsLookupResult = true;
      isDnsLoading = false;
      _notify();
    }
  }

  Future<void> startTraceroute(String host) async {
    final target = host.trim();
    if (target.isEmpty || isTracing) {
      if (target.isEmpty) {
        traceError = 'Trace failed. Please check the host.';
        _notify();
      }
      return;
    }

    _pingService.stopPing();
    await stopTraceroute(addStopLine: false);

    traceHost = target;
    traceHops.clear();
    traceSummary = null;
    traceOutput
      ..clear()
      ..add('Trace to $target | max hops 30')
      ..add('')
      ..add(_traceTableHeader)
      ..add('Waiting for hop responses...');
    traceError = null;
    isTracing = true;
    _notify();

    _traceSubscription = _tracerouteService
        .trace(host: target, maxHops: 30)
        .listen(
          (hop) {
            if (traceOutput.isNotEmpty &&
                traceOutput.last == 'Waiting for hop responses...') {
              traceOutput.removeLast();
            }
            traceHops.add(hop);
            traceOutput.add(_formatTraceHop(hop));
            _notify();
          },
          onError: (_) {
            traceError = 'Trace failed. Please check the host.';
            isTracing = false;
            _traceSubscription = null;
            _notify();
          },
          onDone: () {
            isTracing = false;
            _traceSubscription = null;
            if (traceHops.isNotEmpty) {
              if (traceOutput.isNotEmpty &&
                  traceOutput.last == 'Waiting for hop responses...') {
                traceOutput.removeLast();
              }
              traceSummary = TracerouteSummary.fromHops(traceHops);
              traceOutput.addAll(_formatTraceSummary(traceSummary!));
            }
            _notify();
          },
          cancelOnError: true,
        );
  }

  Future<void> stopTraceroute({bool addStopLine = true}) async {
    final wasTracing = isTracing;
    isTracing = false;

    if (wasTracing && addStopLine) {
      if (traceOutput.isNotEmpty &&
          traceOutput.last == 'Waiting for hop responses...') {
        traceOutput.removeLast();
      }
      traceOutput.add('--- Trace stopped by user ---');
    }

    if (wasTracing) {
      _notify();
    }

    await _tracerouteService.stopTrace();
    await _traceSubscription?.cancel().timeout(
      const Duration(seconds: 1),
      onTimeout: () {},
    );
    _traceSubscription = null;
  }

  List<String> _formatPingEvent(PingEvent event, String host) {
    return switch (event) {
      PingResponse() => [
        '  ${_padSeq(event.seq)}  ${(event.ip ?? host).padRight(18)}  '
            '${_formatDurationMs(event.time).padLeft(6)} ms   '
            'ttl=${event.ttl ?? '?'}',
      ],
      PingError() => [
        '  ${_padSeq(event.seq)}  '
            '${(event.isUnsupported ? 'Unsupported' : event.message ?? 'Ping request failed.').padRight(18)}  '
            '${event.ip == null ? '' : '(${event.ip})'}',
      ],
      PingSummary() => _formatSummary(event),
    };
  }

  List<String> _formatSummary(PingSummary summary) {
    final lost = summary.transmitted > summary.received
        ? summary.transmitted - summary.received
        : 0;
    final lines = [
      '',
      '────────────────────────────────────────',
      '  Packets : ${summary.transmitted} sent, '
          '${summary.received} received, '
          '$lost lost (${summary.packetLoss.toStringAsFixed(0)}% loss)',
    ];

    final stats = summary.stats;
    if (stats?.min != null && stats?.avg != null && stats?.max != null) {
      lines.add(
        '  RTT     : ${_formatDurationMs(stats!.min)} min / '
        '${_formatDurationMs(stats.avg)} avg / '
        '${_formatDurationMs(stats.max)} max ms',
      );
      if (stats.stddev != null || stats.jitter != null) {
        lines.add(
          '  Quality : ${_formatDurationMs(stats.stddev)} stddev / '
          '${_formatDurationMs(stats.jitter)} jitter ms',
        );
      }
    } else if (stats?.avg != null) {
      lines.add('  RTT     : ${_formatDurationMs(stats!.avg)} ms avg');
    } else if (summary.transmitted > 0) {
      lines.add('  RTT     : No replies received');
    }
    return lines;
  }

  String _padSeq(int? seq) {
    if (seq == null) return '  ';
    return '#${(seq + 1).toString().padLeft(2)}';
  }

  List<String> _formatDnsRecord(int index, DnsRecord record) {
    final lines = ['[$index] ${record.type}', '    TTL  : ${record.ttl}'];

    final txtParts = record.type == 'TXT'
        ? _splitTxtRecord(record.value)
        : null;
    if (txtParts == null) {
      lines.addAll(_formatWrappedField('Value', record.value));
      return lines;
    }

    lines.add('    Key  : ${txtParts.key}');
    lines.addAll(_formatWrappedField('Value', txtParts.value));
    return lines;
  }

  String _formatTraceHop(TracerouteHop hop) {
    return _traceRow(
      hop.hopNumber.toString().padLeft(2, '0'),
      hop.hopNumber.toString(),
      _formatTraceStatus(hop),
      _compactTraceAddress(hop),
      _formatTraceProbe(hop.probe1),
      _formatTraceProbe(hop.probe2),
      _formatTraceProbe(hop.probe3),
      _formatTraceAverage(hop.averageRtt),
    );
  }

  List<String> _formatTraceSummary(TracerouteSummary summary) {
    return [
      '',
      '────────────────────────────────────────',
      'Trace Summary',
      '  Destination : ${summary.destinationReached ?? 'Not reached'}',
      '  Hops        : ${summary.totalHops}',
      '  End-to-end  : ${_formatTraceAverage(summary.totalEndToEndLatency)}',
    ];
  }

  String _formatTraceStatus(TracerouteHop hop) {
    if (hop.isDestination) return 'reached';
    return switch (hop.status) {
      TracerouteHopStatus.pending => 'pending',
      TracerouteHopStatus.success => 'success',
      TracerouteHopStatus.timeout => 'timeout',
      TracerouteHopStatus.unsupported => 'n/a',
    };
  }

  String _compactTraceAddress(TracerouteHop hop) {
    if (hop.status == TracerouteHopStatus.timeout) return 'Timed out';
    if (hop.status == TracerouteHopStatus.unsupported) return 'Unsupported';
    if (hop.displayAddress.isEmpty) return 'Unknown hop';
    return hop.displayAddress;
  }

  String _formatTraceProbe(Duration? duration) {
    if (duration == null) return '*';
    return '${_formatDurationMs(duration)}ms';
  }

  String _formatTraceAverage(Duration? duration) {
    if (duration == null) return '-';
    return '${_formatDurationMs(duration)}ms';
  }

  String _formatDurationMs(Duration? duration) {
    if (duration == null) return '?';
    final micros = duration.inMicroseconds;
    if (micros % Duration.microsecondsPerMillisecond == 0) {
      return (micros ~/ Duration.microsecondsPerMillisecond).toString();
    }
    return (micros / Duration.microsecondsPerMillisecond).toStringAsFixed(1);
  }

  ({String key, String value})? _splitTxtRecord(String rawValue) {
    final value = _stripOuterQuotes(rawValue);
    final separatorIndex = value.indexOf('=');
    if (separatorIndex <= 0 || separatorIndex == value.length - 1) {
      return null;
    }

    return (
      key: value.substring(0, separatorIndex),
      value: value.substring(separatorIndex + 1),
    );
  }

  String _stripOuterQuotes(String value) {
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  List<String> _formatWrappedField(String label, String value) {
    const valueWidth = 72;
    final valueLines = _wrapText(_stripOuterQuotes(value), valueWidth);
    return [
      '    ${label.padRight(5)}: ${valueLines.first}',
      for (final line in valueLines.skip(1)) '           $line',
    ];
  }

  List<String> _wrapText(String value, int width) {
    if (value.length <= width) return [value];

    final lines = <String>[];
    final words = value.split(RegExp(r'\s+'));
    var current = '';

    for (final word in words) {
      final next = current.isEmpty ? word : '$current $word';
      if (next.length > width && current.isNotEmpty) {
        lines.add(current);
        current = word;
      } else {
        current = next;
      }
    }

    if (current.isNotEmpty) {
      lines.add(current);
    }
    return lines.isEmpty ? [''] : lines;
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pingService.stopPing();
    _traceSubscription?.cancel();
    _tracerouteService.stopTrace();
    _dnsService.close();
    super.dispose();
  }
}

extension on DnsRecordType {
  String get queryValue => name.toUpperCase();
}
