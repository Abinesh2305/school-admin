import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'dio_client.dart';
import 'dart:io';
import '../core/constants/api_endpoints.dart';
import '../core/constants/app_constants.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:android_intent_plus/android_intent.dart';

Future<bool> isGooglePlayServiceAvailable() async {
  try {
    await FirebaseMessaging.instance.getToken();
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> openGooglePlayServicesSettings() async {
  if (!Platform.isAndroid) return;

  const intent = AndroidIntent(
    action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
    data: 'package:com.google.android.gms',
  );

  await intent.launch();
}

Future<bool> _isFcmAvailable() async {
  try {
    await FirebaseMessaging.instance.getToken();
    return true;
  } catch (e) {
    print("⚠️ FCM not available: $e");
    return false;
  }
}

/// Subscribe to a Firebase topic (FCM + optional backend tracking)
Future<bool> safeSubscribe(String topic) async {
  try {
    final fcmReady = await _isFcmAvailable();
    if (!fcmReady) {
      print("⚠️ Skipping FCM subscribe (service not available)");
      return false;
    }

    await FirebaseMessaging.instance.subscribeToTopic(topic);
    print("✅ SUBSCRIBED → $topic");

    // Backend tracking must NEVER block
    unawaited(_subscribeTopicOnBackend(topic));

    return true;
  } on FirebaseException catch (e) {
    if (e.message?.contains('SERVICE_NOT_AVAILABLE') ?? false) {
      print("⚠️ FCM SERVICE_NOT_AVAILABLE → retry later");
      return false;
    }
    print("❌ FCM ERROR → $e");
    return false;
  } catch (e) {
    print("❌ SUBSCRIBE ERROR → $topic → $e");
    return false;
  }
}

/// Unsubscribe from a Firebase topic (FCM + optional backend tracking)
Future<bool> safeUnsubscribe(String topic) async {
  try {
    final fcmReady = await _isFcmAvailable();
    if (!fcmReady) {
      print("⚠️ Skipping FCM unsubscribe (service not available)");
      return false;
    }

    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    print("✅ UNSUBSCRIBED → $topic");

    unawaited(_unsubscribeTopicOnBackend(topic));

    return true;
  } catch (e) {
    print("❌ UNSUBSCRIBE ERROR → $topic → $e");
    return false;
  }
}

/// Subscribe to topic via backend API (for tracking purposes)
Future<void> _subscribeTopicOnBackend(String topic) async {
  try {
    final box = Hive.box(AppConstants.storageBoxSettings);
    final user = box.get(AppConstants.keyUser);
    final token = box.get(AppConstants.keyToken);

    if (user == null || token == null) {
      print("⚠️ Cannot track topic subscription: User not logged in");
      return;
    }

    final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
    final schoolId = user['school_college_id'] ?? '';

    await DioClient.dio.post(
      ApiEndpoints.subscribeTopic,
      data: {
        'topic': topic,
        'fcm_token': fcmToken,
        'user_id': user['id'],
        'school_id': schoolId,
        'api_token': token,
      },
      options: Options(headers: {AppConstants.headerApiKey: token}),
    );

    print("✅ Topic subscription tracked on backend: $topic");
  } catch (e) {
    // Non-critical error - just log it
    print("⚠️ Failed to track topic subscription on backend: $e");
  }
}

/// Unsubscribe from topic via backend API (for tracking purposes)
Future<void> _unsubscribeTopicOnBackend(String topic) async {
  try {
    final box = Hive.box(AppConstants.storageBoxSettings);
    final user = box.get(AppConstants.keyUser);
    final token = box.get(AppConstants.keyToken);

    if (user == null || token == null) {
      print("⚠️ Cannot track topic unsubscription: User not logged in");
      return;
    }

    final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
    final schoolId = user['school_college_id'] ?? '';

    await DioClient.dio.post(
      ApiEndpoints.unsubscribeTopic,
      data: {
        'topic': topic,
        'fcm_token': fcmToken,
        'user_id': user['id'],
        'school_id': schoolId,
        'api_token': token,
      },
      options: Options(headers: {AppConstants.headerApiKey: token}),
    );

    print("✅ Topic unsubscription tracked on backend: $topic");
  } catch (e) {
    // Non-critical error - just log it
    print("⚠️ Failed to track topic unsubscription on backend: $e");
  }
}
