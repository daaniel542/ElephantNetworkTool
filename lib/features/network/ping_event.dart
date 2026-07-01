sealed class PingEvent {
  const PingEvent();
}

class PingResponse extends PingEvent {
  const PingResponse({this.seq, this.ip, this.ttl, this.time});

  final int? seq;
  final String? ip;
  final int? ttl;
  final Duration? time;
}

class PingError extends PingEvent {
  const PingError({this.seq, this.ip, this.message, this.error});

  final int? seq;
  final String? ip;
  final String? message;
  final Object? error;
}

class PingSummary extends PingEvent {
  const PingSummary({
    required this.transmitted,
    required this.received,
    this.stats,
  });

  final int transmitted;
  final int received;
  final PingStats? stats;

  double get packetLoss {
    if (transmitted == 0) return 0;
    return ((transmitted - received) / transmitted) * 100;
  }
}

class PingStats {
  const PingStats({this.min, this.avg, this.max});

  final Duration? min;
  final Duration? avg;
  final Duration? max;
}
