import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'dio_client.dart';

class HomeService {
  static Future<void> syncHomeContents() async {
    try {
      final box = Hive.box(AppConstants.storageBoxSettings);

      final user = box.get(AppConstants.keyUser);
      final token = box.get(AppConstants.keyToken);

      debugPrint(" Home Sync Started");

      if (user == null || token == null) {
        debugPrint(" Home Sync Failed: user/token null");
        return;
      }

      final fcm = await FirebaseMessaging.instance.getToken();

      final res = await DioClient.dio.post(
        '/homecontents', 
        data: {
          'user_id': user['id'],
          'fcm_token': fcm,
        },
      );

      debugPrint(" HomeContents => ${res.data}");
      debugPrint(" Home Sync Done");

    } catch (e) {
      debugPrint(" Home Sync Error: $e");
    }
  }
}
