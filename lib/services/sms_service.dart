import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dio_client.dart';

class SmsService {
  final Dio _dio = DioClient.dio;

  Future<List<dynamic>> getSMSCommunications({
    DateTime? fromDate,
    DateTime? toDate,
    dynamic category,
    String? type,
    String? search,
  }) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      if (user == null || token == null) {
        throw Exception("User not logged in");
      }

      final body = {
        "user_id": user['id'],
        "api_token": token,
        "page_no": 0,
        "search": search ?? "",
        "category_id": category != null ? category['id'] ?? 0 : 0,
        "sms_type": type ?? "",
        "from_date": fromDate != null
            ? "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}"
            : "",
        "to_date": toDate != null
            ? "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}"
            : "",
      };

      final response = await _dio.post(
        'getSMSCommunications',
        data: body,
        options: Options(headers: {'x-api-key': token}),
      );

      if (response.statusCode == 200) {
        final res = response.data;

        // Handle status 0 (no data) - return empty list instead of throwing
        if (res['status'] == 0) {
          return [];
        }

        // Handle successful response with data
        if (res['status'] == 1) {
          if (res['data'] is List) {
            return res['data'];
          }
          // If data is not a list, return empty list
          return [];
        }
      }

      // If we reach here, the response format is unexpected
      throw Exception("Failed to load SMS communications");
    } on DioException {
      // Re-throw DioExceptions so ErrorHandler can process them properly
      rethrow;
    } catch (e) {
      // Wrap other exceptions
      throw Exception("Failed to load SMS communications: $e");
    }
  }
}
