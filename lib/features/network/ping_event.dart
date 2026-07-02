sealed class PingEvent {
  const PingEvent();
}

abstract final class PingDefaults {
  static const count = 5;
  static const minCount = 1;
  static const maxCount = 999;
  static const timeoutMs = 2000;
  static const minTimeoutMs = 1000;
  static const maxTimeoutMs = 4000;
  static const ttl = 255;
  static const minTtl = 1;
  static const maxTtl = 255;
}

class PingResponse extends PingEvent {
  const PingResponse({this.seq, this.ip, this.ttl, this.time});

  final int? seq;
  final String? ip;
  final int? ttl;
  final Duration? time;
}

class PingError extends PingEvent {
  const PingError({
    this.seq,
    this.ip,
    this.message,
    this.error,
    this.isUnsupported = false,
  });

  final int? seq;
  final String? ip;
  final String? message;
  final Object? error;
  final bool isUnsupported;
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
    if (transmitted <= 0) return 0;
    final lost = (transmitted - received).clamp(0, transmitted).toInt();
    return (lost / transmitted) * 100;
  }
}

class PingStats {
  const PingStats({
    this.min,
    this.avg,
    this.max,
    this.stddev,
    this.jitter,
    this.sampleCount = 0,
  });

  final Duration? min;
  final Duration? avg;
  final Duration? max;
  final Duration? stddev;
  final Duration? jitter;
  final int sampleCount;
}
