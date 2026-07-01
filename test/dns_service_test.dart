import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:net_utility_toolkit/features/network/dns_service.dart';

void main() {
  group('DnsService', () {
    test('sends Cloudflare DoH request and parses answer records', () async {
      final service = DnsService(
        client: MockClient((request) async {
          expect(request.url.toString(), contains('cloudflare-dns.com'));
          expect(request.url.queryParameters['name'], 'example.com');
          expect(request.url.queryParameters['type'], 'A');
          expect(request.headers['Accept'], 'application/dns-json');

          return http.Response(
            jsonEncode({
              'Answer': [
                {'type': 1, 'data': '93.184.216.34', 'TTL': 300},
              ],
            }),
            200,
          );
        }),
      );

      final records = await service.lookup(
        domain: ' https://example.com/docs ',
        type: DnsRecordType.a,
      );

      expect(records, hasLength(1));
      expect(records.single.type, 'A');
      expect(records.single.value, '93.184.216.34');
      expect(records.single.ttl, 300);
      expect(records.single.formatted, 'A  93.184.216.34  TTL 300');
    });

    test('throws a clean message for Cloudflare rate limiting', () async {
      final service = DnsService(
        client: MockClient(
          (_) async => http.Response('Too Many Requests', 429),
        ),
      );

      expect(
        () => service.lookup(domain: 'example.com', type: DnsRecordType.a),
        throwsA(
          isA<DnsServiceException>().having(
            (error) => error.message,
            'message',
            'Too many requests. Please wait a moment before trying again.',
          ),
        ),
      );
    });
  });
}
