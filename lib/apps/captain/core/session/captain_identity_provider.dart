import 'package:supabase_flutter/supabase_flutter.dart';

import 'captain_office_session.dart';

class CaptainIdentityProvider {
  CaptainIdentityProvider(this._supabase, this._session);

  final SupabaseClient _supabase;
  final CaptainOfficeSession _session;

  Future<CaptainIdentity?>? _inFlight;

  Future<CaptainIdentity?> ensure() {
    final current = _session.identity;
    if (current != null) return Future.value(current);

    if (_supabase.auth.currentUser == null) return Future.value(null);

    return _inFlight ??= _restore().whenComplete(() => _inFlight = null);
  }

  Future<String?> driverId() async => (await ensure())?.driverId;

  Future<CaptainIdentity?> refresh() {
    _session.clear();
    _inFlight = null;
    return ensure();
  }

  String? get driverIdOrNull => _session.driverIdOrNull;

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
