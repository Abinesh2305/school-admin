import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../infrastructure/storage/auth_storage_service.dart';

class AcademicService {
  /* ================= BASE URL ================= */

  static String get _baseUrl {
    final base = dotenv.env['BASE_URL'];

    if (base == null || base.isEmpty) {
      throw Exception('BASE_URL not found in .env');
    }

    return base.endsWith('/') ? base : '$base/';
  }

  /* ================= HEADERS ================= */

  static Map<String, String> get _headers {
    final token = AuthStorage.token;

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please login again.');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /* =====================================================
      CLASS APIs
  ===================================================== */

  /// CREATE CLASS
  static Future<Map<String, dynamic>> createClass({
    required String name,
    required int sortOrder,
  }) async {
    final url = Uri.parse('${_baseUrl}academics/school/classes');

    debugPrint('CREATE CLASS → $url');

    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'name': name, 'sortOrder': sortOrder}),
    );

    return _handleResponse(res);
  }

  /// GET ALL CLASSES
  static Future<Map<String, dynamic>> getClasses({
    int page = 1,
    int pageSize = 50,
  }) async {
    final url = Uri.parse(
      '${_baseUrl}academics/school/classes'
      '?page=$page&pageSize=$pageSize',
    );

    debugPrint('GET CLASSES → $url');

    final res = await http.get(url, headers: _headers);

    return _handleResponse(res);
  }

  /// GET CLASS BY ID
  static Future<Map<String, dynamic>> getClassById(int classId) async {
    final url = Uri.parse('${_baseUrl}academics/school/classes/$classId');

    debugPrint('GET CLASS → $url');

    final res = await http.get(url, headers: _headers);

    return _handleResponse(res);
  }

  /// UPDATE CLASS
  static Future<Map<String, dynamic>> updateClass({
    required int classId,
    required String name,
    required int sortOrder,
  }) async {
    final url = Uri.parse('${_baseUrl}academics/school/classes/$classId');

    debugPrint('UPDATE CLASS → $url');

    final res = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({'name': name, 'sortOrder': sortOrder}),
    );

    return _handleResponse(res);
  }

  /* =====================================================
      SECTION APIs
  ===================================================== */

  /// CREATE SECTION
  static Future<Map<String, dynamic>> createSection({
    required int classId,
    required String name,
    required int sortOrder,
  }) async {
    final url = Uri.parse(
      '${_baseUrl}academics/school/classes/$classId/sections',
    );

    debugPrint('CREATE SECTION → $url');

    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'name': name, 'sortOrder': sortOrder}),
    );

    return _handleResponse(res);
  }

  /// GET SECTIONS BY CLASS
  static Future<Map<String, dynamic>> getSections({
    required int classId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final url = Uri.parse(
      '${_baseUrl}academics/school/classes/$classId/sections'
      '?page=$page&pageSize=$pageSize',
    );

    debugPrint('GET SECTIONS → $url');

    final res = await http.get(url, headers: _headers);

    return _handleResponse(res);
  }

  /// GET SECTION BY ID
  static Future<Map<String, dynamic>> getSectionById({
    required int classId,
    required int sectionId,
  }) async {
    final url = Uri.parse(
      '${_baseUrl}academics/school/classes/$classId/sections/$sectionId',
    );

    debugPrint('GET SECTION → $url');

    final res = await http.get(url, headers: _headers);

    return _handleResponse(res);
  }

  /// UPDATE SECTION
  static Future<Map<String, dynamic>> updateSection({
    required int classId,
    required int sectionId,
    required String name,
    required int sortOrder,
  }) async {
    final url = Uri.parse(
      '${_baseUrl}academics/school/classes/$classId/sections/$sectionId',
    );

    debugPrint('UPDATE SECTION → $url');

    final res = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({'name': name, 'sortOrder': sortOrder}),
    );

    return _handleResponse(res);
  }

  
  /// DELETE SECTION
  static Future<void> deleteSection({
    required int classId,
    required int sectionId,
  }) async {
    final url = Uri.parse(
      '${_baseUrl}academics/school/classes/$classId/sections/$sectionId',
    );

    debugPrint('DELETE SECTION → $url');

    final res = await http.delete(url, headers: _headers);

    debugPrint('STATUS → ${res.statusCode}');
    debugPrint('BODY → ${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Delete failed: ${res.body}');
    }
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

    throw Exception('API Error ${res.statusCode}: ${res.body}');
  }

  /* =====================================================
    CLASS DROPDOWN
===================================================== */

