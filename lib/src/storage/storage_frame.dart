import 'dart:convert';

/// Wraps a JSON payload with an Adler-32 checksum and byte length so silent
/// corruption (bit-rot, truncated writes that still parse as JSON) is detected
/// on read.
///
/// Format: `<adler32hex>:<byteLength>\n<json>`.
///
/// Legacy payloads written before framing existed have no header and are
/// returned verbatim, so upgrading never invalidates existing boxes.
final class StorageFrame {
  const StorageFrame._();

  static final RegExp _headerPattern = RegExp(r'^([0-9a-f]+):(\d+)$');

  static String frame(String json) {
    final bytes = utf8.encode(json);
    final checksum = adler32(bytes).toRadixString(16);
    return '$checksum:${bytes.length}\n$json';
  }

  /// Returns the JSON payload after verifying the header, or throws
  /// [FormatException] if the checksum/length does not match. Input without a
  /// valid header is treated as legacy plain JSON and returned unchanged.
  static String deframe(String raw) {
    final separator = raw.indexOf('\n');
    if (separator > 0) {
      final match = _headerPattern.firstMatch(raw.substring(0, separator));
      if (match != null) {
        final payload = raw.substring(separator + 1);
        final bytes = utf8.encode(payload);
        final expectedLength = int.parse(match.group(2)!);
        final expectedChecksum = int.parse(match.group(1)!, radix: 16);
        if (bytes.length != expectedLength ||
            adler32(bytes) != expectedChecksum) {
          throw const FormatException('Storage checksum mismatch.');
        }
        return payload;
      }
    }
    return raw; // legacy plain JSON, no header
  }

  // ponytail: Adler-32, not CRC-32 — ~8 lines, no lookup table, no dependency.
  // Detects truncation/bit-rot fine; swap for CRC-32 only if collision
  // resistance ever matters (it does not for local disk integrity).
  static int adler32(List<int> bytes) {
    const modAdler = 65521;
    var a = 1;
    var b = 0;
    for (final byte in bytes) {
      a = (a + byte) % modAdler;
      b = (b + a) % modAdler;
    }
    return (b << 16) | a;
  }
}
