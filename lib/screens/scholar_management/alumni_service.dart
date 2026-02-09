import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../infrastructure/storage/auth_storage_service.dart';
import 'models/alumni_model.dart';

class AlumniService {
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
    return Uri.parse('${_baseUrl}scholars/school/alumni');
  }

  /* ======================================================
                        LIST ALUMNI
     ====================================================== */

  Future<List<Alumni>> getAll({
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = _baseUri.replace(
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
      },
    );

    print('ALUMNI LIST → $uri');

    final res = await http.get(uri, headers: _headers);

    print('STATUS → ${res.statusCode}');
    print('BODY → ${res.body}');

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      final List list = body['items'] ?? [];

      return list
          .map((e) => Alumni.fromJson(e))
          .toList();
    }

    throw Exception(
      'Load failed (${res.statusCode}) → ${res.body}',
    );
  }

  /* ======================================================
                        MARK ALUMNI
     ====================================================== */

  Future<void> mark({
    required List<int> ids,
    required String leavingDate,
    required String reason,
  }) async {
    final uri = Uri.parse('${_baseUri.toString()}/mark');

    final body = {
      "studentIds": ids,
      "leavingDate": leavingDate,
      "reason": reason,
    };

    print('ALUMNI MARK → $uri');
    print('BODY → $body');

    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    print('STATUS → ${res.statusCode}');
    print('RESP → ${res.body}');

    if (res.statusCode != 200) {
      throw Exception(
        'Mark failed (${res.statusCode}) → ${res.body}',
      );
    }
  }

  /* ======================================================
                        GET DETAILS
     ====================================================== */

  Future<Map<String, dynamic>> getDetails(int id) async {
    final uri = Uri.parse('${_baseUri.toString()}/$id');

    print('ALUMNI DETAIL → $uri');

    final res = await http.get(uri, headers: _headers);

    print('STATUS → ${res.statusCode}');
    print('RESP → ${res.body}');

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception(
      'Detail failed (${res.statusCode}) → ${res.body}',
    );
  }

  /* ======================================================
                        REVERT ALUMNI
     ====================================================== */

  Future<void> revert({
    required List<int> ids,
    required String reason,
  }) async {
    final uri = Uri.parse('${_baseUri.toString()}/revert');

    final body = {
      "studentIds": ids,
      "reason": reason,
    };

    print('ALUMNI REVERT → $uri');
    print('BODY → $body');

    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    print('STATUS → ${res.statusCode}');
    print('RESP → ${res.body}');

    if (res.statusCode != 200) {
      throw Exception(
        'Revert failed (${res.statusCode}) → ${res.body}',
      );
    }
  }
}
