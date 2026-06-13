import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_result.dart';

class ApiErrorHandler {
  /// Converts any Exception (specifically DioException) into a clean, 
  /// user-friendly Failure. This ensures technical exceptions never reach the UI.
  static Failure<T> handle<T>(dynamic error) {
    if (error is DioException) {
      // Log for developers
      if (kDebugMode) {
        debugPrint('🌐 [API ERROR] ${error.requestOptions.uri} -> ${error.message}');
      }
      
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const Failure('انتهى وقت الاتصال، يرجى المحاولة مرة أخرى.', code: 'TIMEOUT');
        case DioExceptionType.badResponse:
          return _handleBadResponse<T>(error.response);
        case DioExceptionType.cancel:
          return const Failure('تم إلغاء الطلب.', code: 'CANCELLED');
        case DioExceptionType.connectionError:
          return const Failure('لا يوجد اتصال بالإنترنت.', code: 'NO_INTERNET');
        case DioExceptionType.unknown:
        default:
          if (error.error is SocketException) {
            return const Failure('لا يوجد اتصال بالإنترنت.', code: 'NO_INTERNET');
          }
          return const Failure('حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.', code: 'UNKNOWN');
      }
    } else {
      // Handle non-Dio errors (e.g. Supabase exceptions or formatting errors)
      if (kDebugMode) {
        debugPrint('🌐 [UNKNOWN ERROR] $error');
      }
      return Failure('حدث خطأ غير متوقع: ${error.toString()}', code: 'UNKNOWN');
    }
  }

  static Failure<T> _handleBadResponse<T>(Response? response) {
    final statusCode = response?.statusCode;
    
    // Attempt to extract backend error message if available
    String? backendMessage;
    if (response?.data != null && response?.data is Map<String, dynamic>) {
      backendMessage = response?.data['message'] ?? response?.data['error_description'];
    }

    switch (statusCode) {
      case 400:
        return Failure(backendMessage ?? 'طلب غير صالح.', code: '400');
      case 401:
        return Failure(backendMessage ?? 'غير مصرح لك بالوصول، يرجى تسجيل الدخول مجدداً.', code: '401');
      case 403:
        return Failure(backendMessage ?? 'ليس لديك صلاحية للوصول.', code: '403');
      case 404:
        return Failure(backendMessage ?? 'المورد غير موجود.', code: '404');
      case 422:
        return Failure(backendMessage ?? 'بيانات غير صالحة.', code: '422');
      case 500:
      case 502:
      case 503:
      case 504:
        return const Failure('حدث خطأ في الخادم، يرجى المحاولة لاحقاً.', code: 'SERVER_ERROR');
      default:
        return Failure(backendMessage ?? 'حدث خطأ غير متوقع.', code: statusCode?.toString());
    }
  }
}
