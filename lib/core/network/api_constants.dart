import 'package:bmt_app/core/flavors/app_flavor.dart';

class ApiConstants {
  ApiConstants._();

  /// Since the project relies heavily on Supabase, we default our base URL to
  /// the Supabase REST URL. This allows Retrofit to call Supabase exactly like
  /// a normal REST API when needed.
  static String get baseUrl => AppFlavorConfig.current.supabaseRestUrl;

  /// Replace with your actual anon key or service role key if needed for external API calls
  static String get anonKey => AppFlavorConfig.current.supabasePublishableKey;

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
  static const String authorization = 'Authorization';
  static const String apiKeyHeader = 'apikey';
}
