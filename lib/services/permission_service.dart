import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all necessary permissions on first launch
  static Future<Map<String, bool>> requestInitialPermissions() async {
    final Map<String, bool> results = {};

    // Request notification permission
    final notificationStatus = await _requestNotificationPermission();
    results['notification'] = notificationStatus;

    return results;
  }


  /// Request notification permission
  static Future<bool> _requestNotificationPermission() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }


  /// Check if notification permission is granted
  static Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  /// Show dialog explaining why permissions are needed
  static Future<void> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Open app settings
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Request specific permission with rationale
  static Future<bool> requestPermissionWithRationale(
    BuildContext context,
    Permission permission,
    String rationale,
  ) async {
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied && context.mounted) {
      // Show rationale dialog
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: Text(rationale),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Grant'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        final result = await permission.request();
        return result.isGranted;
      }
    }

    if (status.isPermanentlyDenied && context.mounted) {
      // Show dialog to open settings
      await showPermissionDialog(
        context,
        title: 'Permission Permanently Denied',
        message: 'Please enable this permission from app settings.',
        onConfirm: () => openSettings(),
      );
    }

    return false;
  }
}
