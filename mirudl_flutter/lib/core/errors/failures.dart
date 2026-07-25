/// Base failure class for use case results
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class HlsFailure extends Failure {
  const HlsFailure(super.message);
}

class CancellationFailure extends Failure {
  const CancellationFailure([super.message = 'Operation cancelled']);
}
