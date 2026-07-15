import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// A coarse time-of-day bucket for a trip's departure time, parsed
/// defensively — an unparseable time never excludes a trip from a filter.
enum DayPart { morning, afternoon, evening }

String timeOfDayLabel(BuildContext context, DayPart bucket) {
  final l10n = context.l10n;
  return switch (bucket) {
    DayPart.morning => l10n.booking_dayPartMorning,
    DayPart.afternoon => l10n.booking_dayPartAfternoon,
    DayPart.evening => l10n.booking_dayPartEvening,
  };
}
