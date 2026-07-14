import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppInterceptors extends Interceptor {
  /// Every Supabase call flows through this interceptor (see
  /// `DioHttpClientAdapter`), so a response body is dumped for each query a
  /// screen runs. `debugPrint` throttles output to ~12KB/s and the pretty
  /// encode runs on the UI isolate, so dumping a large payload keeps the app
  /// busy long after the data has arrived — the screen sits on its loading
  /// skeleton while the body scrolls past in the console. Bodies above this
  /// size are summarised instead.
  static const int _maxLoggedBodyBytes = 4 * 1024;

  /// Set to true locally when a large body really has to be inspected.
  static bool logFullBodies = false;

  static const Set<String> _sensitiveKeys = {
    'access_token',
    'refresh_token',
    'id_token',
    'token',
    'authorization',
    'apikey',
    'api_key',
    'password',
    'new_password',
    'confirm_password',
    'secret',
    'session',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('➡️ [API Request] [${options.method}] ${options.uri}');
    }

    // Inject the Supabase session token into all requests automatically if available.
    final session = _currentSessionOrNull();
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final size = _byteLength(response.data);
      debugPrint(
        '✅ [API Response] [${response.statusCode}] ${response.requestOptions.uri} (${_readableSize(size)})',
      );
      if (logFullBodies || size < 0 || size <= _maxLoggedBodyBytes) {
        debugPrint('📦 [Response Data]\n${_formatData(response.data)}');
      } else {
        debugPrint(
          '📦 [Response Data] omitted — ${_readableSize(size)} body. '
          'Set AppInterceptors.logFullBodies = true to dump it.',
        );
      }
    }

    // Continue processing the response
    super.onResponse(response, handler);
  }

  int _byteLength(dynamic data) {
    if (data is List<int>) return data.length;
    if (data is String) return data.length;
    return -1;
  }

  String _readableSize(int bytes) {
    if (bytes < 0) return 'unknown size';
    if (bytes < 1024) return '$bytes B';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
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
      dynamic jsonData = _redact(data);
      // If it's a list of bytes (from ResponseType.bytes), decode it to a string first
      if (data is List<int>) {
        final decodedString = utf8.decode(data);
        jsonData = _redact(jsonDecode(decodedString));
      } else if (data is String) {
        jsonData = _redact(jsonDecode(data));
      }
      return const JsonEncoder.withIndent('  ').convert(jsonData);
    } catch (_) {
      // Fallback to standard toString if it's not JSON
      if (data is List<int>) {
        try {
          return _redactSensitiveText(utf8.decode(data));
        } catch (_) {
          return '[Binary Data - ${data.length} bytes]';
        }
      }
      return _redactSensitiveText(data.toString());
    }
  }

  dynamic _redact(dynamic value) {
    if (value is Map) {
      return value.map((key, nestedValue) {
        final normalizedKey = key.toString().toLowerCase();
        if (_sensitiveKeys.any(normalizedKey.contains)) {
          return MapEntry(key, '[REDACTED]');
        }
        return MapEntry(key, _redact(nestedValue));
      });
    }

    if (value is List) {
      return value.map(_redact).toList(growable: false);
    }

    return value;
  }

  String _redactSensitiveText(String value) {
    return value
        .replaceAll(
          RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
          'Bearer [REDACTED]',
        )
        .replaceAll(
          RegExp(
            r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
            caseSensitive: false,
          ),
          '[REDACTED_JWT]',
        );
  }

  Session? _currentSessionOrNull() {
    try {
      return Supabase.instance.client.auth.currentSession;
    } catch (_) {
      return null;
    }
  }
}
