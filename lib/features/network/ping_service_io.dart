import 'package:dart_ping/dart_ping.dart' as dart_ping;

import 'ping_event.dart';

class PingService {
  dart_ping.Ping? _activePing;

  Stream<PingEvent> ping({
    required String host,
    required int count,
    required Duration timeout,
    required int ttl,
  }) async* {
    _activePing = dart_ping.Ping(
      host,
      count: count,
      timeout: _timeoutSeconds(timeout),
      ttl: ttl,
    );

    await for (final event in _activePing!.stream) {
      switch (event) {
        case dart_ping.PingResponse():
          yield PingResponse(
            seq: event.seq,
            ip: event.ip,
            ttl: event.ttl,
            time: event.time,
          );

        case dart_ping.PingError():
          yield PingError(
            seq: event.seq,
            ip: event.ip,
            message: _describeError(event.error),
            error: event.error,
          );

        case dart_ping.PingSummary():
          yield PingSummary(
            transmitted: event.transmitted,
            received: event.received,
            stats: _mapStats(event.stats),
          );
      }
    }
  }

  void stopPing() {
    _activePing?.stop();
    _activePing = null;
  }

  void cancel() => stopPing();

  int _timeoutSeconds(Duration timeout) {
    final milliseconds = timeout.inMilliseconds;
    if (milliseconds <= 0) return 1;
    return (milliseconds / Duration.millisecondsPerSecond).ceil();
  }

  PingStats? _mapStats(dart_ping.RoundTripStats? stats) {
    if (stats == null) return null;
    return PingStats(
      min: stats.min,
      avg: stats.avg,
      max: stats.max,
      stddev: stats.stddev,
      jitter: stats.jitter,
      sampleCount: stats.sampleCount,
    );
  }

  String _describeError(dart_ping.ErrorType error) {
    return switch (error) {
      dart_ping.ErrorType.requestTimedOut => 'Request timed out.',
      dart_ping.ErrorType.unknownHost => 'Unknown host.',
      dart_ping.ErrorType.timeToLiveExceeded => 'Time to live exceeded.',
      dart_ping.ErrorType.noReply => 'No reply.',
      dart_ping.ErrorType.noRoute => 'No route to host.',
      dart_ping.ErrorType.unknown => 'Unknown error.',
    };
  }
}
