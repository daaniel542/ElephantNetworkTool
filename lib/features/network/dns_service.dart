import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'dns_lookup_fallback.dart';

typedef DnsFallbackRunner =
    Future<List<Map<String, Object?>>> Function({
      required String domain,
      required String type,
    });

/// Supported DNS record types for Cloudflare DNS-over-HTTPS lookups.
enum DnsRecordType { a, aaaa, cname, mx, txt, ns }

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

/// Performs DNS lookups via Cloudflare's DNS-over-HTTPS JSON API.
///
/// Endpoint: https://cloudflare-dns.com/dns-query
class DnsService {
  DnsService({
    http.Client? client,
    DnsFallbackRunner? fallbackRunner,
    Duration timeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client(),
       _fallbackRunner = fallbackRunner ?? runNativeDnsLookupFallback,
       _timeout = timeout;

  static const _baseUrl = 'https://cloudflare-dns.com/dns-query';

  final http.Client _client;
  final DnsFallbackRunner _fallbackRunner;
  final Duration _timeout;

  /// Resolve [domain] for the given [type] and return DNS answer records.
  Future<List<DnsRecord>> lookup({
    required String domain,
    required DnsRecordType type,
  }) async {
    final cleanDomain = _cleanDomain(domain);

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {'name': cleanDomain, 'type': type.name.toUpperCase()},
    );

    late http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/dns-json'})
          .timeout(_timeout);
    } catch (_) {
      final fallbackRecords = await _lookupWithNativeFallback(
        cleanDomain,
        type.name.toUpperCase(),
      );
      if (fallbackRecords.isNotEmpty) {
        return fallbackRecords;
      }

      throw const DnsServiceException(
        'DNS-over-HTTPS request failed. Check firewall, proxy, or resolver settings.',
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

    final status = (body['Status'] as num?)?.toInt();
    if (status != null && status != 0) {
      throw DnsServiceException(_statusCodeMessage(status));
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

  Future<List<DnsRecord>> _lookupWithNativeFallback(
    String domain,
    String type,
  ) async {
    try {
      final records = await _fallbackRunner(domain: domain, type: type);
      return records
          .map(
            (record) => DnsRecord(
              type: (record['type'] as String?) ?? type,
              value: (record['value'] as String?) ?? '',
              ttl: (record['ttl'] as num?)?.toInt() ?? 0,
            ),
          )
          .where((record) => record.value.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

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

  String _statusCodeMessage(int status) {
    return switch (status) {
      2 => 'DNS resolver failed. Please try again later.',
      3 => 'Domain does not exist.',
      _ => 'DNS lookup failed. Please check the domain.',
    };
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
