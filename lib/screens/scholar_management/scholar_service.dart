import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../infrastructure/storage/auth_storage_service.dart';

import 'models/scholar_model.dart';
import 'models/scholar_lookup_model.dart';
import 'dart:io';

class ScholarService {
  /* ================= BASE URL ================= */

  String get _baseUrl {
    final base = dotenv.env['BASE_URL'];

    if (base == null || base.isEmpty) {
      throw Exception('BASE_URL missing in .env');
    }

    return base.endsWith('/') ? base : '$base/';
  }

  /* ================= HEADERS ================= */

  Map<String, String> get _headers {
    final token = AuthStorage.token;

    if (token == null || token.isEmpty) {
      throw Exception('User not logged in');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /* ================= BASE URI ================= */

  Uri get _baseUri {
    return Uri.parse('${_baseUrl}scholars/school/scholars');
  }

  /* ======================================================
                        GET ALL
     ====================================================== */

      Future<List<Scholar>> getAll({
      int page = 1,
      int pageSize = 50,
       String? search,
       }) async {
        final uri = _baseUri.replace(
         queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (search != null && search.isNotEmpty) 'q': search,
      },
    );

    debugPrint('SCHOLAR LIST → $uri');

    final res = await http.get(uri, headers: _headers);

    debugPrint('STATUS → ${res.statusCode}');

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      final List list = body['items'] ?? [];

      return list.map((e) => Scholar.fromJson(e)).toList();
    }

    throw _error(res, 'Load failed');
  }

  /* ======================================================
                        GET BY ID
     ====================================================== */

  Future<Scholar> getById(int id) async {
    final uri = Uri.parse('${_baseUri.toString()}/$id');

    debugPrint('SCHOLAR GET → $uri');

    final res = await http.get(uri, headers: _headers);

    debugPrint('STATUS → ${res.statusCode}');

    if (res.statusCode == 200) {
      return Scholar.fromJson(jsonDecode(res.body));
    }

    throw _error(res, 'Detail load failed');
  }

  /* ======================================================
                        CREATE
     ====================================================== */

  Future<Scholar> create(Scholar scholar) async {
    final uri = _baseUri;

    debugPrint('SCHOLAR CREATE → $uri');

    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(scholar.toJson()),
    );

    debugPrint('STATUS → ${res.statusCode}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      return Scholar.fromJson(jsonDecode(res.body));
    }

