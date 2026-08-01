import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// One place for the module's number/date rendering, so a price on a card and
/// the same price in the detail pane can never drift apart.
///
/// Digits stay Arabic-Indic to match the rest of the RTL dashboard, but the
/// conversion happens only at render time — never on values that are compared
/// or sent back to the database.
String subscriptionMoney(double value) => '${arabicNumber(value)} ج.م';

String subscriptionDate(DateTime value) {
  String two(int v) => v.toString().padLeft(2, '0');
  return arabicDigits('${value.year}/${two(value.month)}/${two(value.day)}');
}

String subscriptionDateTime(DateTime value) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${subscriptionDate(value)} — '
      '${arabicDigits('${two(value.hour)}:${two(value.minute)}')}';
}

String arabicNumber(num value) {
  final text = value is int || value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  return arabicDigits(text);
}

const _arabicDigitMap = {
  '0': '٠',
  '1': '١',
  '2': '٢',
  '3': '٣',
  '4': '٤',
  '5': '٥',
  '6': '٦',
  '7': '٧',
  '8': '٨',
  '9': '٩',
};

String arabicDigits(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_arabicDigitMap[char] ?? char);
  }
  return buffer.toString();
}

/// The module's status palette, shared by chips, borders and KPI tiles.
Color subscriptionStatusColor(
  BuildContext context,
  SubscriptionStatus status,
) => switch (status) {
  SubscriptionStatus.active => context.status(AppStatusTone.success).ink,
  SubscriptionStatus.pendingPayment =>
    context.status(AppStatusTone.warning).ink,
  SubscriptionStatus.expired => context.status(AppStatusTone.neutral).ink,
  SubscriptionStatus.cancelled => context.status(AppStatusTone.error).ink,
};

class SubscriptionStatusChip extends StatelessWidget {
  final SubscriptionStatus status;

  const SubscriptionStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = subscriptionStatusColor(context, status);
    return StatusChip(
      label: status.label,
      color: color.withAlpha(28),
      textColor: color,
    );
  }
}
