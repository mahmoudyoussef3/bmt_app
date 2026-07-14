import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/driver_avatar.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/driver_identity.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_action_button.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_status_mapping.dart';

/// The assigned captain's identity, rating, and quick actions.
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
                  name: trip.driverName,
                  rating: trip.driverRating,
                  ratingCount: trip.driverRatingCount,
                ),
              ),
              TripInlineBadge(
                label: driverBadgeLabelFor(trip.status),
                color: driverBadgeColorFor(trip.status),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TripInlineActionButton(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  onTap: () => _callDriver(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TripInlineActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  onTap: () => Navigator.pushNamed(context, '/communication'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TripInlineActionButton(
                  icon: Icons.location_on_rounded,
                  label: 'Track',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/tracking',
                    arguments: {'bookingId': trip.id},
                  ),
                ),
              ),
            ],
          ),
        ],
    );
  }

  Future<void> _callDriver(BuildContext context) async {
    final phone = trip.driverPhone.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Driver phone number is not available.')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not start a call to $phone.')),
      );
    }
  }
}
