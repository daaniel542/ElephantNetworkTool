class TracerouteHop {
  const TracerouteHop({
    required this.hopNumber,
    this.address,
    this.latency,
    required this.message,
    this.isDestination = false,
  });

  final int hopNumber;
  final String? address;
  final Duration? latency;
  final String message;
  final bool isDestination;
}

class TracerouteService {
  Stream<TracerouteHop> trace({
    required String host,
    int maxHops = 30,
    int timeout = 2,
  }) async* {
    yield const TracerouteHop(
      hopNumber: 1,
      message: 'Traceroute is not supported on this platform.',
    );
  }

  Future<void> stopTrace() async {}
}
