import 'dart:convert';

import 'package:http/http.dart' as http;

import 'network_controller.dart';

/// A single DNS answer record returned by the Cloudflare DoH API.
class DnsRecord {
  const DnsRecord({required this.type, required this.value, required this.ttl});

  final String type;
  final String value;
  final int ttl;

  String get formatted => '$type  $value  TTL $ttl';
}

class DnsServiceException implements Exception {
  const DnsServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DnsServiceException implements Exception {
  const DnsServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Performs DNS lookups via Cloudflare's DNS-over-HTTPS JSON API.
///
/// Endpoint: https://cloudflare-dns.com/dns-query
class DnsService {
  DnsService({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://cloudflare-dns.com/dns-query';

  final http.Client _client;

  /// Resolve [domain] for the given [type] and return DNS answer records.
  Future<List<DnsRecord>> lookup({
    required String domain,
    required DnsRecordType type,
  }) async {
    // Strip accidental protocol schemas and trim whitespace.
    final cleanDomain = domain
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'^www\.'), '')
        .trim();

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {'name': cleanDomain, 'type': type.name.toUpperCase()},
    );

    late http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: const {'Accept': 'application/dns-json'},
      );
    } catch (_) {
      throw const DnsServiceException(
        'Network unavailable. Check local interface connections.',
      );
    }

    if (response.statusCode == 429) {
      throw const DnsServiceException(
        'Too many requests. Please wait a moment before trying again.',
      );
    }

    if (response.statusCode != 200) {
      throw const DnsServiceException(
        'DNS lookup failed. Please check the domain.',
      );
    }

    final Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Response was not a JSON object.');
      }
      body = decoded;
    } catch (_) {
      throw const DnsServiceException(
        'DNS lookup failed. Please check the domain.',
      );
    }

    final answers = body['Answer'];
    if (answers is! List || answers.isEmpty) {
      return const [];
    }

    return answers
        .whereType<Map<String, dynamic>>()
        .map(
          (answer) => DnsRecord(
            type: _typeCodeToName(answer['type']),
            value: (answer['data'] as String?) ?? '',
            ttl: (answer['TTL'] as num?)?.toInt() ?? 0,
          ),
        )
        .where((record) => record.value.isNotEmpty)
        .toList(growable: false);
  }

  void close() => _client.close();

  String _cleanDomain(String domain) {
    var value = domain.trim();

    value = value.replaceFirst(RegExp(r'^[a-zA-Z][a-zA-Z\d+\-.]*://'), '');
    value = value.split(RegExp(r'[/?#]')).first.trim();
    value = value.replaceFirst(RegExp(r':\d+$'), '');
    value = value.replaceFirst(RegExp(r'\.$'), '');

    if (value.isEmpty) {
      throw const DnsServiceException(
        'DNS lookup failed. Please check the domain.',
      );
    }

    return value;
  }

  String _typeCodeToName(Object? code) {
    const mapping = {
      1: 'A',
      28: 'AAAA',
      5: 'CNAME',
      15: 'MX',
      16: 'TXT',
      2: 'NS',
    };
    final numericCode = code is num ? code.toInt() : 0;
    return mapping[numericCode] ?? numericCode.toString();
  }
}
