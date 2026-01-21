import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../services/dio_client.dart';
import '../core/utils/error_handler.dart';
import '../core/constants/app_constants.dart';

class ContactsService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>?> getContactsList() async {
    try {
      final box = Hive.box(AppConstants.storageBoxSettings);
      final user = box.get(AppConstants.keyUser);
      final token = box.get(AppConstants.keyToken);

      if (user == null || token == null) {
        ErrorHandler.logError(
          context: 'ContactsService.getContactsList',
          error: 'User not logged in',
        );
        return null;
      }

      final res = await _dio.post(
        'getcontactslist',
        data: {
          'user_id': user['id'],
          'api_token': token,
          'school_id': user['school_college_id'],
        },
        options: Options(headers: {AppConstants.headerApiKey: token}),
      );

      return res.data as Map<String, dynamic>?;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        context: 'ContactsService.getContactsList',
        error: e,
        stackTrace: stackTrace,
        additionalInfo: {'endpoint': 'getcontactslist'},
      );
      rethrow; // Let the screen handle the error
    }
  }
}
