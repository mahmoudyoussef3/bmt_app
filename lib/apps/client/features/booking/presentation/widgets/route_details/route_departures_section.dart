import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_departure_tile.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_inline_empty.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_timeline_header.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// When this line runs — nothing more.
///
/// This card used to be a filterable list of selectable departures carrying a
/// fare and an operator badge each, which asked the rider to make the trip
/// decision twice: once here, and again on the wizard's trip step where it
/// actually binds. So it states the timetable and says, plainly, that the
/// choosing happens next. Prices are absent by design — a fare depends on the
/// pickup/drop-off pair the rider has not picked yet, so any figure shown here
/// would be a guess at their journey.
class RouteDeparturesSection extends StatelessWidget {
  const RouteDeparturesSection({super.key, required this.trips});

  final List<RouteTripOptionData> trips;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ordered = [...trips]..sort(_byDepartureTime);

    return ClientCard(
      padding: ClientSpacing.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RouteSectionHeader(
            icon: Icons.schedule_rounded,
            title: l10n.booking_availableTripsLabel,
            subtitle: l10n.booking_pickTripNextStep,
            trailingLabel: ordered.isEmpty ? null : '${ordered.length}',
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: ClientColors.borderFor(context)),
          const SizedBox(height: 4),
          if (ordered.isEmpty) ...[
            const SizedBox(height: 14),
            RouteDetailsInlineEmpty(
              icon: Icons.event_busy_rounded,
              title: l10n.booking_noScheduledTripsYet,
              subtitle: l10n.booking_noDepartureTimesAvailable,
            ),
          ] else
            ...ordered.asMap().entries.map(
              (entry) => RouteDepartureTile(
                trip: entry.value,
                showDivider: entry.key < ordered.length - 1,
              ),
            ),
        ],
      ),
    );
  }

  /// Chronological, to the minute. The dashboard hands departures back in no
  /// guaranteed order, and a timetable that is not in time order is not a
  /// timetable.
  static int _byDepartureTime(RouteTripOptionData a, RouteTripOptionData b) {
    final byDay = a.tripDate.compareTo(b.tripDate);
    if (byDay != 0) return byDay;
    return _minutes(a.departureTime).compareTo(_minutes(b.departureTime));
  }

  /// Minutes past midnight for a raw `HH:mm[:ss]` clock. An unparseable time
  /// sorts last rather than first, so a malformed row never leads the list.
  static int _minutes(String rawTime) {
    final parts = rawTime.split(':');
    if (parts.length < 2) return 1 << 20;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return 1 << 20;
    return hour * 60 + minute;
  }
}
