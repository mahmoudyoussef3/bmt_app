import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';

/// Who is signed in, what day it is, and the one action an operator starts
/// the morning with — a bare line on the page, not a card.
///
/// The EWT redesign retired the gradient hero: a full-bleed brand sweep whose
/// only content was a name and a date cost the top of every session's first
/// screen a card's worth of vertical space for something [DashboardKpiCard]
/// says better one scroll further down. [DashboardModuleHeader] made the same
/// trade for every other module; this is Home's own title block, styled the
/// same way, because Home's line says more than a module title does — who,
/// which office, how many trips, and when the numbers below it were last
/// true.
///
/// Reads entirely off [OfficeContext] and [todayTripsCount], both already
/// resolved by the time Home builds: no query of its own. Deliberately does
/// not repeat the bell or a profile menu — the shell's top bar and sidebar
/// already carry both.
class HomeHeaderBanner extends StatelessWidget {
  const HomeHeaderBanner({
    super.key,
    required this.office,
    required this.todayTripsCount,
    this.onRefresh,
    this.onCreateTrip,
    this.now,
    this.updatedAt,
  });

  final OfficeContext office;

  /// Folded into the context line — "١٨ رحلة مجدولة اليوم" — so the greeting
  /// answers "how busy is today" before the operator's eye even reaches the
  /// KPI row underneath it.
  final int todayTripsCount;

  final VoidCallback? onRefresh;

  /// Primary action. Opens the trip planner itself, not the trips list — the
  /// difference between one click and "navigate, then find the button".
  final VoidCallback? onCreateTrip;

  /// Injectable clock, so the greeting and the date are testable.
  final DateTime? now;

  /// When this load actually landed. Home rebuilds this banner exactly when
  /// [DashboardHomeCubit] emits a fresh summary, so the caller can pass the
  /// completion time of that fetch — never a guess, since there is no other
  /// moment this widget could claim as "when the numbers went stale".
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final at = now ?? DateTime.now();
    final officeName = office.officeName.trim().isEmpty
        ? 'مكتبك'
        : office.officeName.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final identity = _Identity(
          greeting: '${_greetingFor(at)}، ${office.displayName}',
          contextLine: _contextLine(
            officeName: officeName,
            date: at,
            tripsToday: todayTripsCount,
            updatedAt: updatedAt,
          ),
        );
        final actions = _Actions(
          onCreateTrip: onCreateTrip,
          onRefresh: onRefresh,
        );

        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identity,
              const SizedBox(height: AppSpacing.medium),
              actions,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: identity),
            const SizedBox(width: AppSpacing.large),
            actions,
          ],
        );
      },
    );
  }

  String _contextLine({
    required String officeName,
    required DateTime date,
    required int tripsToday,
    required DateTime? updatedAt,
  }) {
    final parts = <String>[
      officeName,
      _formatArabicDate(date),
      tripsToday == 0 ? 'لا رحلات مجدولة اليوم' : '$tripsToday رحلة مجدولة اليوم',
    ];
    if (updatedAt != null) parts.add('آخر تحديث ${_formatClock(updatedAt)}');
    return parts.join(' · ');
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.greeting, required this.contextLine});

  final String greeting;
  final String contextLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          greeting,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 3),
        Text(
          contextLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
      ],
    );
  }
}

/// One primary action, one secondary — on the same baseline as the greeting,
/// exactly where [DashboardModuleHeader] puts every other module's actions.
class _Actions extends StatelessWidget {
  const _Actions({this.onCreateTrip, this.onRefresh});

  final VoidCallback? onCreateTrip;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (onCreateTrip != null)
          FilledButton.icon(
            onPressed: onCreateTrip,
            icon: const Icon(DashboardIcons.add, size: 18),
            label: const Text('رحلة جديدة'),
          ),
        if (onRefresh != null)
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(DashboardIcons.refresh, size: 18),
            label: const Text('تحديث'),
          ),
      ],
    );
  }
}

/// Arabic only distinguishes morning from the rest of the day in everyday
/// greetings, so this is two windows, not the four an English console would
/// use — a literal "طاب مساؤك" at 6pm reads as machine-translated.
String _greetingFor(DateTime at) => at.hour < 12 ? 'صباح الخير' : 'مساء الخير';

const _arabicWeekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const _easternArabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

String _toArabicDigits(String input) {
  return input.split('').map((ch) {
    final digit = int.tryParse(ch);
    return digit == null ? ch : _easternArabicDigits[digit];
  }).join();
}

String _formatArabicDate(DateTime date) {
  final weekday = _arabicWeekdays[date.weekday - 1];
  final month = _arabicMonths[date.month - 1];
  return '$weekday، ${_toArabicDigits('${date.day}')} $month ${_toArabicDigits('${date.year}')}';
}

/// 24h clock, plain digits — matches every other timestamp in the console
/// (trip departures, table cells), which are ASCII throughout.
String _formatClock(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(at.hour)}:${two(at.minute)}';
}
