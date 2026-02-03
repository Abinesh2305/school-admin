import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Application configuration manager
class AppConfig {
  static String? _baseUrl;
  static String? _appName;

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");

      _baseUrl = dotenv.env['BASE_URL'];
      _appName = dotenv.env['APP_NAME'];

      debugPrint("✅ ENV Loaded");
      debugPrint("🌍 BASE_URL = $_baseUrl");
    } catch (e) {
      debugPrint("⚠️ .env not loaded: $e");
      _baseUrl = null;
      _appName = null;
    }
  }

  /// Always return real API (no mock fallback)
  static String get baseUrl =>
      _baseUrl ?? 'https://api.clasteqsms.in/api/';

  static String get appName => _appName ?? 'ClasteqSMS';

  static bool get isDebugMode => kDebugMode;
  static bool get isReleaseMode => kReleaseMode;

  static Duration get connectTimeout =>
      const Duration(seconds: 10);

  static Duration get receiveTimeout =>
      const Duration(seconds: 15);
}
