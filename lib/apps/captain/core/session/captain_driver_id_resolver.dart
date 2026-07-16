import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves the `drivers.id` row for the currently signed-in captain.
///
/// Every captain sign-in links `drivers.user_id` to the resulting
/// `auth.uid()` (see `link_current_captain_driver`), so a direct match is
/// the common case. The phone fallback covers a driver whose linking hasn't
/// happened yet — the one feature that originally carried this fallback was
/// trip history; the others (assigned trips, profile, check-in) each had
/// their own copy of the direct-match lookup with the fallback silently
/// missing, so a driver in that edge case saw a different screen behave
/// differently depending on which one happened to also try their phone.
/// Every captain datasource that needs "which driver record is this" now
/// shares this one query instead.
Future<String?> resolveCaptainDriverId(
  SupabaseClient supabase,
  User user,
) async {
  final direct = await supabase
      .from('drivers')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();
  if (direct != null) return direct['id'] as String?;

  final phone = user.phone;
  if (phone == null || phone.isEmpty) return null;
  final byPhone = await supabase
      .from('drivers')
      .select('id')
      .eq('phone', phone)
      .maybeSingle();
  return byPhone?['id'] as String?;
}
