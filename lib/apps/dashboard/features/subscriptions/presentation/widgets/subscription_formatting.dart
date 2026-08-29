import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';

import '../../domain/entities/user_subscription.dart';
import '../../../finance/presentation/widgets/finance_format.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// One place for the module's number/date rendering, so a price on a card and
/// the same price in the detail pane can never drift apart.
///
/// Quantities and money delegate to [FinanceFormat] — the console's money
/// vocabulary — rather than rendering their own Arabic-Indic digits, which is
/// what this module used to do. The three المبيعات tabs (الحجوزات, الاشتراكات,
/// العملاء) each printed the same figure a different way as a result:
/// `١٢٬٣٤٥ ج.م` here, `12,345 ج.م` one tab over. They sit beside each other in
/// one sidebar group and report on the same money, so the difference reads as
/// two different amounts rather than as two spellings of one.
///
/// [arabicDigits] stays, and stays applied only to *identifiers* — trip codes,
/// phone numbers, booking ids — which are read as labels rather than compared
/// as magnitudes.
String subscriptionMoney(double value) => FinanceFormat.money(value);

String subscriptionDate(DateTime value) => FinanceFormat.date(value);

String subscriptionDateTime(DateTime value) => FinanceFormat.dateTime(value);

/// A quantity — a count of rides, subscribers, days. Never a year or an id:
/// those carry no thousands separator, and `2,025` is not a year.
String arabicNumber(num value) => FinanceFormat.count(value);

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
    return DashboardStatusChip(
      label: status.label,
      color: color.withAlpha(28),
      textColor: color,
    );
  }
}
