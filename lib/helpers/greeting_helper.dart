import '../l10n/app_localizations.dart';

/// Helper class for time-based greetings
class GreetingHelper {
  /// Get greeting based on current time of day
  /// Returns localized greeting: "Good Morning", "Good Afternoon", or "Good Evening"
  static String getGreeting(AppLocalizations localizations) {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return localizations.goodMorning;
    } else if (hour >= 12 && hour < 17) {
      return localizations.goodAfternoon;
    } else if (hour >= 17 && hour < 21) {
      return localizations.goodEvening;
    } else {
      return localizations.goodNight;
    }
  }

  /// Get greeting with user's name
  static String getGreetingWithName(AppLocalizations localizations, String? name) {
    final greeting = getGreeting(localizations);
    if (name != null && name.isNotEmpty) {
      return '$greeting, $name';
    }
    return greeting;
  }

  /// Get greeting emoji based on time
  static String getGreetingEmoji() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return '☀️';
    } else if (hour >= 12 && hour < 17) {
      return '🌤️';
    } else if (hour >= 17 && hour < 21) {
      return '🌆';
    } else {
      return '🌙';
    }
  }
}

