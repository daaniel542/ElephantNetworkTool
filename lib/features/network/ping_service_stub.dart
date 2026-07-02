import 'ping_event.dart';

class PingService {
  Stream<PingEvent> ping({
    required String host,
    required int count,
    required Duration timeout,
    required int ttl,
  }) async* {
    throw UnsupportedError('Ping is not supported on this platform.');
  }

  void stopPing() {}

  void cancel() => stopPing();
}
