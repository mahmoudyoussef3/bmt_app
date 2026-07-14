import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

import '../../domain/entities/client_notification.dart';

abstract final class NotificationIconResolver {
  static (Color iconColor, Color iconBg, IconData icon) resolve(
    NotificationCategory category,
  ) => switch (category) {
    NotificationCategory.booking => (
      ClientColors.journeyCyan,
      ClientColors.journeyCyanLight,
      Icons.confirmation_number_outlined,
    ),
    NotificationCategory.payment => (
      const Color(0xFFD97706),
      const Color(0xFFFEF3C7),
      Icons.payments_outlined,
    ),
    NotificationCategory.trip => (
      const Color(0xFF1769E8),
      const Color(0xFFEAF2FF),
      Icons.directions_bus_outlined,
    ),
    NotificationCategory.subscription => (
      const Color(0xFF7C3AED),
      const Color(0xFFF5F3FF),
      Icons.card_membership_outlined,
    ),
    NotificationCategory.promotion => (
      const Color(0xFFD97706),
      const Color(0xFFFEF3C7),
      Icons.local_offer_outlined,
    ),
    NotificationCategory.emergency => (
      const Color(0xFFDC2626),
      const Color(0xFFFEE2E2),
      Icons.warning_amber_rounded,
    ),
    NotificationCategory.chat => (
      const Color(0xFF0891B2),
      const Color(0xFFE0F2FE),
      Icons.chat_bubble_outline_rounded,
    ),
    NotificationCategory.announcement => (
      const Color(0xFF64748B),
      const Color(0xFFF1F5F9),
      Icons.campaign_outlined,
    ),
    NotificationCategory.system => (
      const Color(0xFF64748B),
      const Color(0xFFF1F5F9),
      Icons.settings_outlined,
    ),
    NotificationCategory.general => (
      const Color(0xFF1769E8),
      const Color(0xFFEAF2FF),
      Icons.notifications_outlined,
    ),
  };
}
