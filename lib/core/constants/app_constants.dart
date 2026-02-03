/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'ClasteqSMS';
  static const String appVersion = '3.1.24';
  
  // API Constants
  static const String baseUrl = 'https://api.clasteqsms.in/api';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  
  // Storage Keys
  static const String storageBoxSettings = 'settings';
  static const String storageBoxPendingReads = 'pending_reads';
  static const String storageBoxPendingReadsHomework = 'pending_reads_homework';
  
  // User Preferences Keys
  // User Preferences Keys
static const String keyUser = 'user';
static const String keyToken = 'token';
static const String keyRefreshToken = 'refresh_token';
static const String keySessionId = 'session_id';
static const String keyLanguage = 'language';
static const String keyThemeMode = 'themeMode';
static const String keyLinkedUsers = 'linked_users';
static const String keyIsFirstLaunch = 'is_first_launch';
static const String keyUpdateRequested = 'updateRequested';
static const String keyLastVersion = 'lastVersion';
static const String keySchoolId = 'school_id';
static const String keyActiveSchool = 'active_school';
static const String storageBoxCache = "cache";
static const String keySchools = "schools";

// Academic year
static const String keyAcademicYear = "academic_year_id";

  
  // Default Values
  static const String defaultLanguage = 'en';
  static const String defaultThemeMode = 'system';
  static const String defaultSchoolId = '1';
  
  // Network Headers
  static const String headerAccept = 'Accept';
  static const String headerApiKey = 'x-api-key';
  
  // Pagination
  static const int defaultPageSize = 10;
  static const int defaultPageNumber = 0;
  
  // Date Formats
  static const String dateFormatYYYYMMDD = 'yyyy-MM-dd';
  static const String dateFormatYYYYMM = 'yyyy-MM';
  
  // Notification Channels
  static const String notificationChannelId = 'high_importance_channel';
  static const String notificationChannelName = 'High Importance Notifications';
  
  // Firebase Topics Prefixes
  static const String topicPrefixSchool = 'School_Scholars_';
  static const String topicPrefixScholar = 'Scholar_';
  static const String topicPrefixSection = 'Section_';
  static const String topicPrefixGroup = 'Group_';
  
  // Device Types
  static const String deviceTypeAndroid = 'ANDROID';
  static const String deviceTypeIOS = 'IOS';
  
  // Error Messages
  static const String errorNetwork = 'Network error occurred';
  static const String errorGeneric = 'Something went wrong';
  static const String errorUserNotLoggedIn = 'User not logged in';
  static const String errorInvalidToken = 'Invalid or expired token';
  
  // Success Messages
  static const String successLogin = 'Login successful';
  static const String successLogout = 'Logged out successfully';
  static const String successUpdate = 'Updated successfully';
  
  // Private constructor to prevent instantiation
  AppConstants._();
}

