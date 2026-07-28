import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The words, icon and colour for a [TripAttention].
///
/// Kept out of the widget so the same copy backs the banner on Trip Details and
/// the one-line strip on a My Trips card — a rider must not read two different
/// accounts of the same booking on two screens.
class TripAttentionCopy {
  const TripAttentionCopy({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
}

TripAttentionCopy? tripAttentionCopy(BuildContext context, TripData trip) {
  final l10n = context.l10n;

  return switch (trip.attention) {
    TripAttention.none => null,

    TripAttention.awaitingPaymentReview => TripAttentionCopy(
      title: l10n.trips_attentionAwaitingReviewTitle,
      body: trip.officeName.isEmpty
          ? l10n.trips_attentionAwaitingReviewBodyNoOffice
          : l10n.trips_attentionAwaitingReviewBody(trip.officeName),
      icon: Icons.pending_actions_rounded,
      color: ClientColors.journeyAmber,
    ),

    TripAttention.paymentIncomplete => TripAttentionCopy(
      title: l10n.trips_attentionPaymentIncompleteTitle,
      body: l10n.trips_attentionPaymentIncompleteBody,
      icon: Icons.hourglass_top_rounded,
      color: ClientColors.journeyAmber,
    ),

    TripAttention.paymentRejected => TripAttentionCopy(
      title: l10n.trips_attentionPaymentRejectedTitle,
      body: l10n.trips_attentionPaymentRejectedBody,
      icon: Icons.error_rounded,
      color: ClientColors.journeyRed,
    ),

    TripAttention.refundDue => TripAttentionCopy(
      title: l10n.trips_attentionRefundDueTitle,
      body: l10n.trips_attentionRefundDueBody,
      icon: Icons.replay_rounded,
      color: ClientColors.primary,
    ),

    TripAttention.needsSupport => TripAttentionCopy(
      title: l10n.trips_attentionNeedsSupportTitle,
      body: l10n.trips_attentionNeedsSupportBody(trip.reference),
      icon: Icons.help_outline_rounded,
      color: ClientColors.journeyRed,
    ),
  };
}
