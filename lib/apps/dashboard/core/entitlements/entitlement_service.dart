import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/dashboard_session.dart';
import 'entitlement_context.dart';

/// Holds the resolved entitlement document for the session, and keeps it fresh.
///
/// A mutable holder for the same reason [DashboardSession] is one: every
/// datasource in `dashboard_di.dart` is a lazy singleton built before anyone has
/// signed in, so a constructor-injected document would be captured empty and
/// stay empty.
///
/// Refreshed on four events, matching the four ways the answer can change:
///
///   * sign-in                        — the document is loaded for the first time
///   * a licensing refusal            — the server disagreed with what we hold
///   * an `office_licenses` realtime  — the platform changed the plan or status
///   * an explicit reload             — the operator pressed refresh
///
/// Never throws. A failure leaves [context] at [EntitlementContext.unknown],
/// which allows everything, because this object is a UX hint and the server is
/// the boundary — a network blip must not silently hide half the console.
class EntitlementService extends ChangeNotifier {
  EntitlementService(this._client, this._session);

  final SupabaseClient _client;
  final DashboardSession _session;

  EntitlementContext _context = EntitlementContext.unknown;
  EntitlementContext get context => _context;

  bool get isLoaded => _context.isLoaded;

  RealtimeChannel? _channel;
  Future<void>? _inFlight;

  /// Loads the document and starts watching the office's license row.
  /// Idempotent: a second call while one is in flight joins the first.
  Future<void> load() {
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<void> _load() async {
    if (_session.officeIdOrNull == null) return;
    try {
      final result = await _client.rpc('office_entitlements');
      if (result is Map) {
        _context = EntitlementContext.fromRpc(
          Map<String, dynamic>.from(result),
        );
        notifyListeners();
      }
    } catch (_) {
      // Deliberately swallowed. See the class doc: failing open is the correct
      // default for a hint, and the server refuses anything this wrongly allows.
    }
    _watch();
  }

  /// Re-resolves after the server refused something on entitlement grounds. The
  /// document we were holding is, by definition, out of date at that moment.
  Future<void> refresh() async {
    _inFlight = null;
    await load();
  }

  void clear() {
    _unwatch();
    if (_context == EntitlementContext.unknown) return;
    _context = EntitlementContext.unknown;
    notifyListeners();
  }

  void _watch() {
    final officeId = _session.officeIdOrNull;
    if (officeId == null || _channel != null) return;

    _channel = _client
        .channel('dashboard_entitlements_$officeId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'office_licenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'office_id',
            value: officeId,
          ),
          // A plan change or a suspension must reach an already-open console.
          // Overrides and plan edits are deliberately NOT subscribed to: they
          // are platform-side edits measured in a handful per month, and the
          // next sign-in or refresh picks them up without a second channel.
          callback: (_) => refresh(),
        );

    _channel!.subscribe();
  }

  void _unwatch() {
    final channel = _channel;
    _channel = null;
    if (channel != null) _client.removeChannel(channel);
  }

  @override
  void dispose() {
    _unwatch();
    super.dispose();
  }
}
