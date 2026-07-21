import 'package:flutter/foundation.dart';

import 'office_context.dart';

/// The signed-in operator's office context, shared by every dashboard datasource.
///
/// This exists as a *mutable holder* rather than a value injected into constructors
/// for a concrete reason: every datasource in `dashboard_di.dart` is registered as a
/// `registerLazySingleton` and is therefore built before anyone has logged in. A
/// constructor-injected office id would be captured as null and stay null. Datasources
/// hold this object instead and read [officeId] per query, so the value is always the
/// current session's.
///
/// It is a [ChangeNotifier] so the shell can rebuild when the office or role changes
/// (sign-in, sign-out, role update) without polling.
class DashboardSession extends ChangeNotifier {
  OfficeContext? _context;

  OfficeContext? get context => _context;

  bool get isAuthenticated => _context != null;

  /// The office every scoped query filters by.
  ///
  /// Throws when read while signed out. That is deliberate: a query that silently
  /// fell back to "no filter" would return every office's rows, so failing loudly is
  /// far safer than defaulting.
  String get officeId {
    final ctx = _context;
    if (ctx == null) {
      throw StateError(
        'DashboardSession.officeId read while signed out. A scoped query must not '
        'run before the office context is loaded.',
      );
    }
    return ctx.officeId;
  }

  /// Non-throwing variant for widgets that legitimately render in both states.
  String? get officeIdOrNull => _context?.officeId;

  void start(OfficeContext context) {
    _context = context;
    notifyListeners();
  }

  void clear() {
    if (_context == null) return;
    _context = null;
    notifyListeners();
  }
}
