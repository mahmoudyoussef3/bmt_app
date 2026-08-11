import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/support/presentation/routes/support_routes.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_attention_copy.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Says what this booking still needs, in plain words, above everything else on
/// Trip Details.
///
/// The status badge answers "where is the journey"; this answers "is it my
/// move". Collapses to nothing when the booking is settled, so a healthy trip
/// carries no scolding banner.
class TripAttentionBanner extends StatelessWidget {
  const TripAttentionBanner({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final copy = tripAttentionCopy(context, trip);
    if (copy == null) return const SizedBox.shrink();

    final offersSupport =
        trip.attention == TripAttention.needsSupport ||
        trip.attention == TripAttention.refundDue ||
        trip.attention == TripAttention.paymentRejected;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: copy.color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: copy.color.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(copy.icon, size: 20, color: copy.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.title,
                  style: ClientTypography.labelMedium(context).copyWith(
                    color: ClientColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy.body,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
                if (offersSupport) ...[
                  const SizedBox(height: 6),
                  
                  InkWell(
                    onTap: () =>
                        Navigator.pushNamed(context, SupportRoutes.center),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        context.l10n.trips_attentionOpenSupport,
                        style: ClientTypography.labelMedium(
                          context,
                        ).copyWith(color: copy.color),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
