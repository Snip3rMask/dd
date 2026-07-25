import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'api_interceptors.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.readTimeout,
        followRedirects: true,
        maxRedirects: 5,
        headers: {
          'User-Agent': ApiConstants.userAgent,
        },
      ),
    );

    dio.interceptors.addAll([
      ApiLoggerInterceptor(),
      ApiErrorInterceptor(),
    ]);
  }

  // Convenience getters for common header presets
  Options get jsonOptions => Options(
        headers: Map<String, dynamic>.from(ApiConstants.jsonHeaders),
      );

  Options get htmlOptions => Options(
        headers: Map<String, dynamic>.from(ApiConstants.htmlHeaders),
      );
}
