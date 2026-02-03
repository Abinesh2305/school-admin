import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

class AuthStorage {
  static final _box = Hive.box('settings');

  // ================= TOKEN =================

  static String? get token => _box.get('token');

  static Future<void> saveToken(String token) async {
    await _box.put('token', token);
  }

  // ================= REFRESH TOKEN =================

  static String? get refreshToken => _box.get('refresh_token');

  static Future<void> saveRefreshToken(String token) async {
    await _box.put('refresh_token', token);
  }

  // ================= SESSION =================

  static String? get sessionId => _box.get('session_id');

  static Future<void> saveSessionId(String id) async {
    await _box.put('session_id', id);
  }

  // ================= SCHOOL =================

  static int? get schoolId => _box.get('school_id');

  static Future<void> saveSchoolId(int id) async {
    await _box.put('school_id', id);
  }

  // ================= SAVE ALL =================

  static Future<void> saveAll({
    required String token,
    required String refreshToken,
    required String sessionId,
    required int schoolId,
  }) async {
    await _box.put('token', token);
    await _box.put('refresh_token', refreshToken);
    await _box.put('session_id', sessionId);
    await _box.put('school_id', schoolId);
  }

  // ================= DEBUG =================

  static void debugPrintAuth() {
    debugPrint("🔐 AUTH STORAGE");
    debugPrint("TOKEN   : ${token != null}");
    debugPrint("REFRESH : ${refreshToken != null}");
    debugPrint("SESSION : ${sessionId != null}");
    debugPrint("SCHOOL  : $schoolId");
  }

  // ================= CLEAR =================

  static Future<void> clear() async {
    await _box.delete('token');
    await _box.delete('refresh_token');
    await _box.delete('session_id');
    await _box.delete('school_id');
  }
}
