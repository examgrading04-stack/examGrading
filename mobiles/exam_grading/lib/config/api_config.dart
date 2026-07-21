import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const _dartDefinedUrl = String.fromEnvironment('FASTAPI_URL');
  static const _defaultUrl = 'http://127.0.0.1:8000';

  static String get baseUrl {
    final configuredUrl = _dartDefinedUrl.isNotEmpty
        ? _dartDefinedUrl
        : dotenv.env['FASTAPI_URL'];

    String url = _normalize(configuredUrl ?? _defaultUrl);

    return url;
  }

  static String get source {
    if (_dartDefinedUrl.isNotEmpty) return 'dart-define';
    if ((dotenv.env['FASTAPI_URL'] ?? '').isNotEmpty) return '.env';
    return 'default';
  }

  static Uri endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }

  static String _normalize(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('FASTAPI_URL=')) {
      return trimmed
          .replaceFirst('FASTAPI_URL=', '')
          .trim()
          .replaceFirst(RegExp(r'/+$'), '');
    }
    return trimmed.replaceFirst(RegExp(r'/+$'), '');
  }
}
