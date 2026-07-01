import 'ping_event.dart';

class PingService {
  Stream<PingEvent> ping({required String host, required int count}) async* {
    yield const PingError(
      ErrorType.unknown,
      message: 'Ping is not supported on this platform.',
    );
  }

  void stopPing() {}

  void cancel() => stopPing();
}
