import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../infrastructure/storage/auth_storage_service.dart';

class ShufflingService {
  /* ================= BASE URL ================= */

  String get _baseUrl {
    final base = dotenv.env['BASE_URL'];

    if (base == null || base.isEmpty) {
      throw Exception('BASE_URL not found in .env');
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
    return Uri.parse('${_baseUrl}scholars/school/shuffling');
  }

  /* ======================================================
                        PREVIEW
     ====================================================== */

  Future<Map<String, dynamic>> preview({
    required int fromClassId,
    required int fromSectionId,
    required int toClassId,
    required int toSectionId,
    required List<int> studentIds,
  }) async {
    final uri = Uri.parse('${_baseUri.toString()}/preview');

    final body = {
      "fromClassId": fromClassId,
      "fromSectionId": fromSectionId,
      "toClassId": toClassId,
      "toSectionId": toSectionId,
      "studentIds": studentIds,
    };

    print('SHUFFLE PREVIEW → $uri');
    print('BODY → $body');

    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    print('STATUS → ${res.statusCode}');
    print('RESP → ${res.body}');

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception('Preview failed (${res.statusCode}) → ${res.body}');
  }

  /* ======================================================
                        COMMIT
     ====================================================== */

  Future<Map<String, dynamic>> commit({
    required int fromClassId,
    required int fromSectionId,
    required int toClassId,
    required int toSectionId,
    required String reason,
    required List<int> studentIds,
  }) async {
    final uri = Uri.parse('${_baseUri.toString()}/commit');

    final body = {
      "fromClassId": fromClassId,
      "fromSectionId": fromSectionId,
      "toClassId": toClassId,
      "toSectionId": toSectionId,
      "reason": reason,
      "studentIds": studentIds,
    };

    print('SHUFFLE COMMIT → $uri');
    print('BODY → $body');

    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    print('STATUS → ${res.statusCode}');
    print('RESP → ${res.body}');

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception('Commit failed (${res.statusCode}) → ${res.body}');
  }

  /* ======================================================
                      GET BATCH STATUS
     ====================================================== */

  Future<Map<String, dynamic>> getBatch(int batchId) async {
    final uri = Uri.parse('${_baseUri.toString()}/batches/$batchId');

    print('SHUFFLE BATCH → $uri');

    final res = await http.get(uri, headers: _headers);

    print('STATUS → ${res.statusCode}');
    print('RESP → ${res.body}');

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception('Batch load failed (${res.statusCode}) → ${res.body}');
  }

  /* ======================================================
                      LIST BATCHES
     ====================================================== */

  Future<Map<String, dynamic>> getBatches({
    int page = 1,
    int pageSize = 20,
    String status = 'all',
  }) async {
    final uri = Uri.parse('${_baseUri.toString()}/batches').replace(
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
        'status': status,
      },
    );

    print('SHUFFLE BATCH LIST → $uri');

    final res = await http.get(uri, headers: _headers);

    print('STATUS → ${res.statusCode}');
    print('RESP → ${res.body}');

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception('Batch list failed (${res.statusCode}) → ${res.body}');
  }

  /* ======================================================
                    BATCH ITEMS
     ====================================================== */

  Future<Map<String, dynamic>> getBatchItems({
    required int batchId,
    int page = 1,
    int pageSize = 50,
    String status = 'all',
  }) async {
    final uri =
        Uri.parse('${_baseUri.toString()}/batches/$batchId/items').replace(
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
        'status': status,
      },
    );

    print('SHUFFLE BATCH ITEMS → $uri');

    final res = await http.get(uri, headers: _headers);

    print('STATUS → ${res.statusCode}');
    print('RESP → ${res.body}');

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception(
        'Batch items failed (${res.statusCode}) → ${res.body}');
  }
}
