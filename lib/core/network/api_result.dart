/// A clean wrapper for all API responses ensuring UI layers never handle raw exceptions.
/// 
/// Dart 3 features sealed classes which allows for exhaustive pattern matching
/// when consuming the result in a Cubit or UseCase.
sealed class ApiResult<T> {
  const ApiResult();
}

class Success<T> extends ApiResult<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends ApiResult<T> {
  final String message;
  final String? code;
  final dynamic technicalDetails;

  const Failure(this.message, {this.code, this.technicalDetails});
}
