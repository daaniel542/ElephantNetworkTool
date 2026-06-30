/// Input validation utilities shared across feature modules.
library;

/// Strip leading/trailing whitespace and accidental protocol prefixes from a
/// domain or hostname string (e.g. "https://example.com" → "example.com").
String cleanDomain(String raw) {
  return raw
      .trim()
      .replaceAll(RegExp(r'^https?://'), '')
      .replaceAll(RegExp(r'^www\.'), '')
      .trim();
}

/// Return true if [host] is a non-empty string that could be a valid hostname
/// or IP address (basic check — not RFC-complete).
bool isValidHost(String host) {
  final trimmed = host.trim();
  if (trimmed.isEmpty) return false;
  // Allow IPs and hostnames; reject obvious garbage.
  return RegExp(r'^[a-zA-Z0-9._\-\[\]:]+$').hasMatch(trimmed);
}

/// Return true if [domain] has at least one dot and no spaces.
bool isValidDomain(String domain) {
  final trimmed = domain.trim();
  return trimmed.isNotEmpty &&
      trimmed.contains('.') &&
      !trimmed.contains(' ');
}

/// Clamp [value] to the range [min, max].
int clampInt(int value, int min, int max) =>
    value < min ? min : (value > max ? max : value);
