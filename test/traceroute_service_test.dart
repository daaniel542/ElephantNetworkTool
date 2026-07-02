import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:net_utility_toolkit/features/network/traceroute_models.dart';
import 'package:net_utility_toolkit/features/network/traceroute_service_io.dart';

void main() {
  group('TracerouteService native probe orchestration', () {
    test('yields successful hops until the destination is reached', () async {
      final service = TracerouteService(
        probeRunner: ({required host, required ttl, required timeout}) async {
          if (ttl == 3) {
            return const TracerouteProbeResult(
              address: '93.184.216.34',
              latency: Duration(milliseconds: 24),
              message: 'Reached destination',
              isDestination: true,
            );
          }
          return TracerouteProbeResult(
            address: '192.0.2.$ttl',
            latency: Duration(milliseconds: 5),
            message: 'TTL exceeded',
          );
        },
      );

      final hops = await service.trace(host: 'example.com').toList();

      expect(hops, hasLength(3));
      expect(hops.last.isDestination, isTrue);
      expect(hops.last.address, '93.184.216.34');
      expect(hops.last.probes, [const Duration(milliseconds: 24), null, null]);
    });

    test(
      'continues through all 30 hops when destination is never reached',
      () async {
        final ttlCalls = <int>[];
        final service = TracerouteService(
          probeRunner: ({required host, required ttl, required timeout}) async {
            ttlCalls.add(ttl);
            return TracerouteProbeResult(
              address: '192.0.2.$ttl',
              latency: Duration(milliseconds: ttl),
              message: 'TTL exceeded',
            );
          },
        );

        final hops = await service.trace(host: 'deep.example').toList();

        expect(hops, hasLength(30));
        expect(hops.last.hopNumber, 30);
        expect(hops.last.isDestination, isFalse);
        expect(ttlCalls, hasLength(90));
      },
    );

    test('marks all-timeout hops without stopping the trace', () async {
      final service = TracerouteService(
        probeRunner: ({required host, required ttl, required timeout}) async {
          return const TracerouteProbeResult(message: 'Request timed out.');
        },
      );

      final hops = await service
          .trace(host: 'blackhole.example', maxHops: 3)
          .toList();

      expect(hops, hasLength(3));
      expect(
        hops.every((hop) => hop.status == TracerouteHopStatus.timeout),
        isTrue,
      );
      expect(hops.every((hop) => hop.averageRtt == null), isTrue);
    });

    test(
      'averages partial probe successes and keeps timeout probes as nulls',
      () async {
        var probeIndex = 0;
        final service = TracerouteService(
          probeRunner: ({required host, required ttl, required timeout}) async {
            probeIndex += 1;
            if (probeIndex == 2) {
              return const TracerouteProbeResult(
                address: '192.0.2.1',
                latency: Duration(milliseconds: 18),
                message: 'TTL exceeded',
              );
            }
            return const TracerouteProbeResult(message: 'Request timed out.');
          },
        );

        final hops = await service
            .trace(host: 'partial.example', maxHops: 1)
            .toList();

        expect(hops.single.status, TracerouteHopStatus.success);
        expect(hops.single.probes, [
          null,
          const Duration(milliseconds: 18),
          null,
        ]);
        expect(hops.single.averageRtt, const Duration(milliseconds: 18));
      },
    );

    test('handles one successful probe per hop', () async {
      final probeCountsByTtl = <int, int>{};
      final service = TracerouteService(
        probeRunner: ({required host, required ttl, required timeout}) async {
          final probe = (probeCountsByTtl[ttl] ?? 0) + 1;
          probeCountsByTtl[ttl] = probe;
          if (probe == 3) {
            return TracerouteProbeResult(
              address: '198.51.100.$ttl',
              latency: Duration(milliseconds: ttl * 10),
              message: 'TTL exceeded',
            );
          }
          return const TracerouteProbeResult(message: 'Request timed out.');
        },
      );

      final hops = await service
          .trace(host: 'sparse.example', maxHops: 2)
          .toList();

      expect(hops, hasLength(2));
      expect(hops[0].probes.whereType<Duration>(), [
        const Duration(milliseconds: 10),
      ]);
      expect(hops[1].probes.whereType<Duration>(), [
        const Duration(milliseconds: 20),
      ]);
    });

    test('stops early for no route errors', () async {
      final service = TracerouteService(
        probeRunner: ({required host, required ttl, required timeout}) async {
          return const TracerouteProbeResult(
            message: 'No route to host.',
            shouldStopTrace: true,
          );
        },
      );

      final hops = await service.trace(host: 'noroute.example').toList();

      expect(hops, hasLength(1));
      expect(hops.single.message, 'No route to host.');
    });

    test('stops early for unknown host errors', () async {
      final service = TracerouteService(
        probeRunner: ({required host, required ttl, required timeout}) async {
          return const TracerouteProbeResult(
            message: 'Unknown host.',
            shouldStopTrace: true,
          );
        },
      );

      final hops = await service.trace(host: 'missing.invalid').toList();

      expect(hops, hasLength(1));
      expect(hops.single.message, 'Unknown host.');
    });

    test('converts probe exceptions into a clean terminal hop', () async {
      final service = TracerouteService(
        probeRunner: ({required host, required ttl, required timeout}) async {
          throw StateError('native stream failed');
        },
      );

      final hops = await service.trace(host: 'explode.example').toList();

      expect(hops, hasLength(1));
      expect(hops.single.message, 'Trace failed. Please check the host.');
    });

    test(
      'does not yield a hop after stopTrace is called during an active probe',
      () async {
        final probeStarted = Completer<void>();
        final releaseProbe = Completer<TracerouteProbeResult>();
        final service = TracerouteService(
          probeRunner: ({required host, required ttl, required timeout}) async {
            if (!probeStarted.isCompleted) {
              probeStarted.complete();
            }
            return releaseProbe.future;
          },
        );
        final hops = <TracerouteHop>[];
        final done = Completer<void>();

        final subscription = service
            .trace(host: 'slow.example')
            .listen(hops.add, onDone: done.complete);

        await probeStarted.future;
        await service.stopTrace();
        releaseProbe.complete(
          const TracerouteProbeResult(
            address: '192.0.2.10',
            latency: Duration(milliseconds: 100),
            message: 'TTL exceeded',
          ),
        );
        await done.future.timeout(const Duration(seconds: 1));
        await subscription.cancel();

        expect(hops, isEmpty);
      },
    );
  });
}
