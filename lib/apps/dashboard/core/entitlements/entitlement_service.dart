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
/// Refreshed on six events, matching every way the answer can change:
///
///   * sign-in                        — the document is loaded for the first time
///   * a licensing refusal            — the server disagreed with what we hold
///   * an explicit reload             — the operator pressed refresh
///   * `office_licenses` realtime     — plan assigned, suspended, restored
///   * `office_feature_overrides`     — an override granted, edited or cleared
///   * `platform_plan_features` /     — a plan edited or a feature kill-switched,
///     `platform_features`              both of which §2.5 requires to propagate
///                                      live to every subscribed office
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

    final officeFilter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'office_id',
      value: officeId,
    );

    // One channel, four tables. Realtime applies RLS per subscriber, so the two
    // office-scoped tables deliver only this office's rows and the two catalog
    // tables deliver only what any office may already read (§13.3).
    //
    // Plan and catalog changes are unfiltered on purpose: a plan edit does not
    // name the offices it affects, and working out whether this office is on the
    // edited plan costs exactly the round trip that [refresh] already makes.
    // Coalescing is [load]'s job — a burst of row events during a
    // `platform_save_plan` joins one in-flight fetch instead of starting many.
    _channel = _client
        .channel('dashboard_entitlements_$officeId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'office_licenses',
          filter: officeFilter,
          callback: (_) => refresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'office_feature_overrides',
          filter: officeFilter,
          callback: (_) => refresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'platform_plan_features',
          callback: (_) => refresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'platform_features',
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
