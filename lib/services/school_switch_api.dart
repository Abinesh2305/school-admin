import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'dio_client.dart';
import '../../core/constants/app_constants.dart';
import '../../infrastructure/storage/auth_storage_service.dart';

class SchoolSwitchApi {
  /// Switch active school and get new token
  static Future<Map<String, dynamic>> switchSchool({
    required int schoolId,
  }) async {
    try {
      //  Prevent auto logout
      DioClient.isSwitchingSchool = true;

      final box = Hive.box(AppConstants.storageBoxSettings);

      final String? token = box.get(AppConstants.keyToken);
      final String? sessionId = box.get(AppConstants.keySessionId);

      if (token == null || sessionId == null) {
        throw Exception("Missing auth data");
      }

      debugPrint(" OLD TOKEN => $token");
      debugPrint(" OLD SESSION => $sessionId");

      //  Payload
      final payload = {
        "schoolId": schoolId,
        "client": {
          "appName": "ClasteqSMS",
          "appVersion": "1.0.0",
          "deviceType": "ANDROID",
          "browserName": "FLUTTER",
        }
      };

      //  API Call
      final Response response = await DioClient.dio.post(
        "/identity/school/switch",
        data: payload,
      );

      debugPrint(" SWITCH RESPONSE => ${response.data}");

      final data = Map<String, dynamic>.from(response.data);

      //  Validate response
      if (data['accessToken'] == null ||
          data['refreshToken'] == null ||
          data['sessionId'] == null) {
        throw Exception("Invalid switch response");
      }

      //  Save new auth
      await AuthStorage.saveAll(
        token: data['accessToken'],
        refreshToken: data['refreshToken'],
        sessionId: data['sessionId'],
        schoolId: schoolId,
      );

      //  Clear cache
      try {
        await Hive.box(AppConstants.storageBoxCache).clear();
      } catch (_) {
        debugPrint("⚠️ Cache box not found");
      }

      
      debugPrint("🆕 NEW TOKEN => ${data['accessToken']}");
      AuthStorage.debugPrintAuth();

      debugPrint(" SCHOOL SWITCH COMPLETE");

      return {
        "success": true,
        "schoolId": schoolId,
      };
    } on DioException catch (e) {
      debugPrint(" SWITCH API ERROR");
      debugPrint("STATUS: ${e.response?.statusCode}");
      debugPrint("DATA: ${e.response?.data}");
      debugPrint("MSG: ${e.message}");

      return {
        "success": false,
        "message":
            e.response?.data?['message'] ?? "School switch failed",
      };
    } catch (e) {
      debugPrint(" SWITCH ERROR: $e");

      return {
        "success": false,
        "message": "Something went wrong",
      };
    } finally {
      
      DioClient.isSwitchingSchool = false;
    }
  }
}
