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
            stats: PingStats(avg: Duration(milliseconds: 24)),
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
        contains('  # 2  142.250.190.46          24 ms   ttl=57'),
      );
      expect(
        controller.activeOutputLines,
        contains('  Packets : 1 sent, 1 received, 0% loss'),
      );
      expect(controller.activeOutputLines, contains('  Latency : 24 ms avg'));

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
      expect(
        controller.activeOutputLines,
        isNot(contains('    IP Address: 10 mail.example.com')),
      );

      controller.dispose();
    });

    test('formats DNS address records with related IP address', () async {
      final controller =
          NetworkController(
              pingService: _FakePingService(const []),
              tracerouteService: _FakeTracerouteService(),
              dnsService: _FakeDnsService(
                records: const [
                  DnsRecord(type: 'A', value: '142.251.47.14', ttl: 194),
                ],
              ),
            )
            ..setActiveMode(NetworkToolMode.dns)
            ..setDnsDomain('google.com')
            ..setDnsRecordType(DnsRecordType.a);

      await controller.lookupDns();

      expect(controller.activeOutputLines, contains('[1] A'));
      expect(
        controller.activeOutputLines,
        contains('    Value: 142.251.47.14'),
      );
      expect(
        controller.activeOutputLines,
        contains('    IP Address: 142.251.47.14'),
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
  });
}

class _FakePingService extends PingService {
  _FakePingService(this.events);

  final List<PingEvent> events;
  bool stopCalled = false;

  @override
  Stream<PingEvent> ping({required String host, required int count}) async* {
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

  @override
  Future<List<DnsRecord>> lookup({
    required String domain,
    required DnsRecordType type,
  }) async {
    return records;
  }
}

class _FakeTracerouteService extends TracerouteService {
  _FakeTracerouteService({this.hops = const []});

  final List<TracerouteHop> hops;

  @override
  Stream<TracerouteHop> trace({
    required String host,
    int maxHops = 30,
    int timeout = 2,
  }) async* {
    for (final hop in hops) {
      yield hop;
    }
  }

  @override
  Future<void> stopTrace() async {}
}
