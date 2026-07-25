/// Base exception for server errors
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Exception for network/internet issues
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception for local storage failures
class CacheException implements Exception {
  final String message;
  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

/// Exception for HLS parsing/download failures
class HlsException implements Exception {
  final String message;
  HlsException(this.message);

  @override
  String toString() => 'HlsException: $message';
}

/// Exception for cancelled operations
class CancellationException implements Exception {
  final String message;
  CancellationException([this.message = 'Operation cancelled']);

  @override
  String toString() => 'CancellationException: $message';
}
