import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'notification_service.dart';

class FileDownloadService {
  static final Dio _dio = Dio();

  /// Download file from URL with progress notification
  static Future<String?> downloadFile({
    required String url,
    required String filename,
    String? authToken,
    Function(int, int)? onProgress,
  }) async {
    try {
      // No storage permission needed for app-specific directories

      // Get download directory
      final directory = await _getDownloadDirectory();
      final filePath = '${directory.path}/$filename';

      // Show progress notification
      const notificationId = 12345;
      await NotificationService.showProgressNotification(
        id: notificationId,
        title: 'Downloading $filename',
        progress: 0,
        maxProgress: 100,
      );

      // Configure Dio
      final options = Options(
        headers:
            authToken != null ? {'Authorization': 'Bearer $authToken'} : {},
        responseType: ResponseType.bytes,
      );

      // Download file
      await _dio.download(
        url,
        filePath,
        options: options,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = ((received / total) * 100).toInt();
            NotificationService.showProgressNotification(
              id: notificationId,
              title: 'Downloading $filename',
              progress: progress,
              maxProgress: 100,
            );
            onProgress?.call(received, total);
          }
        },
      );

      // Cancel progress notification
      await NotificationService.cancelNotification(notificationId);

      // Show completion notification
      await NotificationService.showNotificationWithActions(
        id: notificationId + 1,
        title: 'Download Complete',
        body: '$filename has been downloaded successfully',
        filePath: filePath,
      );

      return filePath;
    } catch (e) {
      await NotificationService.showNotification(
        id: 12346,
        title: 'Download Failed',
        body: 'Failed to download file: $e',
      );
      return null;
    }
  }

  /// Get appropriate download directory based on platform
  /// Uses app-specific directories that don't require storage permissions
  static Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Use app documents directory - no permissions required
      return await getApplicationDocumentsDirectory();
    } else {
      // For other platforms, try downloads directory first
      return await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }
  }

  /// Open downloaded file
  static Future<void> openFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception('Failed to open file: ${result.message}');
      }
    } catch (e) {
      throw Exception('Error opening file: $e');
    }
  }

  /// Check if file exists
  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// Delete file
  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Error deleting file: $e');
    }
  }

  /// Get file size
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Format file size to human readable
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
