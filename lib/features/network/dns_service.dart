import 'dart:convert';
import 'package:http/http.dart' as http;
import 'network_controller.dart';

/// A single DNS answer record returned by the Cloudflare DoH API.
class DnsRecord {
  const DnsRecord({
    required this.type,
    required this.value,
    required this.ttl,
  });

  final String type;
  final String value;
  final int ttl;
}

/// Performs DNS lookups via Cloudflare's DNS-over-HTTPS JSON API.
///
/// Endpoint: https://cloudflare-dns.com/dns-query
/// Reference: https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-https/make-api-requests/json/
class DnsService {
  static const _baseUrl = 'https://cloudflare-dns.com/dns-query';

  /// Resolve [domain] for the given [type] and return a list of [DnsRecord]s.
  ///
  /// Throws a descriptive [Exception] on network failure, rate-limiting, or
  /// empty/malformed responses — matching the error matrix in PRD section 17.
  Future<List<DnsRecord>> lookup({
    required String domain,
    required DnsRecordType type,
  }) async {
    // Strip accidental protocol schemas and trim whitespace.
    final cleanDomain = domain
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'^www\.'), '')
        .trim();

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'name': cleanDomain,
      'type': type.name.toUpperCase(),
    });

    late http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {'Accept': 'application/dns-json'},
      );
    } catch (_) {
      throw Exception('Network unavailable. Check local interface connections.');
    }

    if (response.statusCode == 429) {
      throw Exception('Too many requests. Please wait a moment before trying again.');
    }

    if (response.statusCode != 200) {
      throw Exception('DNS lookup failed. Please check the domain.');
    }

    final Map<String, dynamic> body;
    try {
      body = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('DNS lookup failed. Please check the domain.');
    }

    final answers = body['Answer'] as List<dynamic>?;
    if (answers == null || answers.isEmpty) {
      return [];
    }

    return answers.map((a) {
      final map = a as Map<String, dynamic>;
      return DnsRecord(
        type: _typeCodeToName(map['type'] as int? ?? 0),
        value: map['data'] as String? ?? '',
        ttl: map['TTL'] as int? ?? 0,
      );
    }).toList();
  }

  /// Map a numeric DNS type code to its string name.
  String _typeCodeToName(int code) {
    const mapping = {
      1: 'A',
      28: 'AAAA',
      5: 'CNAME',
      15: 'MX',
      16: 'TXT',
      2: 'NS',
    };
    return mapping[code] ?? code.toString();
  }
}
