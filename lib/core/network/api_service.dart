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

  // Example endpoint to demonstrate Retrofit setup.
  // Replace or add actual endpoints as needed for external APIs.
  //
  // @GET('/example/endpoint')
  // Future<ExampleModel> getExampleData();

  // @POST('/example/submit')
  // Future<void> submitData(@Body() Map<String, dynamic> body);
}
