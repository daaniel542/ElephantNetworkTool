import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:net_utility_toolkit/app/app.dart';
import 'package:net_utility_toolkit/features/network/dns_service.dart';
import 'package:net_utility_toolkit/features/network/network_controller.dart';
import 'package:net_utility_toolkit/features/network/network_screen.dart';
import 'package:net_utility_toolkit/features/network/ping_event.dart';
import 'package:net_utility_toolkit/features/network/ping_service.dart';
import 'package:net_utility_toolkit/features/network/traceroute_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App smoke test renders without crashing', (tester) async {
    await tester.pumpWidget(const NetUtilityApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('desktop shell renders sidebar navigation and footer', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(1200, 800));

    await tester.pumpWidget(const NetUtilityApp());
    await tester.pumpAndSettle();

    expect(find.text('ENT'), findsOneWidget);
    expect(find.text('Version 1'), findsOneWidget);
    expect(find.text('Password Generator'), findsOneWidget);
  });

  testWidgets('mobile shell renders compact bottom navigation', (tester) async {
    _setSurfaceSize(tester, const Size(390, 800));

    await tester.pumpWidget(const NetUtilityApp());
    await tester.pumpAndSettle();

    expect(find.text('Password'), findsWidgets);
    expect(find.text('Encoding'), findsWidgets);
  });

  testWidgets(
    'network mode tabs switch between Ping, DNS, and Trace controls',
    (tester) async {
      final controller = _networkController();
      addTearDown(controller.dispose);

      await _pumpNetworkScreen(tester, controller);

      expect(find.text('Start Ping'), findsOneWidget);

      await tester.tap(find.text('DNS Lookup'));
      await tester.pumpAndSettle();
      expect(find.text('Lookup DNS'), findsOneWidget);

      await tester.tap(find.text('Trace'));
      await tester.pumpAndSettle();
      expect(find.text('Start Trace'), findsOneWidget);
    },
  );

  testWidgets('ping disables start and enables stop while running', (
    tester,
  ) async {
    final release = Completer<void>();
    final pingService = _BlockingPingService(release);
    final controller = _networkController(pingService: pingService);
    addTearDown(controller.dispose);

    await _pumpNetworkScreen(tester, controller);
    await tester.enterText(find.byType(TextField).first, 'slow.example');
    await tester.tap(find.text('Start Ping'));
    await tester.pump();
    await pingService.started.future;
    await tester.pump();

    final stopButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Stop'),
    );
    expect(stopButton.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Stop'));
    release.complete();
    await tester.pumpAndSettle();

    expect(pingService.stopCalled, isTrue);
    final disabledStop = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Stop'),
    );
    expect(disabledStop.onPressed, isNull);
  });

  testWidgets('copy output button enables after a completed ping', (
    tester,
  ) async {
    final controller = _networkController(
      pingService: _ImmediatePingService([
        const PingResponse(
          seq: 0,
          ip: '192.0.2.1',
          ttl: 64,
          time: Duration(milliseconds: 12),
        ),
        const PingSummary(transmitted: 1, received: 1),
      ]),
    );
    addTearDown(controller.dispose);

    await _pumpNetworkScreen(tester, controller);
    var copyButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Copy Output'),
    );
    expect(copyButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'example.com');
    await tester.tap(find.text('Start Ping'));
    await tester.pumpAndSettle();

    copyButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Copy Output'),
    );
    expect(copyButton.onPressed, isNotNull);
  });

  testWidgets('ping table renders partial failures without hiding successes', (
    tester,
  ) async {
    final controller = _networkController(
      pingService: _ImmediatePingService([
        const PingResponse(
          seq: 0,
          ip: '192.0.2.1',
          ttl: 64,
          time: Duration(milliseconds: 12),
        ),
        const PingError(seq: 1, message: 'Request timed out.'),
        const PingSummary(transmitted: 2, received: 1),
      ]),
    );
    addTearDown(controller.dispose);

    await _pumpNetworkScreen(tester, controller);
    await tester.enterText(find.byType(TextField).first, 'partial.example');
    await tester.tap(find.text('Start Ping'));
    await tester.pumpAndSettle();

    expect(find.text('OK'), findsOneWidget);
    expect(find.text('FAIL'), findsOneWidget);
    expect(find.text('Request timed out.'), findsOneWidget);
    expect(find.text('1 (50%)'), findsOneWidget);
  });

  testWidgets('unsupported ping renders as unavailable instead of failed', (
    tester,
  ) async {
    final controller = _networkController(
      pingService: _ImmediatePingService([
        const PingError(
          isUnsupported: true,
          message:
              'Ping requires raw ICMP access, which browser builds cannot use.',
        ),
        const PingSummary(transmitted: 1, received: 0),
      ]),
    );
    addTearDown(controller.dispose);

    await _pumpNetworkScreen(tester, controller);
    await tester.enterText(find.byType(TextField).first, 'example.com');
    await tester.tap(find.text('Start Ping'));
    await tester.pumpAndSettle();

    expect(find.text('N/A'), findsOneWidget);
    expect(
      find.text(
        'Ping requires raw ICMP access, which browser builds cannot use.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('unsupported trace renders as unavailable instead of timeout', (
    tester,
  ) async {
    final controller = _networkController(
      tracerouteService: _ImmediateTracerouteService([
        TracerouteHop(
          hopNumber: 1,
          status: TracerouteHopStatus.unsupported,
          message: 'Traceroute is not supported on web.',
        ),
      ]),
    );
    addTearDown(controller.dispose);

    await _pumpNetworkScreen(tester, controller);
    await tester.tap(find.text('Trace'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'example.com');
    await tester.tap(find.text('Start Trace'));
    await tester.pumpAndSettle();

    expect(find.text('N/A'), findsOneWidget);
    expect(find.text('Traceroute is not supported on web.'), findsOneWidget);
  });
}

NetworkController _networkController({
  PingService? pingService,
  DnsService? dnsService,
  TracerouteService? tracerouteService,
}) {
  return NetworkController(
    pingService: pingService ?? _ImmediatePingService(const []),
    dnsService: dnsService ?? _ImmediateDnsService(),
    tracerouteService: tracerouteService ?? _ImmediateTracerouteService(),
  );
}

Future<void> _pumpNetworkScreen(
  WidgetTester tester,
  NetworkController controller,
) async {
  _setSurfaceSize(tester, const Size(1200, 800));
  await tester.pumpWidget(
    ChangeNotifierProvider<NetworkController>.value(
      value: controller,
      child: const MaterialApp(home: Scaffold(body: NetworkScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

void _setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _ImmediatePingService extends PingService {
  _ImmediatePingService([this.events = const []]);

  final List<PingEvent> events;

  @override
  Stream<PingEvent> ping({
    required String host,
    required int count,
    required Duration timeout,
    required int ttl,
  }) async* {
    for (final event in events) {
      yield event;
    }
  }
}

class _BlockingPingService extends PingService {
  _BlockingPingService(this.release);

  final Completer<void> release;
  final Completer<void> started = Completer<void>();
  bool stopCalled = false;

  @override
  Stream<PingEvent> ping({
    required String host,
    required int count,
    required Duration timeout,
    required int ttl,
  }) async* {
    started.complete();
    yield const PingResponse(
      seq: 0,
      ip: '192.0.2.1',
      ttl: 64,
      time: Duration(milliseconds: 10),
    );
    await release.future;
    yield const PingSummary(transmitted: 1, received: 1);
  }

  @override
  void stopPing() {
    stopCalled = true;
  }
}

class _ImmediateDnsService extends DnsService {
  @override
  Future<List<DnsRecord>> lookup({
    required String domain,
    required DnsRecordType type,
  }) async {
    return const [];
  }
}

class _ImmediateTracerouteService extends TracerouteService {
  _ImmediateTracerouteService([this.hops = const []]);

  final List<TracerouteHop> hops;

  @override
  Stream<TracerouteHop> trace({
    required String host,
    int maxHops = 30,
    int timeout = 2,
  }) async* {
    for (final hop in hops) {
      yield hop;
    }
  }

  @override
  Future<void> stopTrace() async {}
}
