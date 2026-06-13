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
          return const Failure('Connection timed out. Please try again.', code: 'TIMEOUT');
        case DioExceptionType.badResponse:
          return _handleBadResponse<T>(error.response);
        case DioExceptionType.cancel:
          return const Failure('Request was cancelled.', code: 'CANCELLED');
        case DioExceptionType.connectionError:
          return const Failure('No internet connection.', code: 'NO_INTERNET');
        case DioExceptionType.unknown:
        default:
          if (error.error is SocketException) {
            return const Failure('No internet connection.', code: 'NO_INTERNET');
          }
          return const Failure('An unexpected error occurred. Please try again later.', code: 'UNKNOWN');
      }
    } else {
      // Handle non-Dio errors (e.g. Supabase exceptions or formatting errors)
      if (kDebugMode) {
        debugPrint('🌐 [UNKNOWN ERROR] $error');
      }
      return Failure('An unexpected error occurred: ${error.toString()}', code: 'UNKNOWN');
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
        return Failure(backendMessage ?? 'Invalid request.', code: '400');
      case 401:
        return Failure(backendMessage ?? 'Unauthorized. Please login again.', code: '401');
      case 403:
        return Failure(backendMessage ?? 'You do not have permission to access this resource.', code: '403');
      case 404:
        return Failure(backendMessage ?? 'Resource not found.', code: '404');
      case 422:
        return Failure(backendMessage ?? 'Invalid data provided.', code: '422');
      case 500:
      case 502:
      case 503:
      case 504:
        return const Failure('A server error occurred. Please try again later.', code: 'SERVER_ERROR');
      default:
        return Failure(backendMessage ?? 'An unexpected error occurred.', code: statusCode?.toString() ?? 'UNKNOWN');
    }
  }
}
