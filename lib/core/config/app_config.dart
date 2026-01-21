import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Application configuration manager
class AppConfig {
  static String? _baseUrl;
  static String? _appName;
  
  /// Initialize configuration from environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      _baseUrl = dotenv.env['BASE_URL'];
      _appName = dotenv.env['APP_NAME'];
    } catch (e) {
      debugPrint("⚠️ .env file not found, using defaults");
      _baseUrl = null;
      _appName = null;
    }
  }
  
  /// Get base URL for API calls
  static String get baseUrl => _baseUrl ?? 'https://mock-backend.local';
  
  /// Get app name
  static String get appName => _appName ?? 'ClasteqSMS';
  
  /// Check if running in mock mode
  static bool get isMockMode => _baseUrl == null;
  
  /// Check if running in debug mode
  static bool get isDebugMode => kDebugMode;
  
  /// Check if running in release mode
  static bool get isReleaseMode => kReleaseMode;
  
  /// Get API timeout duration
  static Duration get connectTimeout => const Duration(seconds: 10);
  static Duration get receiveTimeout => const Duration(seconds: 15);
}

