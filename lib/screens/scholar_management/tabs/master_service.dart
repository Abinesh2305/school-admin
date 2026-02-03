import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../infrastructure/storage/auth_storage_service.dart';
import '../models/master_item.dart';

class MasterService {
  final String path;
  final String masterKey;

  MasterService({
    required this.path,
    required this.masterKey,
  });

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

  /* ================= URI BUILDER ================= */

  Uri _buildUri({String? extraPath}) {
    final fullPath = extraPath == null
        ? path
        : '$path/$extraPath';

    return Uri.parse('$_baseUrl$fullPath');
  }

  /* ================= GET ALL ================= */

  Future<List<MasterItem>> getAll() async {
    final uri = _buildUri();

    print('MASTER GET → $uri');

    final res = await http.get(uri, headers: _headers);

    print('STATUS → ${res.statusCode}');
    print('BODY → ${res.body}');

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      final List list = body['items'] ?? [];

      return list
          .map((e) => MasterItem.fromJson(e))
          .toList();
    }

    throw Exception('Load failed (${res.statusCode})');
  }

  /* ================= ADD ================= */

  Future<void> add(String name) async {
    final uri = _buildUri();

    final body = {
      'name': name,
      'isActive': true,
      'sortOrder': 0,
    };

    print('ADD BODY → $body');

    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    print('ADD STATUS → ${res.statusCode}');
    print('ADD RESP → ${res.body}');

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        'Add failed (${res.statusCode}) → ${res.body}',
      );
    }
  }

  /* ================= UPDATE ================= */

  Future<void> update(int id, String name) async {
    final uri = _buildUri(extraPath: '$id');

    final res = await http.patch(
      uri,
      headers: _headers,
      body: jsonEncode({
        'name': name,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Update failed');
    }
  }

  /* ================= TOGGLE ================= */

  Future<void> toggle(int id, bool status) async {
    final uri = _buildUri(extraPath: '$id/active');

    final res = await http.patch(
      uri,
      headers: _headers,
      body: jsonEncode({
        'isActive': status,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Toggle failed');
    }
  }
}
