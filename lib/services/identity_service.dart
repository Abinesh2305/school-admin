import 'package:flutter/material.dart';
import 'dio_client.dart';

class IdentityService {
  Future<void> ping() async {
    try {
      final res = await DioClient.dio.get('identity/ping');

      debugPrint(' PING STATUS → ${res.statusCode}');
      debugPrint(' PING RESPONSE → ${res.data}');
    } catch (e) {
      debugPrint(' PING ERROR → $e');
    }
  }
}
