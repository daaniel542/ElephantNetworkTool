import 'package:dart_ping/dart_ping.dart';

import 'traceroute_models.dart';

class TracerouteService {
  static const int _probeCount = 3;

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

      final probes = <Duration?>[];
      String? address;
      var message = 'Request timed out.';
      var isDestination = false;
      var shouldStopTrace = false;

      for (var probe = 0; probe < _probeCount; probe += 1) {
        if (_isStopped) break;

        final result = await _runProbe(host: host, ttl: ttl, timeout: timeout);
        if (_isStopped) break;

        probes.add(result.latency);
        if (result.address != null) {
          address = result.address;
        }
        message = result.message;
        isDestination = isDestination || result.isDestination;
        shouldStopTrace = shouldStopTrace || result.shouldStopTrace;

        if (isDestination || shouldStopTrace) {
          break;
        }
      }

      if (_isStopped) break;

      while (probes.length < _probeCount) {
        probes.add(null);
      }

      final status = probes.any((probe) => probe != null) || address != null
          ? TracerouteHopStatus.success
          : TracerouteHopStatus.timeout;
      final hop = TracerouteHop(
        hopNumber: ttl,
        status: status,
        address: address,
        probes: probes,
        message: message,
        isDestination: isDestination,
      );

      yield hop;

      if (hop.isDestination || shouldStopTrace) break;
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

  Future<_TracerouteProbeResult> _runProbe({
    required String host,
    required int ttl,
    required int timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    _activePing = Ping(host, count: 1, ttl: ttl, timeout: timeout);

    try {
      await for (final event in _activePing!.stream) {
        if (_isStopped) break;

        switch (event) {
          case PingResponse():
            return _TracerouteProbeResult(
              address: event.ip ?? host,
              latency: event.time ?? stopwatch.elapsed,
              message: 'Reached destination',
              isDestination: true,
            );
          case PingError():
            return _probeResultFromError(event, stopwatch.elapsed);
          case PingSummary():
            return const _TracerouteProbeResult(message: 'Request timed out.');
        }
      }
    } catch (_) {
      return const _TracerouteProbeResult(
        message: 'Trace failed. Please check the host.',
        shouldStopTrace: true,
      );
    } finally {
      stopwatch.stop();
      final activePing = _activePing;
      _activePing = null;
      if (activePing != null) {
        await activePing.stop().timeout(
          const Duration(seconds: 1),
          onTimeout: () => false,
        );
      }
    }

    return const _TracerouteProbeResult(message: 'Request timed out.');
  }

  _TracerouteProbeResult _probeResultFromError(
    PingError error,
    Duration elapsed,
  ) {
    return switch (error.error) {
      ErrorType.timeToLiveExceeded => _TracerouteProbeResult(
        address: error.ip,
        latency: error.ip == null ? null : elapsed,
        message: 'TTL exceeded',
      ),
      ErrorType.requestTimedOut => const _TracerouteProbeResult(
        message: 'Request timed out.',
      ),
      ErrorType.noReply => const _TracerouteProbeResult(message: 'No reply.'),
      ErrorType.noRoute => const _TracerouteProbeResult(
        message: 'No route to host.',
        shouldStopTrace: true,
      ),
      ErrorType.unknownHost => const _TracerouteProbeResult(
        message: 'Unknown host.',
        shouldStopTrace: true,
      ),
      ErrorType.unknown => _TracerouteProbeResult(
        message: error.message ?? 'Unknown trace error.',
        shouldStopTrace: true,
      ),
    };
  }
}

class _TracerouteProbeResult {
  const _TracerouteProbeResult({
    required this.message,
    this.address,
    this.latency,
    this.isDestination = false,
    this.shouldStopTrace = false,
  });

  final String? address;
  final Duration? latency;
  final String message;
  final bool isDestination;
  final bool shouldStopTrace;
}