static Future<List<dynamic>> getClassDropdown({
  bool activeOnly = true,
}) async {
  final url = Uri.parse(
    '${_baseUrl}academics/school/classes/dropdown?activeOnly=$activeOnly',
  );

  debugPrint('GET CLASS DROPDOWN → $url');

  final res = await http.get(url, headers: _headers);

  debugPrint('STATUS → ${res.statusCode}');
  debugPrint('BODY → ${res.body}');

  if (res.statusCode >= 200 && res.statusCode < 300) {
    return jsonDecode(res.body);
  }

  throw Exception('Failed to load class dropdown');
}
/* ================= SUBJECT APIs ================= */

static Future<Map<String, dynamic>> getSubjects({
  int page = 1,
  int pageSize = 50,
}) async {
  final url = Uri.parse(
    '${_baseUrl}academics/school/subjects'
    '?page=$page&pageSize=$pageSize',
  );

  final res = await http.get(url, headers: _headers);

  return _handleResponse(res);
}



static Future<void> createSubject({
  required String name,
  required String code,
  required int sortOrder,
}) async {
  final url = Uri.parse('${_baseUrl}academics/school/subjects');

  debugPrint('CREATE SUBJECT → $url');

  final res = await http.post(
    url,
    headers: _headers,
    body: jsonEncode({
      "name": name,
      "code": code,
      "sortOrder": sortOrder,
    }),
  );

  _handleResponse(res);
}
static Future<void> applySubjectsToClasses({
  required List<int> classIds,
  required List<int> subjectIds,
}) async {
  final url = Uri.parse(
    '${_baseUrl}academics/school/mappings/subjects/apply-by-classes',
  );

  debugPrint('APPLY SUBJECT MAPPING → $url');

  final res = await http.post(
    url,
    headers: _headers,
    body: jsonEncode({
      "classIds": classIds,
      "subjectIds": subjectIds,
    }),
  );

  _handleResponse(res);
}
static Future<List<dynamic>> getSectionSubjects({
  required int classId,
  int page = 1,
  int pageSize = 50,
}) async {
  final url = Uri.parse(
    '${_baseUrl}academics/school/mappings/section-subjects'
    '?page=$page&pageSize=$pageSize&classId=$classId',
  );

  debugPrint('GET SECTION SUBJECTS → $url');

  final res = await http.get(url, headers: _headers);

  final data = _handleResponse(res);

  return data['items'] ?? [];
}
/* ================= SUBJECT DROPDOWN ================= */

static Future<List<dynamic>> getSubjectDropdown({
  bool activeOnly = true,
}) async {
  final url = Uri.parse(
    '${_baseUrl}academics/school/subjects/dropdown?activeOnly=$activeOnly',
  );

  debugPrint('GET SUBJECT DROPDOWN → $url');

  final res = await http.get(url, headers: _headers);

  debugPrint('STATUS → ${res.statusCode}');
  debugPrint('BODY → ${res.body}');

  if (res.statusCode >= 200 && res.statusCode < 300) {
    return jsonDecode(res.body);
  }

  throw Exception('Failed to load subject dropdown');
}
/* ================= SECTION SUBJECT MAPPINGS ================= */

static Future<Map<String, dynamic>> getSectionSubjectMappings({
  int page = 1,
  int pageSize = 50,
  int? classId,
}) async {
  final query = {
    'page': '$page',
    'pageSize': '$pageSize',
    if (classId != null) 'classId': '$classId',
  };

  final url = Uri.parse(
    '${_baseUrl}academics/school/mappings/section-subjects',
  ).replace(queryParameters: query);

  debugPrint('GET SECTION SUBJECT MAPPINGS → $url');

  final res = await http.get(url, headers: _headers);

  return _handleResponse(res);
}
static Future<void> mapSubjectToSection({
  required int classId,
  required int sectionId,
  required int subjectId,
}) async {

  final url = Uri.parse(
    '${_baseUrl}academics/school/mappings/section-subjects',
  );

  final res = await http.post(
    url,
    headers: _headers,
    body: jsonEncode({
      "classId": classId,
      "sectionId": sectionId,
      "subjectId": subjectId,
    }),
  );

  _handleResponse(res);
}
/* ================= APPLY SUBJECT BY SECTIONS ================= */

static Future<void> applySubjectsToSections({
  required List<int> sectionIds,
  required List<int> subjectIds,
}) async {

  final url = Uri.parse(
    '${_baseUrl}academics/school/mappings/subjects/apply-by-sections',
  );

  debugPrint('APPLY BY SECTIONS → $url');

  final res = await http.post(
    url,
    headers: _headers,
    body: jsonEncode({
      "sectionIds": sectionIds,
      "subjectIds": subjectIds,
    }),
  );

  _handleResponse(res);
}


}
