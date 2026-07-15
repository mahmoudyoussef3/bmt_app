import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// Generates the next [count] selectable dates as display strings
/// (e.g. "Today, Jul 7", "Tomorrow, Jul 8", "Wed, Jul 9") for the date picker
/// on [SearchTripScreen].
List<String> buildSearchDateOptions(BuildContext context, {int count = 7}) {
  final l10n = context.l10n;
  final localeName = Localizations.localeOf(context).toString();
  final monthDay = DateFormat('MMM d', localeName);
  final weekdayMonthDay = DateFormat('EEE, MMM d', localeName);
  final now = DateTime.now();
  return List.generate(count, (i) {
    final d = now.add(Duration(days: i));
    if (i == 0) return '${l10n.common_today}, ${monthDay.format(d)}';
    if (i == 1) return '${l10n.common_tomorrow}, ${monthDay.format(d)}';
    return weekdayMonthDay.format(d);
  });
}

String todaySearchDateLabel(BuildContext context) =>
    buildSearchDateOptions(context, count: 1).first;
