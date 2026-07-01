import 'ping_event.dart';

class PingService {
  Stream<PingEvent> ping({required String host, required int count}) async* {
    yield const PingError(
      ErrorType.unknown,
      message:
          'Ping is not available in browser-hosted builds. Browsers cannot send ICMP packets; deploy a backend probe service for hosted ping.',
    );
  }

  void stopPing() {}

  void cancel() => stopPing();
}
