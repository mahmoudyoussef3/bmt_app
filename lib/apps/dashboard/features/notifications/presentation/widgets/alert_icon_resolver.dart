import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';

import '../../domain/entities/operational_alert.dart';

/// The semantic status role and icon each operational alert type is drawn with.
///
/// Returns a tone rather than an `(iconColor, iconBg)` pair of light-mode
/// hexes: the bell and the inbox render on a card that follows the theme, and
/// the old pale backgrounds (`#FEF3C7`, `#E0F2FE`, …) stayed pale on a slate
/// page. The caller resolves via `AppStatusStyle.of(context, tone)`.
abstract final class AlertIconResolver {
  static (AppStatusTone tone, IconData icon) resolve(
    OperationalAlertType type,
  ) => switch (type) {
    OperationalAlertType.paymentReview => (
      AppStatusTone.warning,
      Icons.receipt_long_outlined,
    ),
    OperationalAlertType.captainRequest => (
      AppStatusTone.special,
      Icons.how_to_reg_outlined,
    ),
    OperationalAlertType.supportTicket => (
      AppStatusTone.success,
      Icons.support_agent_outlined,
    ),
    OperationalAlertType.refundRequest => (
      AppStatusTone.error,
      Icons.currency_exchange_outlined,
    ),
    OperationalAlertType.tripCancelled => (
      AppStatusTone.error,
      Icons.cancel_outlined,
    ),
    OperationalAlertType.general => (
      AppStatusTone.info,
      Icons.notifications_outlined,
    ),
  };
}
