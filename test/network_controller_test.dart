import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:net_utility_toolkit/features/network/dns_service.dart';
import 'package:net_utility_toolkit/features/network/network_controller.dart';
import 'package:net_utility_toolkit/features/network/ping_event.dart';
import 'package:net_utility_toolkit/features/network/ping_service.dart';
import 'package:net_utility_toolkit/features/network/traceroute_service.dart';

void main() {
  group('NetworkController', () {
    test('formats ping events into terminal output lines', () async {
      final controller = NetworkController(
        pingService: _FakePingService([
          const PingResponse(
            seq: 1,
            ttl: 57,
            time: Duration(milliseconds: 24),
            ip: '142.250.190.46',
          ),
          const PingSummary(
            transmitted: 1,
            received: 1,
            stats: PingStats(
              min: Duration(milliseconds: 24),
              avg: Duration(milliseconds: 24),
              max: Duration(milliseconds: 24),
              stddev: Duration.zero,
              sampleCount: 1,
            ),
          ),
        ]),
        dnsService: _FakeDnsService(),
        tracerouteService: _FakeTracerouteService(),
      )..setPingHost('google.com');

      await controller.startPing();

      expect(controller.isPinging, isFalse);
      expect(
        controller.activeOutputLines,
        contains('PING google.com (5 packets)'),
      );
      expect(
        controller.activeOutputLines,
        contains('  timeout=2000ms  ttl=255'),
      );
      expect(
        controller.activeOutputLines,
        contains('  # 2  142.250.190.46          24 ms   ttl=57'),
      );
      expect(
        controller.activeOutputLines,
        contains('  Packets : 1 sent, 1 received, 0 lost (0% loss)'),
      );
      expect(
        controller.activeOutputLines,
        contains('  RTT     : 24 min / 24 avg / 24 max ms'),
      );
      expect(
        controller.activeOutputLines,
        contains('  Quality : 0 stddev / ? jitter ms'),
      );

      controller.dispose();
    });

    test('passes configured ping options to the ping service', () async {
      final pingService = _FakePingService([
        const PingSummary(transmitted: 0, received: 0),
      ]);
      final controller =
          NetworkController(
              pingService: pingService,
              dnsService: _FakeDnsService(),
              tracerouteService: _FakeTracerouteService(),
            )
            ..setPingHost('1.1.1.1')
            ..setPingCount(12)
            ..setPingTimeoutMs(3500)
            ..setPingTtl(64);

      await controller.startPing();

      expect(pingService.lastHost, '1.1.1.1');
      expect(pingService.lastCount, 12);
      expect(pingService.lastTimeout, const Duration(milliseconds: 3500));
      expect(pingService.lastTtl, 64);
      expect(
        controller.activeOutputLines,
        contains('PING 1.1.1.1 (12 packets)'),
      );
      expect(
        controller.activeOutputLines,
        contains('  timeout=3500ms  ttl=64'),
      );

      controller.dispose();
    });

    test('clamps ping option boundaries', () {
      final controller =
          NetworkController(
              pingService: _FakePingService(const []),
              dnsService: _FakeDnsService(),
              tracerouteService: _FakeTracerouteService(),
            )
            ..setPingCount(0)
            ..setPingTimeoutMs(0)
            ..setPingTtl(0);

      expect(controller.pingCount, PingDefaults.minCount);
      expect(controller.pingTimeoutMs, PingDefaults.minTimeoutMs);
      expect(controller.pingTtl, PingDefaults.minTtl);

      controller
        ..setPingCount(10000)
        ..setPingTimeoutMs(10000)
        ..setPingTtl(10000);

      expect(controller.pingCount, PingDefaults.maxCount);
      expect(controller.pingTimeoutMs, PingDefaults.maxTimeoutMs);
      expect(controller.pingTtl, PingDefaults.maxTtl);

      controller.dispose();
    });

    test('formats full ping metrics in the terminal summary', () async {
      final controller = NetworkController(
        pingService: _FakePingService([
          const PingSummary(
            transmitted: 4,
            received: 3,
            stats: PingStats(
              min: Duration(milliseconds: 10),
              avg: Duration(milliseconds: 20),
              max: Duration(milliseconds: 40),
              stddev: Duration(milliseconds: 12),
              jitter: Duration(milliseconds: 15),
              sampleCount: 3,
            ),
          ),
        ]),
        dnsService: _FakeDnsService(),
        tracerouteService: _FakeTracerouteService(),
      )..setPingHost('8.8.8.8');

      await controller.startPing();

      expect(
        controller.activeOutputLines,
        contains('  Packets : 4 sent, 3 received, 1 lost (25% loss)'),
      );
      expect(
        controller.activeOutputLines,
        contains('  RTT     : 10 min / 20 avg / 40 max ms'),
      );
      expect(
        controller.activeOutputLines,
        contains('  Quality : 12 stddev / 15 jitter ms'),
      );

      controller.dispose();
    });

    test('formats DNS results when DNS mode is active', () async {
      final controller =
          NetworkController(
              pingService: _FakePingService(const []),
              tracerouteService: _FakeTracerouteService(),
              dnsService: _FakeDnsService(
                records: const [
                  DnsRecord(type: 'MX', value: '10 mail.example.com', ttl: 600),
                ],
              ),
            )
            ..setActiveMode(NetworkToolMode.dns)
            ..setDnsDomain('example.com')
            ..setDnsRecordType(DnsRecordType.mx);

      await controller.lookupDns();

      expect(controller.isDnsLoading, isFalse);
      expect(controller.activeOutputLines, contains('DNS Lookup'));
      expect(controller.activeOutputLines, contains('Domain : example.com'));
      expect(controller.activeOutputLines, contains('Type   : MX'));
      expect(controller.activeOutputLines, contains('Records: 1'));
      expect(controller.activeOutputLines, contains('[1] MX'));
      expect(controller.activeOutputLines, contains('    TTL  : 600'));
      expect(
        controller.activeOutputLines,
        contains('    Value: 10 mail.example.com'),
      );

      controller.dispose();
    });

    test('shows a clear DNS empty-state message', () async {
      final controller =
          NetworkController(
              pingService: _FakePingService(const []),
              tracerouteService: _FakeTracerouteService(),
              dnsService: _FakeDnsService(),
            )
            ..setActiveMode(NetworkToolMode.dns)
            ..setDnsDomain('gmail.com')
            ..setDnsRecordType(DnsRecordType.cname);

      await controller.lookupDns();

      expect(controller.isDnsLoading, isFalse);
      expect(controller.hasDnsLookupResult, isTrue);
      expect(controller.activeOutputLines, contains('DNS Lookup'));
      expect(
        controller.activeOutputLines,
        contains('Status : No records found'),
      );
      expect(
        controller.activeOutputLines,
        contains('No CNAME records found for gmail.com.'),
      );

      controller.dispose();
    });

    test('formats traceroute metrics into terminal output lines', () async {
      final controller = NetworkController(
        pingService: _FakePingService(const []),
        dnsService: _FakeDnsService(),
        tracerouteService: _FakeTracerouteService(
          hops: [
            TracerouteHop(
              hopNumber: 1,
              status: TracerouteHopStatus.success,
              address: '192.168.1.1',
              probes: const [
                Duration(milliseconds: 2),
                null,
                Duration(milliseconds: 4),
              ],
              message: 'TTL exceeded',
            ),
            TracerouteHop(
              hopNumber: 2,
              status: TracerouteHopStatus.timeout,
              message: 'Request timed out.',
            ),
            TracerouteHop(
              hopNumber: 3,
              status: TracerouteHopStatus.success,
              address: '93.184.216.34',
              probes: const [
                Duration(milliseconds: 24),
                Duration(milliseconds: 27),
                Duration(milliseconds: 30),
              ],
              message: 'Reached destination',
              isDestination: true,
            ),
          ],
        ),
      )..setActiveMode(NetworkToolMode.trace);

      await controller.startTraceroute('example.com');
      await Future<void>.delayed(Duration.zero);

      expect(controller.isTracing, isFalse);
      expect(
        controller.activeOutputLines,
        contains('Trace to example.com | max hops 30'),
      );
      expect(controller.activeOutputText, contains('Hop | TTL | Status'));
      expect(controller.activeOutputText, contains('192.168.1.1'));
      expect(controller.activeOutputText, contains('01  |   1 | success'));
      expect(
        controller.activeOutputText,
        contains('2ms |        * |      4ms |      3ms'),
      );
      expect(controller.activeOutputText, contains('Timed out'));
      expect(controller.activeOutputText, contains('03  |   3 | reached'));
      expect(
        controller.activeOutputText,
        contains('24ms |     27ms |     30ms |     27ms'),
      );
      expect(controller.activeOutputText, contains('Trace Summary'));
      expect(
        controller.activeOutputText,
        contains('Destination : 93.184.216.34'),
      );
      expect(controller.activeOutputText, contains('Hops        : 3'));
      expect(controller.activeOutputText, contains('End-to-end  : 27ms'));
      expect(controller.traceHops, hasLength(3));
      expect(
        controller.traceHops[0].averageRtt,
        const Duration(milliseconds: 3),
      );
      expect(controller.traceHops[1].averageRtt, isNull);
      expect(
        controller.traceSummary?.totalEndToEndLatency,
        const Duration(milliseconds: 27),
      );

      controller.dispose();
    });

    test('rejects empty ping input without calling the service', () async {
      final pingService = _FakePingService(const []);
      final controller = NetworkController(
        pingService: pingService,
        dnsService: _FakeDnsService(),
        tracerouteService: _FakeTracerouteService(),
      );

      await controller.startPing();

      expect(controller.pingError, 'Ping failed. Please check the host.');
      expect(pingService.lastHost, isNull);

      controller.dispose();
    });

    test('formats ping error events for common failure types', () async {
      final controller = NetworkController(
        pingService: _FakePingService([
          const PingError(seq: 0, message: 'Request timed out.'),
          const PingError(seq: 1, message: 'No route to host.'),
          const PingError(seq: 2, message: 'Unknown host.'),
          const PingError(seq: 3, message: 'Time to live exceeded.'),
          const PingSummary(transmitted: 4, received: 0),
        ]),
        dnsService: _FakeDnsService(),
        tracerouteService: _FakeTracerouteService(),
      )..setPingHost('unreliable.example');

      await controller.startPing();

      expect(controller.activeOutputText, contains('Request timed out.'));
      expect(controller.activeOutputText, contains('No route to host.'));
      expect(controller.activeOutputText, contains('Unknown host.'));
      expect(controller.activeOutputText, contains('Time to live exceeded.'));
      expect(controller.activeOutputText, contains('4 sent, 0 received'));

      controller.dispose();
    });

    test(
      'separates unsupported ping rows from ordinary network failures',
      () async {
        final controller = NetworkController(
          pingService: _FakePingService([
            const PingError(
              isUnsupported: true,
              message:
                  'Ping requires raw ICMP access, which browser builds cannot use.',
            ),
            const PingSummary(transmitted: 1, received: 0),
          ]),
          dnsService: _FakeDnsService(),
          tracerouteService: _FakeTracerouteService(),
        )..setPingHost('example.com');

        await controller.startPing();

        expect(controller.pingRows.single, isA<PingError>());
        expect((controller.pingRows.single as PingError).isUnsupported, isTrue);
        expect(controller.activeOutputText, contains('Unsupported'));

        controller.dispose();
      },
    );

    test('handles ping stream exceptions with a clean error', () async {
      final controller = NetworkController(
        pingService: _ThrowingPingService(),
        dnsService: _FakeDnsService(),
        tracerouteService: _FakeTracerouteService(),
      )..setPingHost('explode.example');

      await controller.startPing();

      expect(controller.isPinging, isFalse);
      expect(controller.pingError, 'Ping failed. Please check the host.');

      controller.dispose();
    });

    test('stops an active ping and records a stopped line', () async {
      final release = Completer<void>();
      final pingService = _BlockingPingService(release);
      final controller = NetworkController(
        pingService: pingService,
        dnsService: _FakeDnsService(),
        tracerouteService: _FakeTracerouteService(),
      )..setPingHost('slow.example');

      final pingFuture = controller.startPing();
      await pingService.started.future;

      expect(controller.isPinging, isTrue);
      controller.stopPing();
      release.complete();
      await pingFuture;

      expect(pingService.stopCalled, isTrue);
      expect(controller.activeOutputText, contains('Ping stopped by user'));
      expect(controller.isPinging, isFalse);

      controller.dispose();
    });

    test('rejects empty DNS input without calling the service', () async {
      final dnsService = _FakeDnsService();
      final controller = NetworkController(
        pingService: _FakePingService(const []),
        dnsService: dnsService,
        tracerouteService: _FakeTracerouteService(),
      )..setActiveMode(NetworkToolMode.dns);

      await controller.lookupDns();

      expect(
        controller.dnsError,
        'DNS lookup failed. Please check the domain.',
      );
      expect(controller.hasDnsLookupResult, isTrue);
      expect(dnsService.lastDomain, isNull);

      controller.dispose();
    });

    test('surfaces DNS service exceptions verbatim', () async {
      final controller =
          NetworkController(
              pingService: _FakePingService(const []),
              dnsService: _ThrowingDnsService(
                const DnsServiceException('Domain does not exist.'),
              ),
              tracerouteService: _FakeTracerouteService(),
            )
            ..setActiveMode(NetworkToolMode.dns)
            ..setDnsDomain('missing.invalid');

      await controller.lookupDns();

      expect(controller.dnsError, 'Domain does not exist.');

      controller.dispose();
    });

    test('rejects empty traceroute input without starting a trace', () async {
      final traceService = _FakeTracerouteService();
      final controller = NetworkController(
        pingService: _FakePingService(const []),
        dnsService: _FakeDnsService(),
        tracerouteService: traceService,
      )..setActiveMode(NetworkToolMode.trace);

      await controller.startTraceroute('');

      expect(controller.traceError, 'Trace failed. Please check the host.');
      expect(traceService.started, isFalse);

      controller.dispose();
    });

    test('handles traceroute stream exceptions with a clean error', () async {
      final controller = NetworkController(
        pingService: _FakePingService(const []),
        dnsService: _FakeDnsService(),
        tracerouteService: _ThrowingTracerouteService(),
      )..setActiveMode(NetworkToolMode.trace);

      await controller.startTraceroute('explode.example');
      await Future<void>.delayed(Duration.zero);

      expect(controller.isTracing, isFalse);
      expect(controller.traceError, 'Trace failed. Please check the host.');

      controller.dispose();
    });

    test(
      'separates unsupported traceroute rows from ordinary timeouts',
      () async {
        final controller = NetworkController(
          pingService: _FakePingService(const []),
          dnsService: _FakeDnsService(),
          tracerouteService: _FakeTracerouteService(
            hops: [
              TracerouteHop(
                hopNumber: 1,
                status: TracerouteHopStatus.unsupported,
                message: 'Traceroute is not supported on web.',
              ),
            ],
          ),
        )..setActiveMode(NetworkToolMode.trace);

        await controller.startTraceroute('example.com');
        await Future<void>.delayed(Duration.zero);

        expect(
          controller.traceHops.single.status,
          TracerouteHopStatus.unsupported,
        );
        expect(controller.activeOutputText, contains('Unsupported'));
        expect(controller.activeOutputText, contains('n/a'));

        controller.dispose();
      },
    );
  });
}

