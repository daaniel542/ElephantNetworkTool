import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dns_service.dart';
import 'ping_service.dart';
import 'traceroute_service.dart';

enum NetworkToolMode { ping, dns, trace }

/// Controller for the Network Tools screen.
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

  /// Number of ICMP packets to send. Default 4, max 20.
  int pingCount = 4;

  /// Whether a ping stream is currently active.
  bool isPinging = false;

  /// Accumulated terminal output lines from the active ping session.
  final List<String> pingOutput = [];

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

  String traceHost = '';
  bool isTracing = false;
  final List<String> traceOutput = [];
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
    pingCount = value.clamp(1, 20);
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

    await stopTraceroute();
    pingOutput.clear();
    pingError = null;

    if (host.isEmpty) {
      pingError = 'Ping failed. Please check the host.';
      _notify();
      return;
    }

    isPinging = true;
    pingOutput
      ..add('Pinging $host...')
      ..add('');
    _notify();

    try {
      await for (final event in _pingService.ping(
        host: host,
        count: pingCount,
      )) {
        pingOutput.addAll(_formatPingEvent(event, host));
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
    _notify();
  }

  /// Execute a DNS lookup for [dnsDomain] using [dnsRecordType].
  Future<void> lookupDns() async {
    final domain = dnsDomain.trim();
    if (isDnsLoading) return;

    await stopTraceroute();
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
    if (target.isEmpty) {
      traceError = 'Trace failed. Please check the host.';
      _notify();
      return;
    }

    await stopTraceroute(addStopLine: false);
    _pingService.stopPing();

    traceHost = target;
    traceOutput
      ..clear()
      ..add('Tracing route to $target...')
      ..add('Maximum hops: 30')
      ..add('')
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
            traceOutput.add(_formatTraceHop(hop));
            _notify();
          },
          onError: (_) {
            traceError = 'Trace failed. Please check the host.';
            isTracing = false;
            _notify();
          },
          onDone: () {
            isTracing = false;
            _traceSubscription = null;
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

    if (!wasTracing && addStopLine == false) {
      _notify();
    }
  }

  List<String> _formatPingEvent(PingEvent event, String host) {
    return switch (event) {
      PingResponse() => [
        'Reply from ${event.ip ?? host}: '
            '${event.seq == null ? '' : 'seq=${event.seq} '}'
            'ttl=${event.ttl ?? '?'} '
            'time=${_formatDurationMs(event.time)} ms',
      ],
      PingError() => [
        'Error${event.seq == null ? '' : ' seq=${event.seq}'}: '
            '${event.message ?? _describeError(event.error)}'
            '${event.ip == null ? '' : ' (${event.ip})'}',
      ],
      PingSummary() => _formatSummary(event),
    };
  }

  List<String> _formatSummary(PingSummary summary) {
    final lost = summary.transmitted - summary.received;
    final lines = [
      '',
      'Summary:',
      'Sent: ${summary.transmitted}',
      'Received: ${summary.received}',
      'Lost: $lost',
      'Packet loss: ${summary.packetLoss.toStringAsFixed(0)}%',
    ];

    final stats = summary.stats;
    if (stats?.avg != null) {
      lines.add('Average: ${_formatDurationMs(stats!.avg)} ms');
    }
    if (stats?.min != null && stats?.max != null) {
      lines.add(
        'Min/Max: ${_formatDurationMs(stats!.min)} / '
        '${_formatDurationMs(stats.max)} ms',
      );
    }
    return lines;
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
    final hopNumber = hop.hopNumber.toString().padLeft(2);
    final address = hop.address ?? '*';
    final latency = hop.latency == null
        ? ''
        : ' ${_formatDurationMs(hop.latency)} ms';
    final destination = hop.isDestination ? ' (destination)' : '';
    return '$hopNumber  $address$latency  ${hop.message}$destination';
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
    var remaining = value;
    while (remaining.length > width) {
      var splitAt = remaining.lastIndexOf(' ', width);
      if (splitAt <= 0) splitAt = width;

      lines.add(remaining.substring(0, splitAt).trimRight());
      remaining = remaining.substring(splitAt).trimLeft();
    }
    if (remaining.isNotEmpty) {
      lines.add(remaining);
    }
    return lines;
  }

  String _formatDurationMs(Duration? duration) {
    if (duration == null) return '?';
    final micros = duration.inMicroseconds;
    if (micros % Duration.microsecondsPerMillisecond == 0) {
      return (micros ~/ Duration.microsecondsPerMillisecond).toString();
    }
    return (micros / Duration.microsecondsPerMillisecond).toStringAsFixed(1);
  }

  String _describeError(ErrorType error) {
    return switch (error) {
      ErrorType.requestTimedOut => 'Request timed out.',
      ErrorType.unknownHost => 'Unknown host.',
      ErrorType.timeToLiveExceeded => 'Time to live exceeded.',
      ErrorType.noReply => 'No reply.',
      ErrorType.noRoute => 'No route to host.',
      ErrorType.unknown => 'Unknown error.',
    };
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
