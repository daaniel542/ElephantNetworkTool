import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:net_utility_toolkit/features/network/dns_service.dart';
import 'package:net_utility_toolkit/features/network/network_controller.dart';
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
          PingSummary(
            transmitted: 1,
            received: 1,
            stats: const PingStats(avg: Duration(milliseconds: 24)),
          ),
        ]),
        dnsService: _FakeDnsService(),
        tracerouteService: _FakeTracerouteService(),
      )..setPingHost('google.com');

      await controller.startPing();

      expect(controller.isPinging, isFalse);
      expect(controller.activeOutputLines, contains('Pinging google.com...'));
      expect(
        controller.activeOutputLines,
        contains('Reply from 142.250.190.46: seq=1 ttl=57 time=24 ms'),
      );
      expect(controller.activeOutputLines, contains('Summary:'));
      expect(controller.activeOutputLines, contains('Average: 24 ms'));

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

    test('wraps long DNS values into aligned continuation lines', () async {
      const longTxt =
          'v=spf1 include:_spf.google.com include:mail.example.com '
          'include:another-long-provider.example.net ~all';
      final controller =
          NetworkController(
              pingService: _FakePingService(const []),
              tracerouteService: _FakeTracerouteService(),
              dnsService: _FakeDnsService(
                records: const [
                  DnsRecord(type: 'TXT', value: longTxt, ttl: 226),
                ],
              ),
            )
            ..setActiveMode(NetworkToolMode.dns)
            ..setDnsDomain('gmail.com')
            ..setDnsRecordType(DnsRecordType.txt);

      await controller.lookupDns();

      final output = controller.activeOutputLines.join('\n');
      expect(output, contains('[1] TXT'));
      expect(output, contains('    TTL  : 226'));
      expect(output, contains('    Key  : v'));
      expect(output, contains('    Value: spf1 include:_spf.google.com'));
      expect(
        output,
        contains('           include:another-long-provider.example.net ~all'),
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

    test('stops an active traceroute and writes a stopped line', () async {
      final tracerouteService = _FakeTracerouteService(neverCompletes: true);
      final controller = NetworkController(
        pingService: _FakePingService(const []),
        dnsService: _FakeDnsService(),
        tracerouteService: tracerouteService,
      )..setActiveMode(NetworkToolMode.trace);

      await controller.startTraceroute('1.1.1.1');

      expect(controller.isTracing, isTrue);
      expect(
        controller.activeOutputLines,
        contains('Waiting for hop responses...'),
      );

      await controller.stopTraceroute();

      expect(controller.isTracing, isFalse);
      expect(tracerouteService.stopCalled, isTrue);
      expect(
        controller.activeOutputLines,
        contains('--- Trace stopped by user ---'),
      );
      expect(
        controller.activeOutputLines,
        isNot(contains('Waiting for hop responses...')),
      );

      controller.dispose();
    });
  });
}

class _FakePingService extends PingService {
  _FakePingService(this.events);

  final List<PingEvent> events;

  @override
  Stream<PingEvent> ping({required String host, required int count}) async* {
    for (final event in events) {
      yield event;
    }
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

  @override
  void close() {}
}

class _FakeTracerouteService extends TracerouteService {
  _FakeTracerouteService({this.hops = const [], this.neverCompletes = false});

  final List<TracerouteHop> hops;
  final bool neverCompletes;
  bool stopCalled = false;
  final _controller = StreamController<TracerouteHop>();

  @override
  Stream<TracerouteHop> trace({
    required String host,
    int maxHops = 30,
    int timeout = 2,
  }) {
    if (neverCompletes) {
      return _controller.stream;
    }
    return _traceHops();
  }

  Stream<TracerouteHop> _traceHops() async* {
    for (final hop in hops) {
      yield hop;
    }
  }

  @override
  Future<void> stopTrace() async {
    stopCalled = true;
    if (!_controller.isClosed) {
      unawaited(_controller.close());
    }
  }
}
