import 'ping_event.dart';

class PingService {
  Stream<PingEvent> ping({required String host, required int count}) async* {
    yield PingError(
      message:
          'Ping requires raw ICMP access, which browser builds cannot use. Run the desktop app for ping.',
    );
    yield PingSummary(transmitted: count, received: 0);
  }

  void stopPing() {}

  void cancel() => stopPing();
}
