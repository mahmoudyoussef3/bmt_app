import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

/// An adapter that bridges the standard Dart `http.Client` (which Supabase uses)
/// to our custom `Dio` instance.
///
/// By providing this to `Supabase.initialize(httpClient: ...)` we force all
/// Supabase requests to flow through `DioFactory`, meaning they trigger the
/// `PrettyDioLogger` and any custom interceptors.
class DioHttpClientAdapter extends http.BaseClient {
  final Dio dio;

  DioHttpClientAdapter(this.dio);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    
    final options = Options(
      method: request.method,
      headers: request.headers,
      
      responseType: ResponseType.bytes,
      validateStatus: (status) =>
          true, 
    );

    dynamic data;
    if (request is http.Request) {
      data = request.bodyBytes.isEmpty ? null : request.bodyBytes;
    } else {
      data = request.finalize();
    }

    try {
      final dioResponse = await dio.request<List<int>>(
        request.url.toString(),
        data: data,
        options: options,
      );

      final List<int> bytes = dioResponse.data as List<int>;
      final stream = Stream.value(bytes);

      return http.StreamedResponse(
        stream,
        dioResponse.statusCode ?? 200,
        contentLength:
            dioResponse.headers.value(Headers.contentLengthHeader) != null
            ? int.tryParse(
                dioResponse.headers.value(Headers.contentLengthHeader)!,
              )
            : null,
        request: request,
        headers: dioResponse.headers.map.map(
          (key, value) => MapEntry(key, value.join(',')),
        ),
        isRedirect: dioResponse.isRedirect,
      );
    } on DioException catch (e) {
      throw http.ClientException(e.toString(), request.url);
    }
  }
}
