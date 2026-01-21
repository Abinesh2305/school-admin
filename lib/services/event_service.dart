import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../services/dio_client.dart';

class EventService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>?> getEvents() async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      final res = await _dio.post(
        'getevents',
        data: {'user_id': user['id'], 'api_token': token},
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } catch (e) {
      print("Event error: $e");
      return null;
    }
  }
}

