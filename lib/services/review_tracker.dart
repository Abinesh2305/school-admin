import 'package:hive_flutter/hive_flutter.dart';

class ReviewTracker {
  static const _boxName = 'settings';
  static const _lastShownKey = 'review_last_shown';
  static const _ratedVersionKey = 'review_rated_version';

  /// Call before showing dialog
  static Future<bool> canAskReview(String currentVersion) async {
    final box = Hive.box(_boxName);

    // If already rated this version → never ask again
    final ratedVersion = box.get(_ratedVersionKey);
    if (ratedVersion == currentVersion) return false;

    // Cooldown check3
    final lastShown = box.get(_lastShownKey);
    if (lastShown == null) return true;

    final lastTime = DateTime.tryParse(lastShown);
    if (lastTime == null) return true;

    final diff = DateTime.now().difference(lastTime);
    return diff.inDays >= 2; // cool down period in days66
  }

  /// Call when user clicks "Later" / Exit / Back / Home
  static Future<void> markLater() async {
    final box = Hive.box(_boxName);
    await box.put(_lastShownKey, DateTime.now().toIso8601String());
  }

  /// Call ONLY when user clicks "Rate Now"
  static Future<void> markRated(String version) async {
    final box = Hive.box(_boxName);
    await box.put(_ratedVersionKey, version);
  }
}
