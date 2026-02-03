import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

import 'dio_client.dart';
import '../core/constants/app_constants.dart';
import '../infrastructure/storage/auth_storage_service.dart';

class AuthService {
  // ===============================
  // CLIENT PAYLOAD (MATCH BACKEND)
  // ===============================
  static const Map<String, dynamic> _clientPayload = {
    "appName": "SchoolWeb",
    "appVersion": "1.0.0",
    "deviceType": "ANDROID",
    "browserName": "FLUTTER",
  };

  // =====================================================
  //  LOGIN
  // =====================================================

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/identity/school/login",
        data: {
          "identifier": identifier,
          "password": password,
          "client": _clientPayload,
        },
      );

      final data = Map<String, dynamic>.from(response.data);

      debugPrint(" LOGIN RESPONSE => $data");

      final box = Hive.box(AppConstants.storageBoxSettings);

      // ===============================
      // MULTI SCHOOL LOGIN
      // ===============================
      if (data['requiresSchoolSelection'] == true && data['schools'] is List) {
        // Save linked users
        final List schools = data['schools'];

        final List<Map<String, dynamic>> parsedSchools = schools
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        await box.put(AppConstants.keyLinkedUsers, parsedSchools);

        //  SAVE SCHOOLS FOR SWITCHING
        await box.put(AppConstants.keySchools, data['schools']);

        debugPrint("🏫 SCHOOLS SAVED => ${data['schools']}");

        return {
          "success": true,
          "requiresSchoolSelection": true,
          "loginChallengeToken": data['loginChallengeToken'],
          "schools": data['schools'],
        };
      }

      // ===============================
      // DIRECT LOGIN
      // ===============================
      if (data['accessToken'] != null) {
        await _clearOldSession();
        await _saveAuth(data);

        await subscribeToTopics(
          _getSchoolIdFromToken(data['accessToken']) ?? 0,
        );

        return {"success": true, "requiresSchoolSelection": false};
      }

      return {"success": false, "message": data['message'] ?? "Login failed"};
    } on DioException catch (e) {
      debugPrint(" LOGIN ERROR: ${e.response?.data}");

      return {
        "success": false,
        "message": e.response?.data?['message'] ?? "Login failed",
      };
    } catch (e) {
      debugPrint(" LOGIN ERROR: $e");

      return {"success": false, "message": "Login failed"};
    }
  }

  // =====================================================
  // COMPLETE SCHOOL LOGIN
  // =====================================================

  Future<Map<String, dynamic>> completeSchoolLogin({
    required String loginChallengeToken,
    required int schoolId,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/identity/school/login/complete",
        data: {
          "loginChallengeToken": loginChallengeToken,
          "schoolId": schoolId,
          "client": _clientPayload,
        },
      );

      final data = Map<String, dynamic>.from(response.data);

      debugPrint("📥 COMPLETE LOGIN RESPONSE => $data");

      if (data['accessToken'] == null || data['sessionId'] == null) {
        throw Exception("Invalid auth response");
      }

      await _clearOldSession(); //  NEW
      await _saveAuth(data);

      await subscribeToTopics(schoolId); //  NEW

      return {"success": true};
    } on DioException catch (e) {
      debugPrint(" COMPLETE LOGIN ERROR: ${e.response?.data}");

      return {
        "success": false,
        "message": e.response?.data?['message'] ?? "Login failed",
      };
    } catch (e) {
      debugPrint(" COMPLETE LOGIN ERROR: $e");

      return {"success": false, "message": "Login failed"};
    }
  }

  // =====================================================
  // CLEAR OLD SESSION (NEW)
  // =====================================================

  Future<void> _clearOldSession() async {
    try {
      debugPrint("🧹 Clearing old session");

      final box = Hive.box(AppConstants.storageBoxSettings);

      // Only clear auth data
      await box.delete(AppConstants.keyToken);
      await box.delete(AppConstants.keyRefreshToken);
      await box.delete(AppConstants.keySessionId);
      await box.delete(AppConstants.keyUser);

      //  DO NOT delete schools
      // DO NOT delete linked users
    } catch (e) {
      debugPrint("⚠️ Clear session error: $e");
    }
  }

  // =====================================================
  //  FCM SUBSCRIBE
  // =====================================================

  Future<void> subscribeToTopics(int schoolId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || schoolId == 0) return;

      await FirebaseMessaging.instance.subscribeToTopic("School_$schoolId");

      debugPrint(" FCM → School_$schoolId");
    } catch (e) {
      debugPrint(" FCM ERROR: $e");
    }
  }

  // =====================================================
  //  SAVE AUTH DATA
  // =====================================================

  Future<void> _saveAuth(Map<String, dynamic> data) async {
    final box = Hive.box(AppConstants.storageBoxSettings);

    await AuthStorage.saveAll(
      token: data['accessToken'],
      refreshToken: data['refreshToken'],
      sessionId: data['sessionId'],
      schoolId: data['schoolId'] ?? _getSchoolIdFromToken(data['accessToken']),
    );

    // Save user
    if (data['user'] != null) {
      await box.put(
        AppConstants.keyUser,
        Map<String, dynamic>.from(data['user']),
      );
    }

    // Save academic year
    if (data['academicYearId'] != null) {
      await box.put(AppConstants.keyAcademicYear, data['academicYearId']);
    }

    AuthStorage.debugPrintAuth();

    debugPrint("✅ AUTH STORAGE COMPLETE");
  }

  // =====================================================
  //   JWT → SCHOOL ID
  // =====================================================

  int? _getSchoolIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];

      final decoded = String.fromCharCodes(
        base64Url.decode(base64Url.normalize(payload)),
      );

      final map = Map<String, dynamic>.from(jsonDecode(decoded));

      return int.tryParse(map['school_id']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }
}
