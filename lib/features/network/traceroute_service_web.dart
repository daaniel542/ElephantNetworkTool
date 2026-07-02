import 'traceroute_models.dart';

class TracerouteService {
  Stream<TracerouteHop> trace({
    required String host,
    int maxHops = 30,
    int timeout = 2,
  }) async* {
    yield TracerouteHop(
      hopNumber: 1,
      status: TracerouteHopStatus.unsupported,
      message: 'Traceroute is not supported on web.',
    );
  }

  Future<void> stopTrace() async {}
}
