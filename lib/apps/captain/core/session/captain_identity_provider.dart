import 'package:supabase_flutter/supabase_flutter.dart';

import 'captain_office_session.dart';

/// The one place the captain's identity is resolved.
///
/// [CaptainOfficeSession] is filled at sign-in, but a Supabase auth session
/// outlives the process — on every relaunch the captain is authenticated with an
/// empty session. Before this existed each datasource papered over that by
/// re-querying the `drivers` table itself on every screen load, and the assigned-
/// trips one cached the result in a lazy singleton that survived sign-out, so a
/// second captain on the same device inherited the first captain's id.
///
/// Everything now asks here instead. The session answers when it is warm;
/// otherwise `captain_session_context()` restores it from `auth.uid()` alone —
/// server-side, so the office is never inferred from anything the app holds.
class CaptainIdentityProvider {
  CaptainIdentityProvider(this._supabase, this._session);

  final SupabaseClient _supabase;
  final CaptainOfficeSession _session;

  /// De-duplicates the restore: the shell mounts several cubits at once and they
  /// all load immediately, which used to mean one round-trip each.
  Future<CaptainIdentity?>? _inFlight;

  /// The signed-in captain, or null when nobody is signed in, the user is not a
  /// driver, or their office is no longer active.
  Future<CaptainIdentity?> ensure() {
    final current = _session.identity;
    if (current != null) return Future.value(current);

    if (_supabase.auth.currentUser == null) return Future.value(null);

    return _inFlight ??= _restore().whenComplete(() => _inFlight = null);
  }

  /// Convenience for the many call sites that only need "which driver am I".
  Future<String?> driverId() async => (await ensure())?.driverId;

  /// The driver id if the session is already warm, without a round trip — for
  /// synchronous callers such as opening a realtime channel. Null before the
  /// first [ensure], which for the realtime path is harmless: the load that
  /// precedes it warms the session, and sign-out empties it again.
  String? get driverIdOrNull => _session.driverIdOrNull;

  /// The captain's office, for surfacing who they drive for.
  String? get officeNameOrNull => _session.identity?.officeName;

  Future<CaptainIdentity?> _restore() async {
    final context = await _supabase.rpc('captain_session_context');
    if (context == null) return null;

    final identity = CaptainIdentity.fromRpc(
      Map<String, dynamic>.from(context as Map),
    );
    if (identity.driverId.isEmpty || identity.officeId.isEmpty) return null;

    _session.start(identity);
    return identity;
  }
}
