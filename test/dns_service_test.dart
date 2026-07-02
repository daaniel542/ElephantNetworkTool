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

          return _jsonResponse({
            'Status': 0,
            'Answer': [
              {'type': 1, 'data': '93.184.216.34', 'TTL': 300},
            ],
          });
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

    test(
      'normalizes URLs, ports, paths, query strings, and trailing dots',
      () async {
        final service = DnsService(
          client: MockClient((request) async {
            expect(request.url.queryParameters['name'], 'example.com');
            return _jsonResponse({
              'Status': 0,
              'Answer': [
                {
                  'type': 28,
                  'data': '2606:2800:220:1:248:1893:25c8:1946',
                  'TTL': 60,
                },
              ],
            });
          }),
        );

        final records = await service.lookup(
          domain: 'https://example.com:443/docs?q=1#frag.',
          type: DnsRecordType.aaaa,
        );

        expect(records.single.type, 'AAAA');
      },
    );

    test('supports all UI-exposed DNS record types', () async {
      const expected = {
        DnsRecordType.a: ('A', 1, '203.0.113.10'),
        DnsRecordType.aaaa: ('AAAA', 28, '2001:db8::10'),
        DnsRecordType.cname: ('CNAME', 5, 'alias.example.com'),
        DnsRecordType.mx: ('MX', 15, '10 mail.example.com'),
        DnsRecordType.txt: (
          'TXT',
          16,
          '"v=spf1 include:_spf.example.com ~all"',
        ),
        DnsRecordType.ns: ('NS', 2, 'ns1.example.com'),
      };

      for (final entry in expected.entries) {
        final service = DnsService(
          client: MockClient((request) async {
            expect(request.url.queryParameters['type'], entry.value.$1);
            return _jsonResponse({
              'Status': 0,
              'Answer': [
                {'type': entry.value.$2, 'data': entry.value.$3, 'TTL': 300},
              ],
            });
          }),
        );

        final records = await service.lookup(
          domain: 'example.com',
          type: entry.key,
        );

        expect(records.single.type, entry.value.$1);
        expect(records.single.value, entry.value.$3);
      }
    });

    test('preserves CNAME chains and unknown numeric record codes', () async {
      final service = DnsService(
        client: MockClient(
          (_) async => _jsonResponse({
            'Status': 0,
            'Answer': [
              {'type': 5, 'data': 'edge.example.net', 'TTL': 120},
              {'type': 65, 'data': '1 . alpn=h3', 'TTL': 120},
              {'type': 1, 'data': '203.0.113.7', 'TTL': 120},
            ],
          }),
        ),
      );

      final records = await service.lookup(
        domain: 'www.example.com',
        type: DnsRecordType.a,
      );

      expect(records.map((record) => record.type), ['CNAME', '65', 'A']);
    });

    test('keeps very long TXT records intact', () async {
      final longTxt = '"${List.filled(512, 'a').join()}"';
      final service = DnsService(
        client: MockClient(
          (_) async => _jsonResponse({
            'Status': 0,
            'Answer': [
              {'type': 16, 'data': longTxt, 'TTL': 1800},
            ],
          }),
        ),
      );

      final records = await service.lookup(
        domain: 'example.com',
        type: DnsRecordType.txt,
      );

      expect(records.single.value, longTxt);
      expect(records.single.value.length, 514);
    });

    test(
      'returns empty records for NOERROR responses without answers',
      () async {
        final service = DnsService(
          client: MockClient((_) async => _jsonResponse({'Status': 0})),
        );

        final records = await service.lookup(
          domain: 'gmail.com',
          type: DnsRecordType.cname,
        );

        expect(records, isEmpty);
      },
    );

    test('throws a clean message for NXDOMAIN', () async {
      final service = DnsService(
        client: MockClient((_) async => _jsonResponse({'Status': 3})),
      );

      await expectLater(
        service.lookup(domain: 'missing.invalid', type: DnsRecordType.a),
        throwsA(
          isA<DnsServiceException>().having(
            (error) => error.message,
            'message',
            'Domain does not exist.',
          ),
        ),
      );
    });

    test('throws a clean message for SERVFAIL', () async {
      final service = DnsService(
        client: MockClient((_) async => _jsonResponse({'Status': 2})),
      );

      await expectLater(
        service.lookup(domain: 'example.com', type: DnsRecordType.a),
        throwsA(
          isA<DnsServiceException>().having(
            (error) => error.message,
            'message',
            'DNS resolver failed. Please try again later.',
          ),
        ),
      );
    });

    test('throws a clean message for Cloudflare rate limiting', () async {
      final service = DnsService(
        client: MockClient(
          (_) async => http.Response('Too Many Requests', 429),
        ),
      );

      await expectLater(
        service.lookup(domain: 'example.com', type: DnsRecordType.a),
        throwsA(
          isA<DnsServiceException>().having(
            (error) => error.message,
            'message',
            'Too many requests. Please wait a moment before trying again.',
          ),
        ),
      );
    });

    test('throws a clean message for non-200 responses', () async {
      final service = DnsService(
        client: MockClient((_) async => http.Response('Bad Gateway', 502)),
      );

      await expectLater(
        service.lookup(domain: 'example.com', type: DnsRecordType.a),
        throwsA(
          isA<DnsServiceException>().having(
            (error) => error.message,
            'message',
            'DNS lookup failed. Please check the domain.',
          ),
        ),
      );
    });

    test('throws a clean message for malformed JSON', () async {
      final service = DnsService(
        client: MockClient((_) async => http.Response('not json', 200)),
      );

      await expectLater(
        service.lookup(domain: 'example.com', type: DnsRecordType.a),
        throwsA(isA<DnsServiceException>()),
      );
    });

    test('throws a clean message for local network exceptions', () async {
      final service = DnsService(
        client: MockClient((_) async => throw Exception('offline')),
      );

      await expectLater(
        service.lookup(domain: 'example.com', type: DnsRecordType.a),
        throwsA(
          isA<DnsServiceException>().having(
            (error) => error.message,
            'message',
            'Network unavailable. Check local interface connections.',
          ),
        ),
      );
    });

    test('throws a clean message when the HTTP request times out', () async {
      final service = DnsService(
        timeout: const Duration(milliseconds: 1),
        client: MockClient(
          (_) => Future.delayed(
            const Duration(milliseconds: 50),
            () => _jsonResponse({'Status': 0}),
          ),
        ),
      );

      await expectLater(
        service.lookup(domain: 'example.com', type: DnsRecordType.a),
        throwsA(
          isA<DnsServiceException>().having(
            (error) => error.message,
            'message',
            'Network unavailable. Check local interface connections.',
          ),
        ),
      );
    });
  });
}

http.Response _jsonResponse(Map<String, Object?> body) {
  return http.Response(jsonEncode(body), 200);
}
