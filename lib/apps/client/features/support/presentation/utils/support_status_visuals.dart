import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

import '../../domain/entities/support_ticket.dart';

/// Accent color and icon for a ticket's lifecycle status.
///
/// The ticket card and the ticket details screen each used to carry their own
/// copy of this mapping, which let the two drift apart (the details screen was
/// tinting "under review" with a raw `Colors.orange`). Both now read from here,
/// the same way they already share their labels via `support_ticket_labels.dart`.
abstract final class SupportStatusVisuals {
  const SupportStatusVisuals._();

  static Color colorFor(BuildContext context, TicketStatus status) =>
      switch (status) {
        TicketStatus.submitted => ClientColors.primaryFor(context),
        TicketStatus.underReview => ClientColors.journeyAmber,
        TicketStatus.contacted => ClientColors.secondary,
        TicketStatus.resolved => ClientColors.journeyCyan,
        TicketStatus.closed => ClientColors.textTertiaryFor(context),
        TicketStatus.rejected => ClientColors.journeyRed,
      };

  static IconData iconFor(TicketStatus status) => switch (status) {
    TicketStatus.submitted => Icons.mark_email_unread_rounded,
    TicketStatus.underReview => Icons.hourglass_top_rounded,
    TicketStatus.contacted => Icons.support_agent_rounded,
    TicketStatus.resolved => Icons.check_circle_rounded,
    TicketStatus.closed => Icons.lock_rounded,
    TicketStatus.rejected => Icons.cancel_rounded,
  };
}
