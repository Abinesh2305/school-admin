/// Base failure class for error handling
abstract class Failure {
  final String message;
  final int? code;
  
  const Failure(this.message, {this.code});
  
  @override
  String toString() => message;
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, {super.code});
}

/// Server failures
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Cache/storage failures
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}

