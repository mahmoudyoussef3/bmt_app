import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// Localized display label for a stored (English, canonical) cancellation
/// reason from `kCancellationReasons`.
///
/// The raw English value is what travels to Supabase and back as
/// `cancellation_reason`, so it must stay stable — only the on-screen label
/// is translated. A value that doesn't match a known reason (legacy data,
/// for instance) falls back to the raw string rather than going blank.
String cancellationReasonLabel(BuildContext context, String reason) {
  final l10n = context.l10n;
  return switch (reason) {
    'Schedule change' => l10n.trips_reasonScheduleChange,
    'Found alternative transport' => l10n.trips_reasonAlternativeTransport,
    'Driver delay concern' => l10n.trips_reasonDriverDelay,
    'Personal emergency' => l10n.trips_reasonPersonalEmergency,
    'Duplicate booking' => l10n.trips_reasonDuplicateBooking,
    'Other' => l10n.seatRelease_reasonOther,
    _ => reason,
  };
}
