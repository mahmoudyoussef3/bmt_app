import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/routes/communication_routes.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/driver_avatar.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/driver_identity.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_action_button.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_identity_labels.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_status_mapping.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

class TripDriverCard extends StatelessWidget {
  const TripDriverCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DriverAvatar(initials: trip.driverInitials),
            const SizedBox(width: 12),
            Expanded(
              child: DriverIdentity(
                name: driverNameFor(context, trip),
                rating: trip.driverRating,
                ratingCount: trip.driverRatingCount,
              ),
            ),
            const SizedBox(width: 8),
            TripInlineBadge(
              label: driverBadgeLabelFor(context, trip.status),
              color: driverBadgeColorFor(trip.status),
            ),
          ],
        ),
        if (trip.canContactDriver) ...[
          const SizedBox(height: 14),
          _ContactActions(trip: trip),
        ],
      ],
    );
  }
}

/// Call and chat — the two ways to reach a live captain.
///
/// Tracking deliberately isn't offered here: on a trackable trip the screen
/// already carries a live-tracking card above this section and a filled
/// "Track vehicle" CTA in the bottom bar, and a third copy of the same action
/// only made the captain row louder than the captain.
class _ContactActions extends StatelessWidget {
  const _ContactActions({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TripInlineActionButton(
            icon: Icons.call_rounded,
            label: context.l10n.tracking_call,
            filled: true,
            onTap: () => _callDriver(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TripInlineActionButton(
            icon: Icons.chat_bubble_rounded,
            label: context.l10n.trips_actionChat,
            color: ClientColors.primaryFor(context),
            onTap: () =>
                Navigator.pushNamed(context, CommunicationRoutes.communication),
          ),
        ),
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
