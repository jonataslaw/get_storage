import 'dart:convert';

abstract interface class StorageCodec {
  String encode(Map<String, dynamic> data);

  Map<String, dynamic> decode(String source);
}

final class JsonStorageCodec implements StorageCodec {
  const JsonStorageCodec();

  @override
  String encode(Map<String, dynamic> data) => json.encode(data);

  @override
  Map<String, dynamic> decode(String source) {
    final normalizedSource = source.trim();
    if (normalizedSource.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = json.decode(normalizedSource);
    return switch (decoded) {
      final Map<String, dynamic> data => Map<String, dynamic>.from(data),
      final Map<dynamic, dynamic> data => _decodeMap(data),
      _ => throw const FormatException('Storage data must be a JSON object.'),
    };
  }

  Map<String, dynamic> _decodeMap(Map<dynamic, dynamic> data) {
    final decoded = <String, dynamic>{};

    for (final MapEntry(:key, :value) in data.entries) {
      if (key is! String) {
        throw const FormatException('Storage keys must be strings.');
      }
      decoded[key] = value;
    }

    return decoded;
  }
}
