import 'dart:io';

Future<List<Map<String, Object?>>> runNativeDnsLookupFallback({
  required String domain,
  required String type,
}) async {
  final result = await Process.run('nslookup', [
    '-type=$type',
    domain,
  ]).timeout(const Duration(seconds: 5));

  if (result.exitCode != 0) {
    return const [];
  }

  final output = '${result.stdout}\n${result.stderr}';
  return _parseNslookupOutput(output, type);
}

List<Map<String, Object?>> _parseNslookupOutput(String output, String type) {
  final records = <Map<String, Object?>>[];
  final lines = output
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  var inAnswer = false;
  for (final line in lines) {
    if (line.startsWith('Name:')) {
      inAnswer = true;
      continue;
    }

    final parsed = switch (type) {
      'A' || 'AAAA' => _parseAddressLine(line, type, inAnswer),
      'CNAME' => _parseKeyValueLine(line, type, 'canonical name ='),
      'MX' => _parseMxLine(line),
      'NS' => _parseKeyValueLine(line, type, 'nameserver ='),
      'TXT' => _parseKeyValueLine(line, type, 'text ='),
      _ => null,
    };

    if (parsed != null) {
      records.add(parsed);
    }
  }

  return records;
}

Map<String, Object?>? _parseAddressLine(
  String line,
  String type,
  bool inAnswer,
) {
  if (!inAnswer) return null;

  final prefixMatch = RegExp(r'^Addresses?:\s*(.+)$').firstMatch(line);
  final value = prefixMatch?.group(1) ?? line;
  if (!_isAddressForType(value, type)) {
    return null;
  }

  return {'type': type, 'value': value, 'ttl': 0};
}

Map<String, Object?>? _parseKeyValueLine(
  String line,
  String type,
  String marker,
) {
  final lowerLine = line.toLowerCase();
  final markerIndex = lowerLine.indexOf(marker);
  if (markerIndex == -1) return null;

  final value = line.substring(markerIndex + marker.length).trim();
  if (value.isEmpty) return null;

  return {'type': type, 'value': value, 'ttl': 0};
}

Map<String, Object?>? _parseMxLine(String line) {
  final match = RegExp(
    r'MX preference\s*=\s*(\d+),\s*mail exchanger\s*=\s*(.+)$',
    caseSensitive: false,
  ).firstMatch(line);
  if (match == null) return null;

  final priority = match.group(1);
  final exchanger = match.group(2)?.trim();
  if (priority == null || exchanger == null || exchanger.isEmpty) {
    return null;
  }

  return {'type': 'MX', 'value': '$priority $exchanger', 'ttl': 0};
}

bool _isAddressForType(String value, String type) {
  final address = InternetAddress.tryParse(value);
  if (address == null) return false;

  return switch (type) {
    'A' => address.type == InternetAddressType.IPv4,
    'AAAA' => address.type == InternetAddressType.IPv6,
    _ => false,
  };
}