    throw _error(res, 'Create failed');
  }

  /* ======================================================
                        UPDATE
     ====================================================== */

  Future<Scholar> update(int id, Scholar scholar) async {
    final uri = Uri.parse('${_baseUri.toString()}/$id');

    debugPrint('SCHOLAR UPDATE → $uri');

    final res = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(scholar.toJson()),
    );

    debugPrint('STATUS → ${res.statusCode}');

    if (res.statusCode == 200) {
      return Scholar.fromJson(jsonDecode(res.body));
    }

    throw _error(res, 'Update failed');
  }

  /* ======================================================
                        DELETE
     ====================================================== */

  Future<void> delete(int id) async {
    final uri = Uri.parse('${_baseUri.toString()}/$id');

    debugPrint('SCHOLAR DELETE → $uri');

    final res = await http.delete(uri, headers: _headers);

    debugPrint('STATUS → ${res.statusCode}');

    if (res.statusCode == 200 || res.statusCode == 204) return;

    throw _error(res, 'Delete failed');
  }

  /* ======================================================
                        LOOKUP
     ====================================================== */

  Future<List<ScholarLookup>> lookup({
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('${_baseUri.toString()}/lookup').replace(
      queryParameters: {'q': query, 'page': '$page', 'pageSize': '$pageSize'},
    );

    debugPrint('SCHOLAR LOOKUP → $uri');

    final res = await http.get(uri, headers: _headers);

    debugPrint('STATUS → ${res.statusCode}');

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      final List list = body['items'] ?? [];

      return list.map((e) => ScholarLookup.fromJson(e)).toList();
    }

    throw _error(res, 'Lookup failed');
  }

  /* ======================================================
                    LOOKUP BY IDS
     ====================================================== */

  Future<List<ScholarLookup>> lookupByIds(List<int> ids) async {
    final uri = Uri.parse('${_baseUri.toString()}/lookup/by-ids');

    debugPrint('SCHOLAR LOOKUP IDS → $uri');
    debugPrint('IDS → $ids');

    final res = await http.post(uri, headers: _headers, body: jsonEncode(ids));

    debugPrint('STATUS → ${res.statusCode}');

    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);

      return list.map((e) => ScholarLookup.fromJson(e)).toList();
    }

    throw _error(res, 'Lookup by ids failed');
  }

  /* ======================================================
                      ERROR HELPER
     ====================================================== */

  Exception _error(http.Response res, String prefix) {
    try {
      final body = jsonDecode(res.body);

      if (body is Map && body['message'] != null) {
        return Exception('$prefix: ${body['message']}');
      }
    } catch (_) {}

    return Exception('$prefix (${res.statusCode})');
  }
  /* ======================================================
                  PHOTO → PRESIGN
   ====================================================== */

  Future<Map<String, String>> getPhotoUploadUrl({
    required String admissionNo,
    required String fileName,
    required String contentType,
  }) async {
    final uri = Uri.parse('${_baseUrl}scholars/school/photos/presign');

    final body = {
      'admissionNo': admissionNo,
      'fileName': fileName,
      'contentType': contentType,
    };

    print('PHOTO PRESIGN → $uri');
    print('BODY → $body');

    final res = await http.post(uri, headers: _headers, body: jsonEncode(body));

    print('STATUS → ${res.statusCode}');
    print('RESP → ${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      return {'uploadUrl': data['uploadUrl'], 'key': data['key']};
    }

    throw Exception('Photo presign failed (${res.statusCode}) → ${res.body}');
  }

 
  /* ======================================================
          FULL PHOTO UPLOAD FLOW (FINAL)
    ====================================================== */

    Future<String> uploadScholarPhoto({
    required File file,
    required String admissionNo,
     }) async {
    final fileName = '$admissionNo.jpg';

    //  Get Presign URL
    final presign = await getPhotoUploadUrl(
      admissionNo: admissionNo,
      fileName: fileName,
      contentType: 'image/jpeg',
    );

    final uploadUrl = presign['uploadUrl']!;
    final key = presign['key']!;

    //  Upload to S3
    await uploadPhoto(
      uploadUrl: uploadUrl,
      file: file,
      contentType: 'image/jpeg',
    );

    debugPrint('PHOTO UPLOADED → $key');

    //  Map to Scholar
    final jobId = await mapPhotoToScholar(admissionNo: admissionNo, key: key);

    debugPrint('PHOTO MAP JOB ID → $jobId');

    //  Wait for job to complete
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 2));

      final done = await checkPhotoJob(jobId);

      if (done) {
        debugPrint('PHOTO JOB COMPLETED');
        break;
      }
    }

    // Return public URL
    return 'https://clasteq-multischool-dev-assets.s3.eu-north-1.amazonaws.com/$key';
  }

  /* ======================================================
                UPLOAD PHOTO TO S3
   ====================================================== */

  Future<void> uploadPhoto({
    required String uploadUrl,
    required File file,
    required String contentType,
  }) async {
    final uri = Uri.parse(uploadUrl);

    final bytes = await file.readAsBytes();

    final request = http.Request('PUT', uri);

    request.bodyBytes = bytes;

    request.headers.addAll({
      'Content-Type': contentType,
      'Content-Length': bytes.length.toString(),
    });

    //  Important: disable redirect following
    request.followRedirects = false;

    final response = await request.send();

    final status = response.statusCode;

    print('PHOTO UPLOAD STATUS → $status');

    if (status != 200 && status != 201) {
      final body = await response.stream.bytesToString();

      print('PHOTO UPLOAD ERROR → $body');

      throw Exception('Photo upload failed ($status)');
    }
  }
  /* ======================================================
            MAP PHOTO TO SCHOLAR
====================================================== */

  Future<int> mapPhotoToScholar({
    required String admissionNo,
    required String key,
  }) async {
    final uri = Uri.parse('${_baseUrl}scholars/school/photos/bulk-map/enqueue');

    final body = {
      'items': [
        {'admissionNo': admissionNo, 'photoKey': key},
      ],
    };

    final res = await http.post(uri, headers: _headers, body: jsonEncode(body));

    debugPrint('PHOTO MAP STATUS → ${res.statusCode}');
    debugPrint('PHOTO MAP RESP → ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);

      return data['id']; // jobId
    }

    throw Exception('Photo mapping failed → ${res.body}');
  }
  /* ======================================================
              CHECK JOB STATUS
====================================================== */

  Future<bool> checkPhotoJob(int jobId) async {
    final uri = Uri.parse('${_baseUrl}jobs/$jobId');

    final res = await http.get(uri, headers: _headers);

    debugPrint('JOB STATUS → ${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      return data['status'] == 'Succeeded';
    }

    throw Exception('Job check failed → ${res.body}');
  }
}
