import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/support_ticket.dart';

/// Localized display label for a ticket's lifecycle status.
///
/// Shared by [SupportTicketCard] and the ticket details screen so the two
/// status pills never drift apart.
String supportStatusLabel(BuildContext context, TicketStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    TicketStatus.submitted => l10n.support_statusSubmitted,
    TicketStatus.underReview => l10n.support_statusUnderReview,
    TicketStatus.contacted => l10n.support_statusContacted,
    TicketStatus.resolved => l10n.support_statusResolved,
    TicketStatus.closed => l10n.support_statusClosed,
    TicketStatus.rejected => l10n.support_statusRejected,
  };
}

/// Localized display label for a ticket's category.
///
/// The category is stored verbatim in Supabase (see
/// `domain/entities/support_category.dart`) so historic tickets keep working
/// — this only maps the known canonical values to a translated label and
/// falls back to the raw stored value for anything else.
String supportCategoryLabel(BuildContext context, String category) {
  final l10n = context.l10n;
  return switch (category) {
    'Booking Issue' => l10n.support_categoryBooking,
    'Payment Issue' => l10n.support_categoryPayment,
    'Trip Delay' => l10n.support_categoryTripDelay,
    'Driver or Vehicle Issue' => l10n.support_categoryDriverVehicle,
    'Subscription Issue' => l10n.support_categorySubscription,
    'Lost Item' => l10n.support_categoryLostItem,
    'Other' => l10n.support_categoryOther,
    _ => category,
  };
}
