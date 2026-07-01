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

    test('formats traceroute hops into terminal output lines', () async {
      final controller = NetworkController(
        pingService: _FakePingService(const []),
        dnsService: _FakeDnsService(),
        tracerouteService: _FakeTracerouteService(
          hops: const [
            TracerouteHop(
              hopNumber: 1,
              address: '192.168.1.1',
              latency: Duration(milliseconds: 2),
              message: 'TTL exceeded',
            ),
            TracerouteHop(
              hopNumber: 2,
              address: '93.184.216.34',
              latency: Duration(milliseconds: 24),
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
        contains('Tracing route to example.com...'),
      );
      expect(
        controller.activeOutputLines,
        contains(' 1  192.168.1.1 2 ms  TTL exceeded'),
      );
      expect(
        controller.activeOutputLines,
        contains(' 2  93.184.216.34 24 ms  Reached destination (destination)'),
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
