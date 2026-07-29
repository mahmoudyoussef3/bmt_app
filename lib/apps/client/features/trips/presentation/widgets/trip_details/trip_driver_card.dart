import 'package:bmt_app/apps/client/features/communication/presentation/routes/communication_routes.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/driver_avatar.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/driver_identity.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_action_button.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_identity_labels.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_status_mapping.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/routes/tracking_routes.dart';

/// The assigned captain's identity and rating — plus the live-journey actions
/// (call, chat, track), which only exist while there is a journey to act on.
///
/// A finished trip shows the captain as a record of who drove: calling or
/// chatting reaches nobody on duty for this booking, and there is no vehicle
/// left to follow on a map.
class TripDriverCard extends StatelessWidget {
  const TripDriverCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            DriverAvatar(initials: trip.driverInitials),
            const SizedBox(width: 14),
            Expanded(
              child: DriverIdentity(
                name: driverNameFor(context, trip),
                rating: trip.driverRating,
                ratingCount: trip.driverRatingCount,
              ),
            ),
            TripInlineBadge(
              label: driverBadgeLabelFor(context, trip.status),
              color: driverBadgeColorFor(trip.status),
            ),
          ],
        ),
        if (trip.canContactDriver) ...[
          const SizedBox(height: 16),
          _LiveActions(trip: trip),
        ],
      ],
    );
  }
}

/// Call, chat, and track — the actions that need a live captain. Track is held
/// back further: it appears only once the trip is under way and this booking's
/// own payment has been approved, matching the bottom bar's rule.
class _LiveActions extends StatelessWidget {
  const _LiveActions({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TripInlineActionButton(
            icon: Icons.call_rounded,
            label: context.l10n.tracking_call,
            onTap: () => _callDriver(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TripInlineActionButton(
            icon: Icons.chat_bubble_rounded,
            label: context.l10n.trips_actionChat,
            onTap: () =>
                Navigator.pushNamed(context, CommunicationRoutes.communication),
          ),
        ),
        if (trip.canBeTracked) ...[
          const SizedBox(width: 10),
          Expanded(
            child: TripInlineActionButton(
              icon: Icons.location_on_rounded,
              label: context.l10n.trips_liveTrackButton,
              onTap: () => Navigator.pushNamed(
                context,
                TrackingRoutes.tracking,
                arguments: {'bookingId': trip.id},
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _callDriver(BuildContext context) async {
    final phone = trip.driverPhone.trim();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (phone.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trips_driverPhoneUnavailable)),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trips_callFailed(phone))),
      );
    }
  }
}
