import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../screens/login_screen.dart';
import '../main.dart';
import 'mock_backend.dart';

class DioClient {
  // Using mock backend - no real API calls
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://mock-backend.local",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        // Mock backend interceptor - intercepts all requests
        onRequest: (options, handler) {
          // Add token to headers for consistency
          final box = Hive.box('settings');
          final token = box.get('token');

          if (token != null) {
            options.headers['x-api-key'] = token;
          }

          // Return mock response instead of making real API call
          Future.delayed(const Duration(milliseconds: 300), () {
            try {
              final mockResponse = MockBackend.getMockResponse(options);
              handler.resolve(mockResponse);
            } catch (e) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  error: e,
                  type: DioExceptionType.unknown,
                ),
              );
            }
          });
        },

        onResponse: (response, handler) {
          final msg = response.data?['message']?.toString() ?? '';

          if (_isInvalidTokenMessage(msg)) {
            _handleInvalidUser();
            return;
          }
          return handler.next(response);
        },

        onError: (DioException e, handler) {
          final msg = e.response?.data?['message']?.toString() ?? '';

          if (_isInvalidTokenMessage(msg)) {
            _handleInvalidUser();
            return;
          }
          return handler.next(e);
        },
      ),
    );

  static bool _isInvalidTokenMessage(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('invalid user') ||
        lower.contains('token') ||
        lower.contains('device changed');
  }

  static Future<void> _handleInvalidUser() async {
    try {
      final box = Hive.box('settings');
      await box.clear();

      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Navigator.of(ctx).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              onToggleTheme: () {},
              onToggleLanguage: () {},
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("⚠️ Logout redirect error: $e");
    }
  }
}
