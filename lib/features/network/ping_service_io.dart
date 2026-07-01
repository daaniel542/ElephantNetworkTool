import 'package:dart_ping/dart_ping.dart' as dart_ping;

import 'ping_event.dart';

class PingService {
  dart_ping.Ping? _activePing;

  Stream<PingEvent> ping({required String host, required int count}) async* {
    _activePing = dart_ping.Ping(host, count: count);

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
            stats: PingStats(avg: event.time),
          );
      }
    }
  }

  void stopPing() {
    _activePing?.stop();
    _activePing = null;
  }

  void cancel() => stopPing();

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
