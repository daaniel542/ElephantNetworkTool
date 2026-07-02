import 'traceroute_models.dart';

Stream<TracerouteHop> mockTracerouteStream({
  Duration delay = Duration.zero,
}) async* {
  final hops = [
    TracerouteHop(
      hopNumber: 1,
      status: TracerouteHopStatus.success,
      address: '192.168.1.1',
      probes: const [
        Duration(milliseconds: 2),
        Duration(milliseconds: 3),
        Duration(milliseconds: 2),
      ],
      message: 'TTL exceeded',
    ),
    TracerouteHop(
      hopNumber: 2,
      status: TracerouteHopStatus.success,
      address: '10.12.0.1',
      probes: const [
        Duration(milliseconds: 10),
        null,
        Duration(milliseconds: 14),
      ],
      message: 'TTL exceeded',
    ),
    TracerouteHop(
      hopNumber: 3,
      status: TracerouteHopStatus.timeout,
      message: 'Request timed out.',
    ),
    TracerouteHop(
      hopNumber: 4,
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

  for (final hop in hops) {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    yield hop;
  }
}
