/// Result type for handling success/failure states
sealed class Result<T> {
  const Result();
}

/// Success result
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Failure result
class Failure<T> extends Result<T> {
  final String message;
  final int? code;
  const Failure(this.message, {this.code});
}

/// Extension methods for Result
extension ResultExtensions<T> on Result<T> {
  /// Check if result is success
  bool get isSuccess => this is Success<T>;
  
  /// Check if result is failure
  bool get isFailure => this is Failure<T>;
  
  /// Get data if success, null otherwise
  T? get dataOrNull => isSuccess ? (this as Success<T>).data : null;
  
  /// Get error message if failure, null otherwise
  String? get errorOrNull => isFailure ? (this as Failure<T>).message : null;
  
  /// Map the data type
  Result<R> map<R>(R Function(T) mapper) {
    if (isSuccess) {
      return Success(mapper((this as Success<T>).data));
    }
    return Failure((this as Failure<T>).message, code: (this as Failure<T>).code);
  }
  
  /// Fold result into a single value
  R fold<R>(R Function(String error) onFailure, R Function(T data) onSuccess) {
    if (isSuccess) {
      return onSuccess((this as Success<T>).data);
    }
    return onFailure((this as Failure<T>).message);
  }
}

