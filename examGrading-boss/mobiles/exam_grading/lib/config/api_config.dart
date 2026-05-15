import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const _dartDefinedUrl = String.fromEnvironment('FASTAPI_URL');
  static const _androidEmulatorUrl = 'http://10.0.2.2:8000';

  static String get baseUrl {
    final configuredUrl = _dartDefinedUrl.isNotEmpty
        ? _dartDefinedUrl
        : dotenv.env['FASTAPI_URL'];

    return _normalize(configuredUrl ?? _androidEmulatorUrl);
  }

  static String get source {
    if (_dartDefinedUrl.isNotEmpty) return 'dart-define';
    if ((dotenv.env['FASTAPI_URL'] ?? '').isNotEmpty) return '.env';
    return 'android-emulator-default';
  }

  static Uri endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }

  static String _normalize(String url) {
    return url.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
