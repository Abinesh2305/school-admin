import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../main.dart';
import '../screens/login_screen.dart';

class DioClient {
  // ===============================
  // FLAG: Prevent Logout on Switch
  // ===============================
  static bool isSwitchingSchool = false;

  // ===============================
  //  DIO INSTANCE
  // ===============================
  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: _normalizeBaseUrl(AppConfig.baseUrl),
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        )
        // ===============================
        // LOGGER
        // ===============================
        ..interceptors.add(
          LogInterceptor(
            request: true,
            requestBody: true,
            responseBody: true,
            responseHeader: false,
            error: true,
            logPrint: (obj) => debugPrint('🌐 DIO → $obj'),
          ),
        )
        // ===============================
        //  MAIN INTERCEPTOR
        // ===============================
        ..interceptors.add(
          InterceptorsWrapper(
            // ================= REQUEST =================
            onRequest: (options, handler) async {
              final box = Hive.box(AppConstants.storageBoxSettings);
              final token = box.get(AppConstants.keyToken);

              // Attach latest token
              if (token != null && token.toString().isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              } else {
                options.headers.remove('Authorization');
              }

              debugPrint(' REQUEST → ${options.method} ${options.uri}');
              debugPrint(' HEADERS → ${options.headers}');

              handler.next(options);
            },

            // ================= RESPONSE =================
            onResponse: (response, handler) {
              debugPrint(' RESPONSE → ${response.requestOptions.uri}');
              handler.next(response);
            },

            // ================= ERROR =================
            onError: (DioException e, handler) async {
              debugPrint(' ERROR → ${e.requestOptions.uri}');
              debugPrint(' STATUS → ${e.response?.statusCode}');
              debugPrint(' DATA → ${e.response?.data}');
              debugPrint(' MSG → ${e.message}');

              //  Prevent logout during school switch
              if (e.response?.statusCode == 401 &&
                  !DioClient.isSwitchingSchool) {
                await _forceLogout();
              }

              handler.next(e);
            },
          ),
        );

  // ===============================
  //  HELPERS
  // ===============================

  static String _normalizeBaseUrl(String url) {
    if (!url.endsWith('/')) {
      return '$url/';
    }
    return url;
  }

  // ===============================
  //  FORCE LOGOUT
  // ===============================

  static Future<void> _forceLogout() async {
    try {
      debugPrint(' FORCE LOGOUT');

      final box = Hive.box(AppConstants.storageBoxSettings);

      // Only remove auth data
      await box.delete(AppConstants.keyToken);
      await box.delete(AppConstants.keyRefreshToken);
      await box.delete(AppConstants.keySessionId);
      await box.delete(AppConstants.keyUser);
      await box.delete(AppConstants.keySchoolId);

      final ctx = navigatorKey.currentContext;

      if (ctx == null) {
        debugPrint(' Context null during logout');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 200));

      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              LoginScreen(onToggleTheme: () {}, onToggleLanguage: () {}),
        ),
        (_) => false,
      );
    } catch (e) {
      debugPrint(' Logout error: $e');
    }
  }
}
