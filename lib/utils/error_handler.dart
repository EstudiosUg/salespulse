import 'dart:io';

/// Utility class for handling and formatting errors in a user-friendly way
class ErrorHandler {
  /// Convert technical errors into user-friendly messages
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString();

    // Network connectivity errors
    if (error is SocketException || errorString.contains('SocketException')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (errorString.contains('Failed host lookup') ||
        errorString.contains('Connection refused') ||
        errorString.contains('Connection timed out')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    // HTTP timeout errors
    if (errorString.contains('TimeoutException') ||
        errorString.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    // Authentication errors
    if (errorString.contains('401') || errorString.contains('Unauthorized')) {
      return 'Session expired. Please login again.';
    }

    if (errorString.contains('403') || errorString.contains('Forbidden')) {
      return 'You don\'t have permission to perform this action.';
    }

    // Validation errors
    if (errorString.contains('422') ||
        errorString.contains('validation failed')) {
      return 'Invalid data. Please check your input and try again.';
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return 'Server error. Please try again later.';
    }

    if (errorString.contains('404') || errorString.contains('Not Found')) {
      return 'Requested data not found.';
    }

    // Remove technical jargon from error messages
    String cleanMessage = errorString
        .replaceAll('Exception: ', '')
        .replaceAll('Error: ', '')
        .replaceAll(RegExp(r'http[s]?://[^\s]+'), '[server]')
        .replaceAll(RegExp(r':\s*\d{3}'), '') // Remove status codes
        .replaceAll('Error fetching', 'Unable to load')
        .replaceAll('Error creating', 'Unable to create')
        .replaceAll('Error updating', 'Unable to update')
        .replaceAll('Error deleting', 'Unable to delete')
        .replaceAll('Failed to load', 'Unable to load')
        .replaceAll('Failed to create', 'Unable to create')
        .replaceAll('Failed to update', 'Unable to update')
        .replaceAll('Failed to delete', 'Unable to delete');

    // If the message is still too technical or contains "Exception", use a generic message
    if (cleanMessage.contains('Exception') ||
        cleanMessage.contains('Stack trace') ||
        cleanMessage.length > 100) {
      return 'An error occurred. Please try again.';
    }

    return cleanMessage.trim();
  }
}

