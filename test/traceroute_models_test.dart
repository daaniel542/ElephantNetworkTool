import 'package:flutter_test/flutter_test.dart';
import 'package:net_utility_toolkit/features/network/mock_traceroute_stream.dart';
import 'package:net_utility_toolkit/features/network/traceroute_service.dart';

void main() {
  group('TracerouteHop', () {
    test('averages all three successful probes', () {
      final hop = TracerouteHop(
        hopNumber: 1,
        status: TracerouteHopStatus.success,
        probes: const [
          Duration(milliseconds: 9),
          Duration(milliseconds: 12),
          Duration(milliseconds: 15),
        ],
        message: 'TTL exceeded',
      );

      expect(hop.averageRtt, const Duration(milliseconds: 12));
    });

    test('averages two successful probes and ignores a timeout', () {
      final hop = TracerouteHop(
        hopNumber: 1,
        status: TracerouteHopStatus.success,
        probes: const [
          Duration(milliseconds: 10),
          null,
          Duration(milliseconds: 14),
        ],
        message: 'TTL exceeded',
      );

      expect(hop.averageRtt, const Duration(milliseconds: 12));
    });

    test('averages one successful probe and ignores two timeouts', () {
      final hop = TracerouteHop(
        hopNumber: 1,
        status: TracerouteHopStatus.success,
        probes: const [null, Duration(milliseconds: 18), null],
        message: 'TTL exceeded',
      );

      expect(hop.averageRtt, const Duration(milliseconds: 18));
    });

    test('returns null average when all probes time out', () {
      final hop = TracerouteHop(
        hopNumber: 1,
        status: TracerouteHopStatus.timeout,
        message: 'Request timed out.',
      );

      expect(hop.averageRtt, isNull);
      expect(hop.displayAddress, 'Request Timed Out');
    });
  });

  group('TracerouteSummary', () {
    test(
      'uses final destination average as total latency instead of summing hops',
      () {
        final hops = [
          TracerouteHop(
            hopNumber: 1,
            status: TracerouteHopStatus.success,
            address: '192.168.1.1',
            probes: const [
              Duration(milliseconds: 2),
              Duration(milliseconds: 4),
              Duration(milliseconds: 6),
            ],
            message: 'TTL exceeded',
          ),
          TracerouteHop(
            hopNumber: 2,
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
        ];

        final summary = TracerouteSummary.fromHops(hops);

        expect(summary.destinationReached, '93.184.216.34');
        expect(summary.totalHops, 2);
        expect(summary.totalEndToEndLatency, const Duration(milliseconds: 27));
      },
    );
  });

  group('mockTracerouteStream', () {
    test('streams deterministic mixed traceroute rows', () async {
      final hops = await mockTracerouteStream().toList();

      expect(hops, hasLength(4));
      expect(hops[0].status, TracerouteHopStatus.success);
      expect(hops[1].probes, contains(null));
      expect(hops[2].status, TracerouteHopStatus.timeout);
      expect(hops[3].isDestination, isTrue);
    });
  });
}
