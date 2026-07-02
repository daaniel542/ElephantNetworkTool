import 'package:flutter_test/flutter_test.dart';
import 'package:net_utility_toolkit/features/network/ping_event.dart';

void main() {
  group('PingSummary', () {
    test('reports zero packet loss when nothing was transmitted', () {
      const summary = PingSummary(transmitted: 0, received: 0);

      expect(summary.packetLoss, 0);
    });

    test('calculates packet loss from transmitted and received packets', () {
      const summary = PingSummary(transmitted: 5, received: 3);

      expect(summary.packetLoss, 40);
    });

    test(
      'clamps impossible received counts instead of reporting negative loss',
      () {
        const summary = PingSummary(transmitted: 2, received: 5);

        expect(summary.packetLoss, 0);
      },
    );

    test('preserves unsupported ping errors for UI classification', () {
      const event = PingError(
        isUnsupported: true,
        message: 'Ping is not supported here.',
      );

      expect(event.isUnsupported, isTrue);
      expect(event.message, 'Ping is not supported here.');
    });
  });
}
