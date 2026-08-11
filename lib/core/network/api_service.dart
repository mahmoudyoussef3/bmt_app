import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api_service.g.dart';

/// Centralized API Service for executing direct REST calls.
///
/// Add your new endpoints here. Since this is bound to `DioFactory`,
/// all requests here will have the base URL, timeouts, and authorization headers automatically applied.
@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

}
