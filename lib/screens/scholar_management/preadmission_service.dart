import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../infrastructure/storage/auth_storage_service.dart';
import 'models/preadmission_model.dart';

class PreadmissionService {
  /* ================= BASE URL ================= */

  String get _baseUrl {
    final base = dotenv.env['BASE_URL'];

    if (base == null || base.isEmpty) {
      throw Exception('BASE_URL not found');
    }

    return base.endsWith('/') ? base : '$base/';
  }

  /* ================= HEADERS ================= */

  Map<String, String> get _headers {
    final token = AuthStorage.token;

    if (token == null || token.isEmpty) {
      throw Exception('Not logged in');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /* ================= BASE URI ================= */

  Uri get _baseUri {
    return Uri.parse('${_baseUrl}scholars/school/preadmissions');
  }

  /* ======================================================
                        LIST
     ====================================================== */

  Future<List<Preadmission>> getAll({
    int page = 1,
    int pageSize = 20,
    String status = 'all',
  }) async {
    final uri = _baseUri.replace(
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
        'status': status,
      },
    );

    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List list = body['items'] ?? [];

      return list.map((e) => Preadmission.fromJson(e)).toList();
    }

    throw Exception('Load failed (${res.statusCode})');
  }

  /* ======================================================
                        CREATE
     ====================================================== */

  Future<Preadmission> create(Preadmission p) async {
    final res = await http.post(
      _baseUri,
      headers: _headers,
      body: jsonEncode(p.toCreateJson()),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return Preadmission.fromJson(jsonDecode(res.body));
    }

    throw Exception('Create failed → ${res.body}');
  }

  /* ======================================================
                    CONVERT FORM
     ====================================================== */

  Future<Map<String, dynamic>> getConvertForm(int id) async {
  final uri = Uri.parse('${_baseUri.toString()}/$id/convert-form');

  print("URL = $uri");

  final res = await http.get(uri, headers: _headers);

  print("STATUS = ${res.statusCode}");
  print("BODY = ${res.body}");

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }

  throw Exception(
    'Convert-form failed (${res.statusCode}) → ${res.body}',
  );
}




  /* ======================================================
                        CONVERT
     ====================================================== */

  Future<Map<String, dynamic>> convert({
    required int id,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${_baseUri.toString()}/$id/convert');

    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception('Convert failed → ${res.body}');
  }
  /* ======================================================
                    CREATE (RAW FULL DATA)
   ====================================================== */

Future<void> createRaw(Map<String, dynamic> body) async {

  final res = await http.post(
    _baseUri,
    headers: _headers,
    body: jsonEncode(body),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception('Create failed → ${res.body}');
  }
}

}
