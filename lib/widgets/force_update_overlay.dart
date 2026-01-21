import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/force_update_service.dart';

/// Overlay widget that blocks the app and forces user to update
class ForceUpdateOverlay extends StatefulWidget {
  final String message;
  final String latestVersion;

  const ForceUpdateOverlay({
    super.key,
    required this.message,
    required this.latestVersion,
  });

  @override
  State<ForceUpdateOverlay> createState() => _ForceUpdateOverlayState();
}

class _ForceUpdateOverlayState extends State<ForceUpdateOverlay> {
  bool _isUpdating = false;
  String _statusMessage = 'Checking for updates...';

  @override
  void initState() {
    super.initState();
    _checkForInAppUpdate();
  }

  Future<void> _checkForInAppUpdate() async {
    setState(() {
      _isUpdating = true;
      _statusMessage = 'Checking for updates...';
    });

    try {
      // Try to perform in-app update (Android only)
      final result = await ForceUpdateService.checkAndPerformUpdate(
        forceUpdate: true,
      );

      if (result == AppUpdateResult.success) {
        // Update completed successfully
        setState(() {
          _statusMessage = 'Update completed successfully!';
        });
      } else if (result == AppUpdateResult.inAppUpdateFailed) {
        // In-app update failed or not available, show manual update option
        setState(() {
          _isUpdating = false;
          _statusMessage = 'Please update the app from the Play Store';
        });
      } else {
        // Update in progress
        setState(() {
          _statusMessage = 'Update in progress...';
        });
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
        _statusMessage = 'Please update the app from the Play Store';
      });
    }
  }

  Future<void> _openPlayStore() async {
    try {
      // Get package name dynamically
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;
      final playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageName';
      
      final uri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please update the app manually from the Play Store'),
            ),
          );
        }
      }
    } catch (e) {
      // If opening store fails, show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please update the app manually from the Play Store'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button - force update is mandatory
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon/Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Update Required',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  widget.message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Version info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Version ${widget.latestVersion} is now available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Status message
                if (_isUpdating)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else
                  // Update button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openPlayStore,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Update Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Info text
                Text(
                  'You cannot use the app until you update to the latest version.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

