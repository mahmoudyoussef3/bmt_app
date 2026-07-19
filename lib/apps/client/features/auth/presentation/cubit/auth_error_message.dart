/// Maps an auth error to a user-facing message: a [FormatException] carries a
/// ready validation message, while other exceptions are unwrapped from their
/// `Exception:` prefix.
String authErrorMessage(Object error) {
  if (error is FormatException) return error.message;
  return error.toString().replaceAll('Exception: ', '');
}
