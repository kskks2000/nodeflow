import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const _overrideBaseUrl = String.fromEnvironment(
    'NODEFLOW_API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }
    if (kIsWeb) {
      return 'http://www.kcastle.net/api/v1';
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://www.kcastle.net/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }
}
