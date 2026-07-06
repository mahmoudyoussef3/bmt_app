import 'package:flutter/material.dart';

import '../../domain/entities/operational_alert.dart';

abstract final class AlertIconResolver {
  static (Color iconColor, Color iconBg, IconData icon) resolve(
    OperationalAlertType type,
  ) => switch (type) {
    OperationalAlertType.paymentReview => (
      const Color(0xFFD97706),
      const Color(0xFFFEF3C7),
      Icons.receipt_long_outlined,
    ),
    OperationalAlertType.captainRequest => (
      const Color(0xFF7C3AED),
      const Color(0xFFF5F3FF),
      Icons.how_to_reg_outlined,
    ),
    OperationalAlertType.supportTicket => (
      const Color(0xFF0891B2),
      const Color(0xFFE0F2FE),
      Icons.support_agent_outlined,
    ),
    OperationalAlertType.refundRequest => (
      const Color(0xFFDC2626),
      const Color(0xFFFEE2E2),
      Icons.currency_exchange_outlined,
    ),
    OperationalAlertType.tripCancelled => (
      const Color(0xFFDC2626),
      const Color(0xFFFEE2E2),
      Icons.cancel_outlined,
    ),
    OperationalAlertType.general => (
      const Color(0xFF1769E8),
      const Color(0xFFEAF2FF),
      Icons.notifications_outlined,
    ),
  };
}
