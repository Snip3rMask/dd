import 'package:dio/dio.dart';

/// Logs all API requests and responses in debug mode
class ApiLoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('[API] ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('[API] ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('[API] ERROR ${err.type}: ${err.message}');
    handler.next(err);
  }
}

/// Maps DioExceptions to our custom exceptions
class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        err = DioException(
          requestOptions: err.requestOptions,
          error: err.error,
          type: err.type,
          message: 'Network error: ${err.message}',
        );
        break;
      case DioExceptionType.badResponse:
        // Already handled by the caller
        break;
      default:
        break;
    }
    handler.next(err);
  }
}
