import 'package:dart_ping/dart_ping.dart';

import 'traceroute_models.dart';

typedef TracerouteProbeRunner =
    Future<TracerouteProbeResult> Function({
      required String host,
      required int ttl,
      required int timeout,
    });

class TracerouteService {
  TracerouteService({TracerouteProbeRunner? probeRunner})
    : _probeRunner = probeRunner;

  static const int _probeCount = 3;

  final TracerouteProbeRunner? _probeRunner;
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

        final result = await _runConfiguredProbe(
          host: host,
          ttl: ttl,
          timeout: timeout,
        );
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

  Future<TracerouteProbeResult> _runConfiguredProbe({
    required String host,
    required int ttl,
    required int timeout,
  }) async {
    try {
      final probeRunner = _probeRunner;
      if (probeRunner != null) {
        return await probeRunner(host: host, ttl: ttl, timeout: timeout);
      }
      return await _runProbe(host: host, ttl: ttl, timeout: timeout);
    } catch (_) {
      return const TracerouteProbeResult(
        message: 'Trace failed. Please check the host.',
        shouldStopTrace: true,
      );
    }
  }

  Future<TracerouteProbeResult> _runProbe({
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
            return TracerouteProbeResult(
              address: event.ip ?? host,
              latency: event.time ?? stopwatch.elapsed,
              message: 'Reached destination',
              isDestination: true,
            );
          case PingError():
            return _probeResultFromError(event, stopwatch.elapsed);
          case PingSummary():
            return const TracerouteProbeResult(message: 'Request timed out.');
        }
      }
    } catch (_) {
      return const TracerouteProbeResult(
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

    return const TracerouteProbeResult(message: 'Request timed out.');
  }

  TracerouteProbeResult _probeResultFromError(
    PingError error,
    Duration elapsed,
  ) {
    return switch (error.error) {
      ErrorType.timeToLiveExceeded => TracerouteProbeResult(
        address: error.ip,
        latency: error.ip == null ? null : elapsed,
        message: 'TTL exceeded',
      ),
      ErrorType.requestTimedOut => const TracerouteProbeResult(
        message: 'Request timed out.',
      ),
      ErrorType.noReply => const TracerouteProbeResult(message: 'No reply.'),
      ErrorType.noRoute => const TracerouteProbeResult(
        message: 'No route to host.',
        shouldStopTrace: true,
      ),
      ErrorType.unknownHost => const TracerouteProbeResult(
        message: 'Unknown host.',
        shouldStopTrace: true,
      ),
      ErrorType.unknown => TracerouteProbeResult(
        message: error.message ?? 'Unknown trace error.',
        shouldStopTrace: true,
      ),
    };
  }
}

class TracerouteProbeResult {
  const TracerouteProbeResult({
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
