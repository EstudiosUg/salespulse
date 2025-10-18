import 'dart:developer' as developer;

/// API Configuration
///
/// This file contains all API-related configuration.
/// Change these values based on your environment (development, production, etc.)
class ApiConfig {
  // ==========================================================================
  // IMPORTANT: Change these URLs based on your environment
  // ==========================================================================

  /// Base URL for the Laravel backend API
  ///
  /// Development (Local):
  /// - Use your local machine IP (e.g., 'http://192.168.1.100:8000')
  /// - Or use localhost if running emulator: 'http://10.0.2.2:8000'
  ///
  /// Production:
  /// - Use your production domain (e.g., 'https://api.salespulse.com')
  static const String baseUrl = 'https://salespulse.estudios.ug';

  /// API endpoint path (usually '/api')
  static const String apiPath = '/api';

  /// Storage path for uploaded files (avatars, exports, etc.)
  static const String storagePath = '/storage';

  // ==========================================================================
  // Computed URLs (Don't modify these)
  // ==========================================================================

  /// Full API URL (base + api path)
  static String get apiUrl => '$baseUrl$apiPath';

  /// Full storage URL (base + storage path)
  static String get storageUrl => '$baseUrl$storagePath';

  // ==========================================================================
  // API Settings
  // ==========================================================================

  /// Request timeout duration in seconds
  static const int timeoutSeconds = 30;

  /// Enable debug mode (prints API requests/responses)
  static const bool debugMode = true;

  // ==========================================================================
  // Helper Methods
  // ==========================================================================

  /// Get avatar URL for a given filename
  static String getAvatarUrl(String filename) {
    return '$storageUrl/avatars/$filename';
  }

  /// Get export file URL
  static String getExportUrl(String filename) {
    return '$storageUrl/exports/$filename';
  }

  /// Print current configuration (useful for debugging)
  static void printConfig() {
    if (debugMode) {
      developer.log('=== API Configuration ===', name: 'ApiConfig');
      developer.log('Base URL: $baseUrl', name: 'ApiConfig');
      developer.log('API URL: $apiUrl', name: 'ApiConfig');
      developer.log('Storage URL: $storageUrl', name: 'ApiConfig');
      developer.log('Timeout: ${timeoutSeconds}s', name: 'ApiConfig');
      developer.log('========================', name: 'ApiConfig');
    }
  }
}
