import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/subject_model.dart';
import 'package:ClasteqSMS/infrastructure/storage/auth_storage_service.dart';

class SubjectService {
  final _auth = AuthStorage();

  final String baseUrl =
      "${dotenv.env['BASE_URL']}academics/school/subjects";

  // ================= HEADERS =================

  Future<Map<String, String>> _headers() async {
    final token = AuthStorage.token;

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  // ================= GET SUBJECTS (LIST) =================

  Future<Map<String, dynamic>> getSubjects({
    int page = 1,
    int pageSize = 20,
  }) async {
    final url =
        "$baseUrl?page=$page&pageSize=$pageSize";

    final res = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load subjects");
    }
  }

  // ================= GET BY ID =================

  Future<Subject> getById(int id) async {
    final res = await http.get(
      Uri.parse("$baseUrl/$id"),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      return Subject.fromJson(jsonDecode(res.body));
    } else {
      throw Exception("Failed to load subject");
    }
  }

  // ================= ADD =================

  Future<void> createSubject(Subject subject) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode(subject.toJson()),
    );

    if (res.statusCode != 200) {
      throw Exception("Create failed");
    }
  }

  // ================= UPDATE =================

  Future<void> updateSubject(int id, Subject subject) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/$id"),
      headers: await _headers(),
      body: jsonEncode(subject.toJson()),
    );

    if (res.statusCode != 200) {
      throw Exception("Update failed");
    }
  }

  // ================= DROPDOWN =================

  Future<List<dynamic>> getDropdown({bool activeOnly = true}) async {
    final url =
        "$baseUrl/dropdown?activeOnly=$activeOnly";

    final res = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Dropdown failed");
    }
  }

  // ================= ACTIVE / DEACTIVE =================

  Future<void> setActive(int id, bool isActive) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/$id/active"),
      headers: await _headers(),
      body: jsonEncode({
        "isActive": isActive,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Active update failed");
    }
  }
}
