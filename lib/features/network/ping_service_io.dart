import 'package:dart_ping/dart_ping.dart' as dart_ping;

import 'ping_event.dart';

/// Thin wrapper around dart_ping.
///
/// The service owns the active native ping process and exposes app-owned event
/// types so web builds never import dart_ping or dart:ffi.
class PingService {
  dart_ping.Ping? _activePing;

  Stream<PingEvent> ping({required String host, required int count}) async* {
    stopPing();
    _activePing = dart_ping.Ping(host, count: count);

    await for (final event in _activePing!.stream) {
      yield switch (event) {
        dart_ping.PingResponse() => PingResponse(
          seq: event.seq,
          ttl: event.ttl,
          time: event.time,
          ip: event.ip,
          stats: _mapStats(event.stats),
        ),
        dart_ping.PingError() => PingError(
          _mapErrorType(event.error),
          message: event.message,
          seq: event.seq,
          ip: event.ip,
          stats: _mapStats(event.stats),
        ),
        dart_ping.PingSummary() => PingSummary(
          transmitted: event.transmitted,
          received: event.received,
          time: event.time,
          stats: _mapStats(event.stats),
        ),
      };
    }
  }

  void stopPing() {
    _activePing?.stop();
    _activePing = null;
  }

  void cancel() => stopPing();

  PingStats? _mapStats(dart_ping.RoundTripStats? stats) {
    if (stats == null) return null;
    return PingStats(min: stats.min, avg: stats.avg, max: stats.max);
  }

  ErrorType _mapErrorType(dart_ping.ErrorType error) {
    return switch (error) {
      dart_ping.ErrorType.timeToLiveExceeded => ErrorType.timeToLiveExceeded,
      dart_ping.ErrorType.requestTimedOut => ErrorType.requestTimedOut,
      dart_ping.ErrorType.unknownHost => ErrorType.unknownHost,
      dart_ping.ErrorType.noReply => ErrorType.noReply,
      dart_ping.ErrorType.noRoute => ErrorType.noRoute,
      dart_ping.ErrorType.unknown => ErrorType.unknown,
    };
  }
}
