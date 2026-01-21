import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

/// Storage service for managing local data persistence
class StorageService {
  static Box? _settingsBox;
  static Box? _pendingReadsBox;
  static Box? _pendingReadsHomeworkBox;

  /// Initialize storage boxes
  static Future<void> initialize() async {
    _settingsBox = await Hive.openBox(AppConstants.storageBoxSettings);
    _pendingReadsBox = await Hive.openBox(AppConstants.storageBoxPendingReads);
    _pendingReadsHomeworkBox = 
        await Hive.openBox(AppConstants.storageBoxPendingReadsHomework);
  }

  /// Get settings box (with fallback for hot reload)
  static Box get settingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      // Fallback for hot reload scenarios - Hive boxes persist across hot reloads
      _settingsBox = Hive.box(AppConstants.storageBoxSettings);
    }
    return _settingsBox!;
  }

  /// Get pending reads box (with fallback for hot reload)
  static Box get pendingReadsBox {
    if (_pendingReadsBox == null || !_pendingReadsBox!.isOpen) {
      // Fallback for hot reload scenarios
      _pendingReadsBox = Hive.box(AppConstants.storageBoxPendingReads);
    }
    return _pendingReadsBox!;
  }

  /// Get pending reads homework box (with fallback for hot reload)
  static Box get pendingReadsHomeworkBox {
    if (_pendingReadsHomeworkBox == null || !_pendingReadsHomeworkBox!.isOpen) {
      // Fallback for hot reload scenarios
      _pendingReadsHomeworkBox = Hive.box(AppConstants.storageBoxPendingReadsHomework);
    }
    return _pendingReadsHomeworkBox!;
  }

  /// Save user data
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await settingsBox.put(AppConstants.keyUser, user);
  }

  /// Get user data
  static Map<String, dynamic>? getUser() {
    return settingsBox.get(AppConstants.keyUser) as Map<String, dynamic>?;
  }

  /// Save token
  static Future<void> saveToken(String token) async {
    await settingsBox.put(AppConstants.keyToken, token);
  }

  /// Get token
  static String? getToken() {
    return settingsBox.get(AppConstants.keyToken) as String?;
  }

  /// Clear all data
  static Future<void> clearAll() async {
    await settingsBox.clear();
    await pendingReadsBox.clear();
    await pendingReadsHomeworkBox.clear();
  }

  /// Clear user data (logout)
  static Future<void> clearUserData() async {
    await settingsBox.delete(AppConstants.keyUser);
    await settingsBox.delete(AppConstants.keyToken);
  }
}

