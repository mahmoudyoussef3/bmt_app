import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'api_constants.dart';
import 'app_interceptors.dart';

class DioFactory {
  DioFactory._();

  static Dio? _dio;

  static Dio getDio() {
    if (_dio != null) return _dio!;

    _dio = Dio();

    _dio!.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: kIsWeb ? null : ApiConstants.sendTimeout,
      headers: {
        'Content-Type': ApiConstants.contentType,
        'Accept': ApiConstants.accept,
        'apikey': ApiConstants
            .anonKey, // Needed if querying Supabase REST endpoints via Retrofit
      },
    );

    _dio!.interceptors.add(AppInterceptors());

    // Only add pretty logging in debug mode to prevent sensitive data leaks in production
    if (kDebugMode) {
      _dio!.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody:
              false, // Turned off here because AppInterceptors prints it beautifully as JSON
          error: true,
          compact: true,
          maxWidth: 120,
        ),
      );
    }

    return _dio!;
  }
}
