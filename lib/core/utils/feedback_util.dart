import 'dart:developer';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackUtil {
  static const String _reviewRequestedKey = 'has_requested_review';

  static Future<bool> hasRequestedReview() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reviewRequestedKey) ?? false;
  }

  static Future<void> askFeedBack() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_reviewRequestedKey, true);
      }
    } catch (e) {
      log(e.toString());
    }
  }

  /// Call this after first entry is saved
  static Future<void> askFeedbackIfFirstEntry() async {
    final alreadyAsked = await hasRequestedReview();
    if (!alreadyAsked) {
      // Small delay so the screen transition completes first
      await Future.delayed(const Duration(seconds: 2));
      await askFeedBack();
    }
  }
}