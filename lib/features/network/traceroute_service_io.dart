import 'package:dart_ping/dart_ping.dart';

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
  Ping? _activePing;
  bool _isStopped = false;

  Stream<TracerouteHop> trace({
    required String host,
    int maxHops = 30,
    int timeout = 2,
  }) async* {
    _isStopped = false;

    for (var ttl = 1; ttl <= maxHops; ttl += 1) {
      if (_isStopped) break;

      TracerouteHop? hop;
      _activePing = Ping(host, count: 1, ttl: ttl, timeout: timeout);

      try {
        await for (final event in _activePing!.stream) {
          if (_isStopped) break;

          switch (event) {
            case PingResponse():
              hop = TracerouteHop(
                hopNumber: ttl,
                address: event.ip ?? host,
                latency: event.time,
                message: 'Reached destination',
                isDestination: true,
              );
            case PingError():
              hop = _hopFromError(ttl, event);
            case PingSummary():
              hop ??= TracerouteHop(
                hopNumber: ttl,
                message: 'Request timed out.',
              );
          }

          break;
        }
      } catch (_) {
        hop = TracerouteHop(
          hopNumber: ttl,
          message: 'Trace failed. Please check the host.',
        );
      } finally {
        final activePing = _activePing;
        _activePing = null;
        if (activePing != null) {
          await activePing.stop().timeout(
            const Duration(seconds: 1),
            onTimeout: () => false,
          );
        }
      }

      if (_isStopped || hop == null) break;

      yield hop;

      if (hop.isDestination) break;
    }
  }

  Future<void> stopTrace() async {
    _isStopped = true;
    final activePing = _activePing;
    _activePing = null;

    if (activePing != null) {
      await activePing.stop().timeout(
        const Duration(seconds: 1),
        onTimeout: () => false,
      );
    }
  }

  TracerouteHop _hopFromError(int ttl, PingError error) {
    return switch (error.error) {
      ErrorType.timeToLiveExceeded => TracerouteHop(
        hopNumber: ttl,
        address: error.ip,
        message: 'TTL exceeded',
      ),
      ErrorType.requestTimedOut => TracerouteHop(
        hopNumber: ttl,
        message: 'Request timed out.',
      ),
      ErrorType.noReply => TracerouteHop(hopNumber: ttl, message: 'No reply.'),
      ErrorType.noRoute => TracerouteHop(
        hopNumber: ttl,
        message: 'No route to host.',
      ),
      ErrorType.unknownHost => TracerouteHop(
        hopNumber: ttl,
        message: 'Unknown host.',
      ),
      ErrorType.unknown => TracerouteHop(
        hopNumber: ttl,
        message: error.message ?? 'Unknown trace error.',
      ),
    };
  }
}
