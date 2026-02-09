import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../infrastructure/storage/auth_storage_service.dart';


class StaffService {
  final _auth = AuthStorage();

  // BASE URL FROM ENV
  final String baseUrl = "${dotenv.env['BASE_URL']}staff/school";

  // ================= HEADERS =================

  Future<Map<String, String>> _headers() async {
    final token = AuthStorage.token;

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  // ================= GET STAFF =================

  Future<Map<String, dynamic>> getStaff({
    int page = 1,
    int pageSize = 20,
    bool? isActive,
  }) async {
    String url = "$baseUrl/staff?page=$page&pageSize=$pageSize";

    if (isActive != null) {
      url += "&isActive=$isActive";
    }

    final res = await http.get(Uri.parse(url), headers: await _headers());

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load staff");
    }
  }

  // ================= GET BY ID =================

  Future<Map<String, dynamic>> getById(int id) async {
    final res = await http.get(
      Uri.parse("$baseUrl/staff/$id"),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load staff");
    }
  }

  // ================= SAVE =================

  Future<Map<String, dynamic>> saveStaff(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/staff/save"),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Save failed");
    }
  }

  // ================= ACTIVE / DEACTIVE =================

  Future<void> setActive(int id, bool active) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/staff/$id/active"),
      headers: await _headers(),
      body: jsonEncode({"isActive": active}),
    );

    if (res.statusCode != 200) {
      throw Exception("Status update failed");
    }
  }
  // ================= ACADEMIC YEARS =================

  Future<List<dynamic>> getAcademicYears() async {
  final url =
      "${dotenv.env['BASE_URL']}schools/school/academic-years";

  final res = await http.get(
    Uri.parse(url),
    headers: await _headers(),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    // ✅ Extract items array
    return data['items'] as List;
  } else {
    throw Exception("Failed to load academic years");
  }
}


  // ================= ROLES =================

  Future<List<dynamic>> getRoles(int academicYearId) async {
  final url =
      "${dotenv.env['BASE_URL']}schools/school/roles?academicYearId=$academicYearId";

  final res = await http.get(
    Uri.parse(url),
    headers: await _headers(),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    // ✅ Extract items
    return data['items'] as List;
  } else {
    throw Exception("Failed to load roles");
  }
}

}
