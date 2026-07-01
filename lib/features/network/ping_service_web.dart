class PingService {
  Future<void> ping({
    required String host,
    required int count,
    required void Function(String line) onResult,
  }) async {
    onResult(
      'Ping is not available in browser-hosted builds. '
      'Browsers cannot send ICMP packets; deploy a backend probe service for hosted ping.',
    );
  }

  void cancel() {}
}
