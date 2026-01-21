import '../storage/database_helper.dart';
import '../../core/constants/app_constants.dart';

/// Service for managing app preferences using SQLite
class PreferencesService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Initialize preferences service
  static Future<void> initialize() async {
    // Ensure database is initialized
    await _dbHelper.database;
  }

  /// Save theme mode preference
  /// themeMode: 'light', 'dark', or 'system'
  static Future<void> saveThemeMode(String themeMode) async {
    await _dbHelper.insertOrUpdatePreference(
      AppConstants.keyThemeMode,
      themeMode,
    );
  }

  /// Get theme mode preference
  /// Returns: 'light', 'dark', or 'system' (default: 'system')
  static Future<String> getThemeMode() async {
    final theme = await _dbHelper.getPreference(AppConstants.keyThemeMode);
    return theme ?? AppConstants.defaultThemeMode;
  }

  /// Save language preference
  /// language: 'en' or 'ta'
  static Future<void> saveLanguage(String language) async {
    await _dbHelper.insertOrUpdatePreference(
      AppConstants.keyLanguage,
      language,
    );
  }

  /// Get language preference
  /// Returns: 'en' or 'ta' (default: 'en')
  static Future<String> getLanguage() async {
    final language = await _dbHelper.getPreference(AppConstants.keyLanguage);
    return language ?? AppConstants.defaultLanguage;
  }

  /// Clear all preferences
  static Future<void> clearAll() async {
    await _dbHelper.clearAllPreferences();
  }

  /// Close database connection
  static Future<void> close() async {
    await _dbHelper.close();
  }
}

