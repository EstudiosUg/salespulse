import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) async {
    debugPrint('Notification tapped: ${response.payload}');

    // Check if payload is for opening email
    if (response.payload != null && response.payload!.startsWith('mailto:')) {
      try {
        final Uri emailUri = Uri.parse(response.payload!);
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Error opening email: $e');
      }
    }
  }

  /// Show a simple notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'salespulse_channel',
      'SalesPulse Notifications',
      channelDescription: 'Notifications for SalesPulse app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show progress notification (for downloads)
  static Future<void> showProgressNotification({
    required int id,
    required String title,
    required int progress,
    required int maxProgress,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      'salespulse_download_channel',
      'Download Progress',
      channelDescription: 'Shows download progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      onlyAlertOnce: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      'Downloading... ${((progress / maxProgress) * 100).toInt()}%',
      details,
    );
  }

  /// Show notification with action buttons
  static Future<void> showNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required String filePath,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      'salespulse_export_channel',
      'Export Notifications',
      channelDescription: 'Notifications for data exports',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      actions: [
        const AndroidNotificationAction(
          'open',
          'Open',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: filePath,
    );
  }

  /// Show email export notification that opens email app when tapped
  static Future<void> showEmailExportNotification({
    required int id,
    required String title,
    required String body,
    required String userEmail,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'salespulse_email_export_channel',
      'Email Export Notifications',
      channelDescription: 'Notifications for data exports sent via email',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
      actions: [
        AndroidNotificationAction(
          'open_email',
          'Open Email',
          showsUserInterface: true,
          icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use mailto URI as payload to open email app
    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: 'mailto:$userEmail',
    );
  }

  /// Cancel a notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
