/// A sign-in, sign-up or context-load failure that already carries the sentence
/// the operator should read.
///
/// Lives in the domain because the cubit branches on it: keeping it beside the
/// Supabase datasource would have made the presentation layer import `data/`
/// just to catch an error type.
class DashboardAuthFailure implements Exception {
  const DashboardAuthFailure(this.message, {this.code});

  /// User-facing Arabic text. Every caller shows this and nothing else.
  final String message;

  /// The server's machine code, set only where a caller needs to branch on the
  /// *reason* rather than report it. Matching on [message] instead would couple
  /// control flow to translatable text.
  final String? code;

  @override
  String toString() => message;
}
