import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../../../domain/entities/tracking_crew.dart';
import '../../formatters/tracking_labels.dart';
import 'tracking_card_parts.dart';
import 'tracking_vehicle_row.dart';

/// The captain and the vehicle, in one card.
///
/// The rating is the real average from `drivers.rating`, maintained by the
/// review triggers. A captain nobody has rated yet shows "no ratings" — never a
/// fabricated score, and never the old "N/A" that came from a field the app
/// never even fetched.
class TrackingCrewCard extends StatelessWidget {
  const TrackingCrewCard({
    super.key,
    required this.captain,
    required this.vehicle,
    required this.labels,
  });

  final TrackingCaptain captain;
  final TrackingVehicle vehicle;
  final TrackingLabels labels;

  @override
  Widget build(BuildContext context) {
    final l10n = labels.l10n;
    final initials = captain.initials;

    return ClientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: ClientColors.primaryContainerFor(context),
                child: initials == null
                    ? Icon(
                        Icons.person_rounded,
                        color: ClientColors.primaryFor(context),
                      )
                    : Text(
                        initials,
                        style: ClientTypography.labelMedium(context).copyWith(
                          color: ClientColors.primaryFor(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      captain.displayName ?? l10n.tracking_captain,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    TrackingRatingRow(
                      hasRating: captain.hasRating,
                      text: captain.hasRating
                          ? labels.rating(
                              captain.rating!,
                              captain.ratingCount,
                            )
                          : l10n.tracking_noRating,
                    ),
                  ],
                ),
              ),
              if (captain.isCallable)
                IconButton.filledTonal(
                  onPressed: () => _call(context, captain.phone!),
                  icon: const Icon(Icons.call_rounded, size: 20),
                  tooltip: l10n.tracking_call,
                ),
            ],
          ),
          TrackingVehicleRow(vehicle: vehicle),
        ],
      ),
    );
  }

  Future<void> _call(BuildContext context, String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await launchUrl(Uri(scheme: 'tel', path: phone))) {
      messenger.showSnackBar(
        SnackBar(content: Text(labels.l10n.tracking_noPhone)),
      );
    }
  }
}
