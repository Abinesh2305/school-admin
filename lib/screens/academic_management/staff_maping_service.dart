import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../infrastructure/storage/auth_storage_service.dart';

class StaffMappingService {

  /* =====================================================
      BASE URL
  ===================================================== */

  static String get _baseUrl {
    final base = dotenv.env['BASE_URL'];

    if (base == null || base.isEmpty) {
      throw Exception('BASE_URL not found in .env');
    }

    return base.endsWith('/') ? base : '$base/';
  }

  /* =====================================================
      HEADERS
  ===================================================== */

  static Map<String, String> get _headers {

    final token = AuthStorage.token;

    if (token == null || token.isEmpty) {
      throw Exception('Auth token missing. Login again.');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /* =====================================================
      SAVE / UPDATE STAFF (WITH MAPPING)
  ===================================================== */

  static Future<Map<String, dynamic>> saveStaff({
    required Map<String, dynamic> data,
  }) async {

    final url = Uri.parse(
      '${_baseUrl}staff/school/staff/save',
    );

    debugPrint('SAVE STAFF → $url');
    debugPrint('DATA → ${jsonEncode(data)}');

    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(data),
    );

    return _handleResponse(res);
  }

  /* =====================================================
      GET STAFF MAPPINGS
  ===================================================== */

  static Future<Map<String, dynamic>> getStaffMappings({
    required int staffId,
  }) async {

    final url = Uri.parse(
      '${_baseUrl}staff/school/staff/$staffId/mappings',
    );

    debugPrint('GET STAFF MAPPINGS → $url');

    final res = await http.get(url, headers: _headers);

    return _handleResponse(res);
  }

  /* =====================================================
      RELIEVE STAFF
  ===================================================== */

  static Future<Map<String, dynamic>> relieveStaff({
    required int staffId,
    required int status,
    required String reason,
  }) async {

    final url = Uri.parse(
      '${_baseUrl}staff/school/staff/$staffId/relieve',
    );

    debugPrint('RELIEVE STAFF → $url');

    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        "status": status,
        "reason": reason,
      }),
    );

    return _handleResponse(res);
  }


  /* =====================================================
      RESPONSE HANDLER
  ===================================================== */

  static Map<String, dynamic> _handleResponse(http.Response res) {

    debugPrint('STATUS → ${res.statusCode}');
    debugPrint('BODY → ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }

    try {
      final body = jsonDecode(res.body);

      if (body is Map && body['message'] != null) {
        throw Exception(body['message']);
      }
    } catch (_) {}

    throw Exception(
      'API Error ${res.statusCode}: ${res.body}',
    );
  }

  /* ================= GET STAFF LIST ================= */

static Future<Map<String, dynamic>> getStaffList({
  int page = 1,
  int pageSize = 50,
}) async {

  final url = Uri.parse(
    '${_baseUrl}staff/school/staff'
    '?page=$page&pageSize=$pageSize',
  );

  debugPrint("GET STAFF LIST → $url");

  final res = await http.get(url, headers: _headers);

  return _handleResponse(res);
}


  /* ================= GET STAFF BY ID ================= */

static Future<Map<String, dynamic>> getStaffById(
  int staffId,
) async {

  final url = Uri.parse(
    '${_baseUrl}staff/school/staff/$staffId',
  );

  debugPrint("GET STAFF → $url");

  final res = await http.get(url, headers: _headers);

  return _handleResponse(res);
}
/* ================= GET EX EMPLOYEES ================= */

static Future<Map<String, dynamic>> getExEmployees({
  int page = 1,
  int pageSize = 20,
}) async {

  final url = Uri.parse(
    '${_baseUrl}staff/school/ex-employees'
    '?page=$page&pageSize=$pageSize',
  );

  debugPrint("GET EX EMPLOYEES → $url");

  final res = await http.get(url, headers: _headers);

  return _handleResponse(res);
}


}