class _FakePingService extends PingService {
  _FakePingService(this.events);

  final List<PingEvent> events;
  bool stopCalled = false;
  String? lastHost;
  int? lastCount;
  Duration? lastTimeout;
  int? lastTtl;

  @override
  Stream<PingEvent> ping({
    required String host,
    required int count,
    required Duration timeout,
    required int ttl,
  }) async* {
    lastHost = host;
    lastCount = count;
    lastTimeout = timeout;
    lastTtl = ttl;

    for (final event in events) {
      yield event;
    }
  }

  @override
  void stopPing() {
    stopCalled = true;
  }
}

class _FakeDnsService extends DnsService {
  _FakeDnsService({this.records = const []});

  final List<DnsRecord> records;
  String? lastDomain;
  DnsRecordType? lastType;

  @override
  Future<List<DnsRecord>> lookup({
    required String domain,
    required DnsRecordType type,
  }) async {
    lastDomain = domain;
    lastType = type;
    return records;
  }
}

class _FakeTracerouteService extends TracerouteService {
  _FakeTracerouteService({this.hops = const []});

  final List<TracerouteHop> hops;
  bool started = false;

  @override
  Stream<TracerouteHop> trace({
    required String host,
    int maxHops = 30,
    int timeout = 2,
  }) async* {
    started = true;
    for (final hop in hops) {
      yield hop;
    }
  }

