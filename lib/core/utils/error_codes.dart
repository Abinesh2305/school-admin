import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:async';

/// Error code constants for user-facing error messages
/// These codes help developers identify issues without exposing technical details to users
class ErrorCodes {
  // Network/Connection Errors (400-499)
  static const String networkTimeout = '401';
  static const String networkConnection = '402';
  static const String networkSlow = '403';
  static const String networkUnavailable = '404';
  
  // Server Errors (500-599)
  static const String serverError = '501';
  static const String serverUnavailable = '502';
  static const String serverTimeout = '503';
  
  // Authentication Errors (600-699)
  static const String unauthorized = '601';
  static const String sessionExpired = '602';
  static const String invalidCredentials = '603';
  
  // Data Errors (700-799)
  static const String dataNotFound = '701';
  static const String dataInvalid = '702';
  static const String dataLoadFailed = '703';
  
  // Generic Errors (800-899)
  static const String unknownError = '801';
  static const String operationFailed = '802';
  static const String serviceUnavailable = '803';
  
  /// Get user-friendly message for error code
  static String getUserMessage(String code) {
    switch (code) {
      case networkTimeout:
      case networkConnection:
      case networkSlow:
      case networkUnavailable:
        return 'Unable to load the message right now due to low internet speed. Please retry in a few minutes.';
      
      case serverError:
      case serverUnavailable:
      case serverTimeout:
        return 'Unable to load the message right now due to low internet speed. Please retry in a few minutes.';
      
      case unauthorized:
      case sessionExpired:
        return 'Your session has expired. Please login again.';
      
      case invalidCredentials:
        return 'Invalid credentials. Please check your login details.';
      
      case dataNotFound:
        return 'The requested information could not be found.';
      
      case dataInvalid:
      case dataLoadFailed:
        return 'Unable to load the message right now due to low internet speed. Please retry in a few minutes.';
      
      case unknownError:
      case operationFailed:
      case serviceUnavailable:
      default:
        return 'Unable to load the message right now due to low internet speed. Please retry in a few minutes.';
    }
  }
  
  /// Get error code from exception
  static String getErrorCode(dynamic error) {
    if (error is SocketException) {
      return networkUnavailable;
    }
    
    if (error is TimeoutException) {
      return networkTimeout;
    }
    
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      
      // Network errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return networkTimeout;
      }
      
      if (error.type == DioExceptionType.connectionError) {
        return networkConnection;
      }
      
      // HTTP status codes
      if (statusCode != null) {
        switch (statusCode) {
          case 401:
            return unauthorized;
          case 403:
            return unauthorized;
          case 404:
            return dataNotFound;
          case 408:
            return networkTimeout;
          case 500:
            return serverError;
          case 502:
          case 503:
            return serverUnavailable;
          case 504:
            return serverTimeout;
          default:
            return operationFailed;
        }
      }
      
      return networkConnection;
    }
    
    return unknownError;
  }
}

