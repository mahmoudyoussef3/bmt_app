import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppInterceptors extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('➡️ [API Request] [${options.method}] ${options.uri}');
    }

    // Inject the Supabase session token into all requests automatically if available.
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '✅ [API Response] [${response.statusCode}] ${response.requestOptions.uri}',
      );
      debugPrint('📦 [Response Data]\n${_formatData(response.data)}');
    }

    // Continue processing the response
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '❌ [API Error] [${err.response?.statusCode ?? 'N/A'}] ${err.requestOptions.uri}',
      );
      debugPrint('❗ [Error Message] ${err.message}');
      if (err.response?.data != null) {
        debugPrint('❗ [Error Data]\n${_formatData(err.response?.data)}');
      }
    }

    // Handle global authentication failures (e.g., token expired)
    if (err.response?.statusCode == 401) {
      debugPrint(
        '⚠️ [Auth Warning] Unauthorized request! Token might be expired.',
      );
      // Future logic: Trigger global logout or token refresh here.
    }

    super.onError(err, handler);
  }

  String _formatData(dynamic data) {
    try {
      dynamic jsonData = data;
      // If it's a list of bytes (from ResponseType.bytes), decode it to a string first
      if (data is List<int>) {
        final decodedString = utf8.decode(data);
        jsonData = jsonDecode(decodedString);
      } else if (data is String) {
        jsonData = jsonDecode(data);
      }
      return const JsonEncoder.withIndent('  ').convert(jsonData);
    } catch (_) {
      // Fallback to standard toString if it's not JSON
      if (data is List<int>) {
        try {
          return utf8.decode(data);
        } catch (_) {
          return '[Binary Data - ${data.length} bytes]';
        }
      }
      return data.toString();
    }
  }
}
