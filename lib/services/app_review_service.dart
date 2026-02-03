import 'package:in_app_review/in_app_review.dart';

class AppReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// Google UI (may show in-app OR Play Store)
  static Future<void> requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (_) {}
  }

  /// Always opens Play Store (PUBLIC review)
  static Future<void> requestPublicReview({
    required String androidPackageName,
  }) async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: androidPackageName,
      );
    } catch (_) {}
  }
}
