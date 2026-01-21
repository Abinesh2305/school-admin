import 'package:flutter/material.dart';
import 'error_handler.dart';
import '../../presentation/core/widgets/error_widget.dart' as error_widget;
import '../../presentation/core/widgets/empty_state_widget.dart';

/// Mixin for consistent error handling in screens
mixin ScreenErrorHandler {
  /// Build error widget with retry
  Widget buildErrorWidget(String message, String? errorCode, VoidCallback onRetry) {
    return error_widget.CustomErrorWidget(
      message: message,
      errorCode: errorCode,
      onRetry: onRetry,
    );
  }

  /// Build empty state widget
  Widget buildEmptyState(String message, {IconData? icon, VoidCallback? onRetry}) {
    return EmptyStateWidget(
      message: message,
      icon: icon ?? Icons.inbox_outlined,
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }

  /// Handle API call with error handling
  Future<ApiResponseResult> handleApiCall<T>(
    Future<T> Function() apiCall, {
    required String context,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final result = await apiCall();
      if (result is Map<String, dynamic>) {
        return ErrorHandler.handleApiResponse(result);
      }
      return ApiResponseResult(
        success: true,
        data: result,
        message: 'Success',
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        context: context,
        error: e,
        stackTrace: stackTrace,
        additionalInfo: additionalInfo,
      );
      return ApiResponseResult(
        success: false,
        data: null,
        message: ErrorHandler.getErrorMessage(e),
        errorCode: ErrorHandler.getErrorCode(e),
      );
    }
  }
}




