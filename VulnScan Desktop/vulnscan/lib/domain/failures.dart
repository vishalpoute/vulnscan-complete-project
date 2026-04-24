/// Base class for all app failures
abstract class Failure {
  final String message;

  Failure({required this.message});

  @override
  String toString() => message;
}

/// Authentication-related failures
class AuthFailure extends Failure {
  AuthFailure({required super.message});
}

/// Network-related failures
class NetworkFailure extends Failure {
  NetworkFailure({required super.message});
}

/// Server/API-related failures
class ServerFailure extends Failure {
  final int? statusCode;

  ServerFailure({required super.message, this.statusCode});
}

/// Subscription/authorization failures
class SubscriptionFailure extends Failure {
  SubscriptionFailure({required super.message});
}

/// Validation failures
class ValidationFailure extends Failure {
  ValidationFailure({required super.message});
}

/// Generic/unknown failures
class UnknownFailure extends Failure {
  UnknownFailure({required super.message});
}

/// Local storage failures
class StorageFailure extends Failure {
  StorageFailure({required super.message});
}
