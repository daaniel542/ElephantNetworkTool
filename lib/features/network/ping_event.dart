sealed class PingEvent {
  const PingEvent();
}

class PingResponse extends PingEvent {
  const PingResponse({this.seq, this.ttl, this.time, this.ip, this.stats});

  final int? seq;
  final int? ttl;
  final Duration? time;
  final String? ip;
  final PingStats? stats;
}

class PingError extends PingEvent {
  const PingError(this.error, {this.message, this.seq, this.ip, this.stats});

  final ErrorType error;
  final String? message;
  final int? seq;
  final String? ip;
  final PingStats? stats;
}

class PingSummary extends PingEvent {
  const PingSummary({
    required this.transmitted,
    required this.received,
    this.time,
    this.stats,
  });

  final int transmitted;
  final int received;
  final Duration? time;
  final PingStats? stats;

  double get packetLoss =>
      transmitted == 0 ? 100.0 : (transmitted - received) * 100 / transmitted;
}

class PingStats {
  const PingStats({this.min, this.avg, this.max});

  final Duration? min;
  final Duration? avg;
  final Duration? max;
}

enum ErrorType {
  timeToLiveExceeded,
  requestTimedOut,
  unknownHost,
  unknown,
  noReply,
  noRoute,
}
