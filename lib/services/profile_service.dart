import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../services/dio_client.dart';

class ProfileService {
  final Dio _dio = DioClient.dio;

  /// ===============================
  /// FETCH PROFILE
  /// GET /api/identity/superadmin/me
  /// ===============================
  Future<Map<String, dynamic>?> getProfileDetails() async {
    try {
      final box = Hive.box('settings');
      final token = box.get('token');

      if (token == null) throw Exception('Not logged in');

      final res = await _dio.get(
        '/api/identity/superadmin/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.data is Map<String, dynamic>) {
        await box.put('user', res.data);
        return {'status': 1, 'data': res.data};
      }
    } catch (e) {
      print('⚠️ getProfileDetails error: $e');
    }
    return null;
  }

  /// ===============================
  /// UPDATE ALTERNATE MOBILE
  /// (TEMP: LOCAL ONLY – backend API missing)
  /// ===============================
  Future<Map<String, dynamic>?> updateAlternateMobile({
    required String mobile1,
  }) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');

      if (user == null) throw Exception('User missing');

      user['mobile1'] = mobile1;
      await box.put('user', user);

      return {'status': 1, 'message': 'Alternate mobile updated locally'};
    } catch (e) {
      print('⚠️ updateAlternateMobile error: $e');
      return {'status': 0, 'message': 'Update failed'};
    }
  }

  /// ===============================
  /// CHANGE PASSWORD
  /// (Backend API NOT AVAILABLE)
  /// ===============================
  Future<Map<String, dynamic>?> changePassword(String newPassword) async {
    return {'status': 0, 'message': 'Change password API not available'};
  }

  /// ===============================
  /// LOGOUT
  /// POST /api/identity/superadmin/logout
  /// ===============================
  Future<bool> logout() async {
    try {
      final box = Hive.box('settings');
      final token = box.get('token');

      if (token != null) {
        await _dio.post(
          '/api/identity/superadmin/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }

      await box.clear();
      return true;
    } catch (e) {
      print(' logout error: $e');
      return false;
    }
  }
}
