import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../infrastructure/storage/auth_storage_service.dart';
import 'package:flutter/material.dart';

class CandidateService {
  final _auth = AuthStorage();

  final String baseUrl = "${dotenv.env['BASE_URL']}staff/school/candidates";

  // ================= HEADERS =================

  Future<Map<String, String>> _headers() async {
    final token = AuthStorage.token;

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  // ================= LIST =================

  Future<Map<String, dynamic>> getCandidates({
    String q = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = "$baseUrl?q=$q&page=$page&pageSize=$pageSize";

    final res = await http.get(Uri.parse(url), headers: await _headers());

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load candidates");
    }
  }

  // ================= GET BY ID =================

  Future<Map<String, dynamic>> getById(int id) async {
    final res = await http.get(
      Uri.parse("$baseUrl/$id"),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load candidate");
    }
  }

  // ================= SAVE =================

  Future<void> saveCandidate(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/save"),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception("Save failed");
    }
  }

  // ================= CONVERT =================

  Future<void> convertToStaff(Map<String, dynamic> data) async {
    final url = "$baseUrl/convert";

    debugPrint("CONVERT URL: $url");
    debugPrint("CONVERT BODY: $data");

    final res = await http.post(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    debugPrint("CONVERT STATUS: ${res.statusCode}");
    debugPrint("CONVERT RESPONSE: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Convert failed");
    }
  }

  // ================= DELETE =================

  Future<void> delete(int id) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception("Delete failed");
    }
  }
}
