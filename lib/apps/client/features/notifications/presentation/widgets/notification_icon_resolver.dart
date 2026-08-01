import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

import '../../domain/entities/client_notification.dart';

/// The icon and its two colours for each notification category.
///
/// Every pair is `(ink, container)` drawn from the shared journey roles, so a
/// notification row uses the same amber for "payment" that a payment chip uses
/// elsewhere. It previously carried its own hex literals for eight of the ten
/// categories — light-mode tints like `#FEF3C7` and `#F1F5F9` that would have
/// rendered as near-white blocks on a dark page.
abstract final class NotificationIconResolver {
  static (Color iconColor, Color iconBg, IconData icon) resolve(
    BuildContext context,
    NotificationCategory category,
  ) => switch (category) {
    NotificationCategory.booking => (
      ClientColors.onJourneyCyanFor(context),
      ClientColors.journeyCyanLightFor(context),
      Icons.confirmation_number_outlined,
    ),
    NotificationCategory.payment => (
      ClientColors.onJourneyAmberFor(context),
      ClientColors.journeyAmberLightFor(context),
      Icons.payments_outlined,
    ),
    NotificationCategory.trip => (
      ClientColors.onPrimaryContainerFor(context),
      ClientColors.primaryContainerFor(context),
      Icons.directions_bus_outlined,
    ),
    NotificationCategory.subscription => (
      ClientColors.journeyPurpleFor(context),
      ClientColors.journeyPurpleLightFor(context),
      Icons.card_membership_outlined,
    ),
    NotificationCategory.promotion => (
      ClientColors.onJourneyAmberFor(context),
      ClientColors.journeyAmberLightFor(context),
      Icons.local_offer_outlined,
    ),
    NotificationCategory.emergency => (
      ClientColors.onJourneyRedFor(context),
      ClientColors.journeyRedLightFor(context),
      Icons.warning_amber_rounded,
    ),
    NotificationCategory.chat => (
      ClientColors.onJourneyCyanFor(context),
      ClientColors.journeyCyanLightFor(context),
      Icons.chat_bubble_outline_rounded,
    ),
    NotificationCategory.announcement => (
      ClientColors.onJourneySlateFor(context),
      ClientColors.journeySlateLightFor(context),
      Icons.campaign_outlined,
    ),
    NotificationCategory.system => (
      ClientColors.onJourneySlateFor(context),
      ClientColors.journeySlateLightFor(context),
      Icons.settings_outlined,
    ),
    NotificationCategory.general => (
      ClientColors.onPrimaryContainerFor(context),
      ClientColors.primaryContainerFor(context),
      Icons.notifications_outlined,
    ),
  };
}
