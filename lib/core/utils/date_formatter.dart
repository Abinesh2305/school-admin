import 'package:intl/intl.dart';

/// Date formatting utilities
class DateFormatter {
  /// Format date to yyyy-MM-dd
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  /// Format date to yyyy-MM (for month-year)
  static String formatMonthYear(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }
  
  /// Format date to display format (e.g., "Jan 15, 2024")
  static String formatDisplayDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
  
  /// Format date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }
  
  /// Parse date from yyyy-MM-dd string
  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// Parse month-year from yyyy-MM string
  static DateTime? parseMonthYear(String monthYear) {
    try {
      return DateFormat('yyyy-MM').parse(monthYear);
    } catch (e) {
      return null;
    }
  }
  
  /// Get relative time (e.g., "2 days ago")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  /// Format notification date/time in 12-hour format (e.g., "Dec 15, 2024 03:45 PM")
  /// Tries to parse the date string from various formats (ISO8601, etc.)
  static String formatNotificationDateTime(String? dateString, {String? fallbackDateString}) {
    if (dateString == null || dateString.isEmpty) {
      // Try fallback if provided
      if (fallbackDateString != null && fallbackDateString.isNotEmpty) {
        return formatNotificationDateTime(fallbackDateString);
      }
      return '';
    }
    
    // If it's already a relative time string (like "3 days ago"), try to use fallback
    if (dateString.contains('ago') || dateString.contains('day') || dateString.contains('hour')) {
      if (fallbackDateString != null && fallbackDateString.isNotEmpty) {
        return formatNotificationDateTime(fallbackDateString);
      }
      return dateString; // Return as-is if no fallback
    }
    
    try {
      // Try parsing ISO8601 format (most common)
      DateTime? dateTime = DateTime.tryParse(dateString);
      
      // If parsing fails, try other common formats
      if (dateTime == null) {
        try {
          dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateString);
        } catch (e) {
          try {
            dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString);
          } catch (e2) {
            // If all parsing fails, return original string
            return dateString;
          }
        }
      }
      
      // Format in 12-hour format: "MMM dd, yyyy hh:mm a" (e.g., "Dec 15, 2024 03:45 PM")
      return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
    } catch (e) {
      // If formatting fails, return original string
      return dateString;
    }
  }
}

