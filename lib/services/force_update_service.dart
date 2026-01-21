import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/constants/api_endpoints.dart';
import 'dio_client.dart';

/// Service to handle force update checks and in-app updates
class ForceUpdateService {
  static bool _isChecking = false;
  
  /// Check if update is required from backend
  /// For admin app, force update check is optional and won't block the app
  static Future<ForceUpdateResult> checkForUpdate() async {
    if (_isChecking) {
      return ForceUpdateResult(updateRequired: false);
    }
    
    _isChecking = true;
    
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;
      
      // Check version from backend with timeout
      final response = await DioClient.dio.get(
        ApiEndpoints.appVersion,
        queryParameters: {
          'current_version': currentVersion,
          'build_number': buildNumber,
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Update check timeout');
        },
      );
      
      _isChecking = false;
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        // Handle both 'success' and 'status' response formats
        final isSuccess = responseData['success'] == true || responseData['status'] == 1;
        
        if (isSuccess) {
          final data = responseData['data'] ?? {};
          final updateRequired = data['force_update'] ?? false;
          final latestVersion = data['latest_version'] ?? currentVersion;
          final updateMessage = data['message'] ?? 'A new version is available. Please update to continue.';
          
          // For admin app, only show update if explicitly required
          // Don't block on version mismatch alone
          return ForceUpdateResult(
            updateRequired: updateRequired == true,
            latestVersion: latestVersion,
            message: updateMessage,
          );
        }
      }
      
      return ForceUpdateResult(updateRequired: false);
    } catch (e) {
      _isChecking = false;
      debugPrint('Error checking for update: $e');
      // On error, don't block the app - allow it to continue
      // This is especially important for admin app
      return ForceUpdateResult(updateRequired: false);
    }
  }
  
  /// Check and perform Google Play in-app update (Android only)
  static Future<AppUpdateResult?> checkAndPerformUpdate({
    required bool forceUpdate,
  }) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (forceUpdate && updateInfo.immediateUpdateAllowed) {
          // Force immediate update - blocks the app
          final result = await InAppUpdate.performImmediateUpdate();
          return result;
        } else if (updateInfo.flexibleUpdateAllowed) {
          // Flexible update - user can continue using app
          await InAppUpdate.startFlexibleUpdate();
          // Note: For flexible updates, you need to complete the update later
          // by calling InAppUpdate.completeFlexibleUpdate()
          return AppUpdateResult.inAppUpdateFailed;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error performing in-app update: $e');
      return AppUpdateResult.inAppUpdateFailed;
    }
  }
  
  /// Complete flexible update (call after flexible update downloads)
  static Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('Error completing flexible update: $e');
    }
  }
}

/// Result of force update check
class ForceUpdateResult {
  final bool updateRequired;
  final String? latestVersion;
  final String? message;
  
  ForceUpdateResult({
    required this.updateRequired,
    this.latestVersion,
    this.message,
  });
}