  @override
  Future<void> stopTrace() async {}
}

class _ThrowingPingService extends PingService {
  @override
  Stream<PingEvent> ping({
    required String host,
    required int count,
    required Duration timeout,
    required int ttl,
  }) async* {
    throw StateError('native ping failed');
  }
}

class _BlockingPingService extends PingService {
  _BlockingPingService(this.release);

  final Completer<void> release;
  final Completer<void> started = Completer<void>();
  bool stopCalled = false;

  @override
  Stream<PingEvent> ping({
    required String host,
    required int count,
    required Duration timeout,
    required int ttl,
  }) async* {
    started.complete();
    yield const PingResponse(
      seq: 0,
      ip: '192.0.2.10',
      ttl: 64,
      time: Duration(milliseconds: 10),
    );
    await release.future;
    yield const PingSummary(transmitted: 1, received: 1);
  }

  @override
  void stopPing() {
    stopCalled = true;
  }
}

class _ThrowingDnsService extends DnsService {
  _ThrowingDnsService(this.exception);

  final DnsServiceException exception;

  @override
  Future<List<DnsRecord>> lookup({
    required String domain,
    required DnsRecordType type,
  }) async {
    throw exception;
  }
}

class _ThrowingTracerouteService extends TracerouteService {
  @override
  Stream<TracerouteHop> trace({
    required String host,
    int maxHops = 30,
    int timeout = 2,
  }) async* {
    throw StateError('native trace failed');
  }

  @override
  Future<void> stopTrace() async {}
}
