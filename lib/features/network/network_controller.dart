import 'package:flutter/foundation.dart';
import 'ping_service.dart';
import 'dns_service.dart';

/// Supported DNS record types per PRD section 10.1.
enum DnsRecordType { a, aaaa, cname, mx, txt, ns }

/// Controller for the Network Tools screen.
///
/// Manages ping state, DNS lookup state, and all user-facing input fields.
/// Both ping streaming and DNS fetching are coordinated through this class.
class NetworkController extends ChangeNotifier {
  NetworkController({
    required PingService pingService,
    required DnsService dnsService,
  })  : _pingService = pingService,
        _dnsService = dnsService;

  final PingService _pingService;
  final DnsService _dnsService;

  // -------------------------------------------------------------------------
  // Ping state
  // -------------------------------------------------------------------------

  /// Host or IP address entered by the user.
  String pingHost = '';

  /// Number of ICMP packets to send. Default 4, max 20.
  int pingCount = 4;

  /// Whether a ping stream is currently active.
  bool isPinging = false;

  /// Accumulated terminal output lines from the active ping session.
  final List<String> pingOutput = [];

  /// Optional error message to display in the ping panel.
  String? pingError;

  // -------------------------------------------------------------------------
  // DNS state
  // -------------------------------------------------------------------------

  /// Domain entered by the user.
  String dnsDomain = '';

  /// Currently selected record type.
  DnsRecordType dnsRecordType = DnsRecordType.a;

  /// Whether a DNS lookup is currently in flight.
  bool isDnsLoading = false;

  /// Results returned by the last successful DNS lookup.
  List<DnsRecord> dnsResults = [];

  /// Optional error message to display in the DNS panel.
  String? dnsError;

  // -------------------------------------------------------------------------
  // Ping actions
  // -------------------------------------------------------------------------

  /// Start streaming ping packets to [pingHost].
  Future<void> startPing() async {
    if (isPinging || pingHost.trim().isEmpty) return;

    pingOutput.clear();
    pingError = null;
    isPinging = true;
    notifyListeners();

    try {
      await _pingService.ping(
        host: pingHost.trim(),
        count: pingCount,
        onResult: (line) {
          pingOutput.add(line);
          notifyListeners();
        },
      );
    } catch (e) {
      pingError = 'Ping failed. Please check the host.';
    } finally {
      isPinging = false;
      notifyListeners();
    }
  }

  /// Abort an active ping stream.
  void stopPing() {
    _pingService.cancel();
    isPinging = false;
    pingOutput.add('--- Ping cancelled by user ---');
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // DNS actions
  // -------------------------------------------------------------------------

  /// Execute a DNS lookup for [dnsDomain] using [dnsRecordType].
  Future<void> lookupDns() async {
    if (isDnsLoading || dnsDomain.trim().isEmpty) return;

    dnsResults = [];
    dnsError = null;
    isDnsLoading = true;
    notifyListeners();

    try {
      dnsResults = await _dnsService.lookup(
        domain: dnsDomain.trim(),
        type: dnsRecordType,
      );
    } catch (e) {
      dnsError = e.toString();
    } finally {
      isDnsLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pingService.cancel();
    super.dispose();
  }
}
