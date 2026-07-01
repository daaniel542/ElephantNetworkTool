class PingService {
  Future<void> ping({
    required String host,
    required int count,
    required void Function(String line) onResult,
  }) async {
    throw UnsupportedError('Ping is not supported on this platform.');
  }

  void cancel() {}
}
