import 'package:dart_ping/dart_ping.dart';

/// Wraps the dart_ping package to stream ICMP results back as formatted lines.
///
/// Consumers call [ping] and supply an [onResult] callback that receives each
/// formatted line as it arrives. Call [cancel] to abort an active stream.
class PingService {
  Ping? _activePing;

  /// Start pinging [host] for [count] packets.
  ///
  /// Each result (reply, timeout, summary) is converted to a human-readable
  /// line and passed to [onResult]. Throws on unresolvable host.
  Future<void> ping({
    required String host,
    required int count,
    required void Function(String line) onResult,
  }) async {
    _activePing = Ping(host, count: count);

    await for (final event in _activePing!.stream) {
      switch (event) {
        case PingResponse():
          final ip = event.ip ?? host;
          final ms = event.time?.inMilliseconds ?? '?';
          final ttl = event.ttl ?? '?';
          onResult('Reply from $ip: ttl=$ttl time=${ms}ms');

        case PingError():
          onResult('Error: ${_describeError(event.error)}');

        case PingSummary():
          final loss =
              ((event.transmitted - event.received) / event.transmitted * 100)
                  .toStringAsFixed(0);
          onResult(
            '--- $host ping statistics ---\n'
            '${event.transmitted} packets transmitted, '
            '${event.received} received, '
            '$loss% packet loss',
          );
      }
    }
  }

  /// Abort the active ping stream, if any.
  void cancel() {
    _activePing?.stop();
    _activePing = null;
  }

  String _describeError(ErrorType error) {
    switch (error) {
      case ErrorType.requestTimedOut:
        return 'Request timed out.';
      case ErrorType.unknownHost:
        return 'Unknown host.';
      case ErrorType.timeToLiveExceeded:
        return 'Time to live exceeded.';
      case ErrorType.noReply:
        return 'No reply.';
      case ErrorType.noRoute:
        return 'No route to host.';
      case ErrorType.unknown:
        return 'Unknown error.';
    }
  }
}
