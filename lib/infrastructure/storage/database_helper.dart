import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

/// SQLite database helper for managing app preferences
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _isInitializing = false;

  DatabaseHelper._init();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    
    // Prevent multiple simultaneous initializations
    if (_isInitializing) {
      // Wait a bit and retry
      await Future.delayed(const Duration(milliseconds: 100));
      return database;
    }
    
    try {
      _isInitializing = true;
      _database = await _initDB('app_preferences.db');
      return _database!;
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// Insert or update preference
  Future<int> insertOrUpdatePreference(String key, String value) async {
    try {
      final db = await database;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      return await db.insert(
        'preferences',
        {
          'key': key,
          'value': value,
          'updated_at': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to save preference: $e');
    }
  }

  /// Get preference value by key
  Future<String?> getPreference(String key) async {
    try {
      final db = await database;
      // Ensure database is open and ready
      if (!db.isOpen) {
        return null;
      }
      final result = await db.query(
        'preferences',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
      );

      if (result.isEmpty) return null;
      return result.first['value'] as String?;
    } catch (e) {
      // Return null on error, let the service handle default values
      debugPrint('Database query error: $e');
      return null;
    }
  }

  /// Delete preference by key
  Future<int> deletePreference(String key) async {
    final db = await database;
    return await db.delete(
      'preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  /// Get all preferences
  Future<Map<String, String>> getAllPreferences() async {
    final db = await database;
    final result = await db.query('preferences');

    return {
      for (var row in result) row['key'] as String: row['value'] as String
    };
  }

  /// Clear all preferences
  Future<int> clearAllPreferences() async {
    final db = await database;
    return await db.delete('preferences');
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

