import 'package:flutter/foundation.dart';

import 'licensing_failure.dart';

/// The one place a server refusal becomes a *licensing* refusal.
///
/// ## Why this exists
///
/// Every enforcement path in the database refuses with one of the six codes in
/// §7.2 and carries the whole verdict across in the exception detail. Without
/// this guard each datasource ran that exception through its own formatter, so
/// the operator saw
///
///     quota_exceeded | code: 23514 | details: {"allowed": false, "limit": 5, …}
///
/// instead of "12 من 12 سائقًا على الأساسية" — the exact failure §7.2 and §10.3
/// exist to prevent, and the difference between a support ticket and a sale.
///
/// ## How it is used
///
/// One line, first thing in the `catch` of any write that a trigger or an
/// `assert_feature()` guard can refuse:
///
/// ```dart
/// } on PostgrestException catch (e) {
///   LicensingGuard.check(e);          // throws LicensingFailure, or returns
///   throw Exception(_formatError(e)); // unchanged for everything else
/// }
/// ```
///
/// [check] is deliberately a no-op for non-licensing errors, so adding it to a
/// catch block cannot change any existing behaviour. That property is what makes
/// it safe to apply across the whole data layer at once.
class LicensingGuard {
  const LicensingGuard._();

  /// Rethrows [error] as a [LicensingFailure] when it is one, after announcing
  /// it on [licensingRefusals] so the shell can raise the upgrade card.
  ///
  /// Returns normally for anything else — the caller's own error mapping runs
  /// unchanged.
  static void check(Object error) {
    final failure = LicensingFailure.tryParse(error);
    if (failure == null) return;
    licensingRefusals.report(failure);
    throw failure;
  }

  /// Wraps a whole write for the datasources that carry no `catch` of their own.
  static Future<T> run<T>(Future<T> Function() write) async {
    try {
      return await write();
    } catch (error) {
      check(error);
      rethrow;
    }
  }
}

/// Announces licensing refusals to whoever is showing the UI.
///
/// ## Why a library singleton and not a `get_it` registration
///
/// This is not a dependency with alternatives; it is a one-way UI event channel
/// with exactly one publisher (the data layer) and exactly one subscriber (the
/// shell). Putting it in the service locator would mean every datasource — all
/// of which sit in `data/` and take nothing but a `SupabaseClient` — had to
/// reach into DI to report an error, and a test that builds a datasource without
/// the full graph would crash on the reporting path rather than on the thing it
/// was testing.
///
/// It holds at most one refusal and drops it once read: a refusal is a response
/// to something the operator just did, and replaying a stale one after the fact
/// would be worse than losing it.
class LicensingRefusalBus extends ChangeNotifier {
  LicensingFailure? _pending;

  /// The refusal waiting to be shown, if any. Reading does not clear it — call
  /// [consume] for that.
  LicensingFailure? get pending => _pending;

  void report(LicensingFailure failure) {
    _pending = failure;
    notifyListeners();
  }

  /// Takes the pending refusal and clears it, so a rebuild cannot show the same
  /// dialog twice.
  LicensingFailure? consume() {
    final failure = _pending;
    _pending = null;
    return failure;
  }

  void clear() => _pending = null;
}

/// The app-wide instance. See [LicensingRefusalBus] for why it is not in DI.
final licensingRefusals = LicensingRefusalBus();
