enum TracerouteHopStatus { pending, success, timeout }

class TracerouteHop {
  TracerouteHop({
    required this.hopNumber,
    required this.status,
    required this.message,
    List<Duration?> probes = const <Duration?>[null, null, null],
    this.address,
    this.isDestination = false,
  }) : assert(probes.length == 3, 'Traceroute hops require exactly 3 probes.'),
       probes = List<Duration?>.unmodifiable(probes);

  final int hopNumber;
  final TracerouteHopStatus status;
  final String? address;
  final List<Duration?> probes;
  final String message;
  final bool isDestination;

  Duration? get probe1 => probes[0];
  Duration? get probe2 => probes[1];
  Duration? get probe3 => probes[2];

  Duration? get averageRtt {
    final successfulProbes = probes.whereType<Duration>().toList();
    if (successfulProbes.isEmpty) return null;

    final totalMicros = successfulProbes.fold<int>(
      0,
      (sum, probe) => sum + probe.inMicroseconds,
    );
    return Duration(microseconds: totalMicros ~/ successfulProbes.length);
  }

  String get displayAddress {
    return address ??
        (status == TracerouteHopStatus.timeout ? 'Request Timeout' : '');
  }
}

class TracerouteSummary {
  const TracerouteSummary({
    required this.destinationReached,
    required this.totalHops,
    required this.totalEndToEndLatency,
  });

  final String? destinationReached;
  final int totalHops;
  final Duration? totalEndToEndLatency;

  factory TracerouteSummary.fromHops(List<TracerouteHop> hops) {
    if (hops.isEmpty) {
      return const TracerouteSummary(
        destinationReached: null,
        totalHops: 0,
        totalEndToEndLatency: null,
      );
    }

    TracerouteHop? destinationHop;
    for (final hop in hops.reversed) {
      if (hop.isDestination) {
        destinationHop = hop;
        break;
      }
    }

    return TracerouteSummary(
      destinationReached: destinationHop?.address,
      totalHops: hops.last.hopNumber,
      totalEndToEndLatency: destinationHop?.averageRtt,
    );
  }
}
