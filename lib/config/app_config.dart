import 'package:flutter/foundation.dart';

/// API tabanı. Default `http://localhost:5041` (callcenter pattern #518).
/// `--dart-define=API_BASE_URL=...` her zaman üzerine yazar.
///
/// **Android emülatör** loopback için `10.0.2.2` kullanır.
class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv.trimRight();
    if (kIsWeb) return 'http://localhost:5041';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5041';
      default:
        return 'http://localhost:5041';
    }
  }

  /// Yerel HTTPS dev cert reddedilirse override.
  static const bool allowBadSsl = bool.fromEnvironment(
    'ALLOW_BAD_SSL',
    defaultValue: false,
  );
}
