import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dns_service.dart';
import 'ping_service.dart';
import 'traceroute_service.dart';

/// Supported DNS record types per PRD section 10.1.
enum DnsRecordType { a, aaaa, cname, mx, txt, ns }

enum NetworkToolMode { ping, dns, trace }

/// Controller for the Network Tools screen.
///
/// Manages ping state, DNS lookup state, and all user-facing input fields.
/// Both ping streaming and DNS fetching are coordinated through this class.
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

  NetworkToolMode activeMode = NetworkToolMode.ping;

  // -------------------------------------------------------------------------
  // Ping state
  // -------------------------------------------------------------------------

  /// Host or IP address entered by the user.
  String pingHost = '';

  /// Number of ICMP packets to send. Default 5, max 20.
  int pingCount = 5;

  /// Whether a ping stream is currently active.
  bool isPinging = false;

  /// Accumulated terminal output lines from the active ping session.
  final List<String> pingOutput = [];

  /// Optional error message to display in the ping panel.
  String? pingError;

  // -------------------------------------------------------------------------
  // DNS state
  // -------------------------------------------------------------------------

  /// Domain entered by the user.
  String dnsDomain = '';

  /// Currently selected record type.
  DnsRecordType dnsRecordType = DnsRecordType.a;

  /// Whether a DNS lookup is currently in flight.
  bool isDnsLoading = false;

  /// Results returned by the last successful DNS lookup.
  List<DnsRecord> dnsResults = [];

  /// Optional error message to display in the DNS panel.
  String? dnsError;

  // -------------------------------------------------------------------------
  // Trace state
  // -------------------------------------------------------------------------

  /// Hostname or IP address entered by the user for traceroute.
  String traceHost = '';

  /// Whether a traceroute stream is currently active.
  bool isTracing = false;

  /// Accumulated terminal output lines from the active traceroute session.
  final List<String> traceOutput = [];

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
      return [];
    }
    return [
      'DNS results:',
      '',
      for (final record in dnsResults)
        '${record.type.padRight(6)} ${record.value}  TTL ${record.ttl}',
    ];
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
    notifyListeners();
  }

  void setPingHost(String value) {
    pingHost = value;
  }

  void setPingCount(int value) {
    pingCount = value.clamp(1, 20);
    notifyListeners();
  }

  void setDnsDomain(String value) {
    dnsDomain = value;
  }

  void setDnsRecordType(DnsRecordType value) {
    dnsRecordType = value;
    notifyListeners();
  }

  void setTraceHost(String value) {
    traceHost = value;
  }

  // -------------------------------------------------------------------------
  // Ping actions
  // -------------------------------------------------------------------------

  /// Start streaming ping packets to [pingHost].
  Future<void> startPing() async {
    if (isPinging || pingHost.trim().isEmpty) return;

    await stopTraceroute(addStopLine: false);
    pingOutput.clear();
    pingError = null;
    isPinging = true;
    pingOutput
      ..add('Pinging ${pingHost.trim()}...')
      ..add('');
    notifyListeners();

    try {
      await _pingService.ping(
        host: pingHost.trim(),
        count: pingCount,
        onResult: (line) {
          pingOutput.add(line);
          notifyListeners();
        },
      );
    } catch (e) {
      pingError = 'Ping failed. Please check the host.';
    } finally {
      isPinging = false;
      notifyListeners();
    }
  }

  /// Abort an active ping stream.
  void stopPing() {
    _pingService.cancel();
    isPinging = false;
    pingOutput.add('--- Ping cancelled by user ---');
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // DNS actions
  // -------------------------------------------------------------------------

  /// Execute a DNS lookup for [dnsDomain] using [dnsRecordType].
  Future<void> lookupDns() async {
    if (isDnsLoading || dnsDomain.trim().isEmpty) return;

    await stopTraceroute(addStopLine: false);
    dnsResults = [];
    dnsError = null;
    isDnsLoading = true;
    notifyListeners();

    try {
      dnsResults = await _dnsService.lookup(
        domain: dnsDomain.trim(),
        type: dnsRecordType,
      );
    } catch (e) {
      dnsError = e.toString();
    } finally {
      isDnsLoading = false;
      notifyListeners();
    }
  }

  Future<void> startTraceroute(String host) async {
    final target = host.trim();
    if (target.isEmpty || isTracing) return;

    _pingService.cancel();
    await stopTraceroute(addStopLine: false);

    traceHost = target;
    traceOutput
      ..clear()
      ..add('Tracing route to $target...')
      ..add('Maximum hops: 30')
      ..add('')
      ..add('Waiting for hop responses...');
    traceError = null;
    isTracing = true;
    notifyListeners();

    _traceSubscription = _tracerouteService
        .trace(host: target)
        .listen(
          (hop) {
            if (traceOutput.isNotEmpty &&
                traceOutput.last == 'Waiting for hop responses...') {
              traceOutput.removeLast();
            }
            traceOutput.add(_formatTraceHop(hop));
            notifyListeners();
          },
          onError: (_) {
            traceError = 'Trace failed. Please check the host.';
            isTracing = false;
            notifyListeners();
          },
          onDone: () {
            isTracing = false;
            _traceSubscription = null;
            notifyListeners();
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
      notifyListeners();
    }

    await _tracerouteService.stopTrace();
    await _traceSubscription?.cancel().timeout(
      const Duration(seconds: 1),
      onTimeout: () {},
    );
    _traceSubscription = null;
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

  String _formatDurationMs(Duration? duration) {
    if (duration == null) return '?';
    final micros = duration.inMicroseconds;
    if (micros % Duration.microsecondsPerMillisecond == 0) {
      return (micros ~/ Duration.microsecondsPerMillisecond).toString();
    }
    return (micros / Duration.microsecondsPerMillisecond).toStringAsFixed(1);
  }

  @override
  void dispose() {
    _pingService.cancel();
    _traceSubscription?.cancel();
    _tracerouteService.stopTrace();
    super.dispose();
  }
}
