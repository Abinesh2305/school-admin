import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'error_codes.dart';

/// Error handler utility for consistent error handling across the app
class ErrorHandler {
  /// Log error details
  static void logError({
    required String context,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) {
    final errorDetails = StringBuffer();
    errorDetails.writeln('=== ERROR LOG ===');
    errorDetails.writeln('Context: $context');
    errorDetails.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
    
    if (error is DioException) {
      errorDetails.writeln('Error Type: DioException');
      errorDetails.writeln('Status Code: ${error.response?.statusCode ?? 'N/A'}');
      errorDetails.writeln('Error Message: ${error.message}');
      errorDetails.writeln('Request Path: ${error.requestOptions.path}');
      errorDetails.writeln('Request Method: ${error.requestOptions.method}');
      errorDetails.writeln('Request Data: ${error.requestOptions.data}');
      errorDetails.writeln('Response Data: ${error.response?.data}');
      errorDetails.writeln('Error Type: ${error.type}');
    } else if (error is SocketException) {
      errorDetails.writeln('Error Type: SocketException');
      errorDetails.writeln('Message: ${error.message}');
    } else if (error is TimeoutException) {
      errorDetails.writeln('Error Type: TimeoutException');
      errorDetails.writeln('Message: ${error.message}');
    } else {
      errorDetails.writeln('Error Type: ${error.runtimeType}');
      errorDetails.writeln('Error: $error');
    }
    
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      errorDetails.writeln('Additional Info: $additionalInfo');
    }
    
    if (stackTrace != null) {
      errorDetails.writeln('Stack Trace:');
      errorDetails.writeln(stackTrace.toString());
    }
    
    errorDetails.writeln('================');
    
    // In debug mode, print to console; in production, this could be sent to a logging service
    if (kDebugMode) {
      debugPrint(errorDetails.toString());
    } else {
      // In production, you could send to crash reporting service like Firebase Crashlytics
      print(errorDetails.toString());
    }
  }

  /// Get user-friendly error message with error code
  static String getErrorMessage(dynamic error, {String? defaultMessage}) {
    final errorCode = ErrorCodes.getErrorCode(error);
    final userMessage = ErrorCodes.getUserMessage(errorCode);
    return '$errorCode - $userMessage';
  }

  /// Get error code from error
  static String getErrorCode(dynamic error) {
    return ErrorCodes.getErrorCode(error);
  }

  /// Check if error is a network error
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    return error is SocketException || error is TimeoutException;
  }

  /// Handle API response and extract data safely
  static ApiResponseResult handleApiResponse(Map<String, dynamic>? response) {
    if (response == null) {
      return ApiResponseResult(
        success: false,
        data: null,
        message: 'No response from server',
        errorCode: 'NO_RESPONSE',
      );
    }

    final status = response['status'];
    final message = response['message']?.toString() ?? 'Unknown error';
    final data = response['data'];

    if (status == 1 || status == true) {
      return ApiResponseResult(
        success: true,
        data: data,
        message: message,
      );
    } else {
      return ApiResponseResult(
        success: false,
        data: data,
        message: message,
        errorCode: 'API_ERROR',
      );
    }
  }

  /// Extract list from API response safely
  static List<dynamic> extractList(dynamic data, {String? key}) {
    if (data == null) return [];
    
    dynamic target = data;
    if (key != null && data is Map) {
      target = data[key];
    }
    
    if (target is List) return target;
    if (target is Map) {
      // If data is a Map but we expected a List, return empty
      return [];
    }
    return [];
  }
}

/// Result class for API response handling
class ApiResponseResult {
  final bool success;
  final dynamic data;
  final String message;
  final String? errorCode;

  ApiResponseResult({
    required this.success,
    this.data,
    required this.message,
    this.errorCode,
  });
}

