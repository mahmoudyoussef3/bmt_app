import 'package:supabase_flutter/supabase_flutter.dart';

import 'licensing_guard.dart';

/// The server-side gate every export passes through before a file exists.
///
/// ## Why this is an RPC and not a check on the entitlement document
///
/// PDF, Excel and CSV are produced entirely in the Flutter layer, from rows the
/// office is already licensed to read. There is no row to gate and no request to
/// intercept, so an `if (entitlements.allows(...))` in the toolbar would be the
/// *only* gate — precisely the "Flutter-only validation" the enforcement audit
/// set out to remove.
///
/// `office_consume_export` moves the decision and the meter to the database:
/// it asserts `export_pdf` / `export_excel` and consumes one unit of
/// `max_exports_per_month` in the same transaction. The app cannot lie about its
/// own count, and the refusal carries the same six codes as every other one.
///
/// ## What it honestly cannot do
///
/// It does not stop an operator who already holds the data from writing their
/// own file. Nothing can, short of not letting them read the data — which they
/// are licensed to do. This gates the *product feature* and *meters the usage*,
/// which is what the catalog sells, and it is why `export_pdf` is registered as
/// an `rpc` gate rather than an `rls` one.
abstract final class LicensedExport {
  const LicensedExport._();

  /// Call before generating bytes. Throws a `LicensingFailure` when the office
  /// is not licensed for [format] or has exhausted its monthly export quota.
  static Future<void> consume(String format) {
    return LicensingGuard.run(
      () => Supabase.instance.client.rpc(
        'office_consume_export',
        params: {'p_kind': _kind(format)},
      ),
    );
  }

  /// One licence covers both spreadsheet forms; the server agrees.
  static String _kind(String format) => switch (format.toLowerCase()) {
    'pdf' => 'pdf',
    'excel' => 'excel',
    'csv' => 'csv',
    _ => format.toLowerCase(),
  };
}
