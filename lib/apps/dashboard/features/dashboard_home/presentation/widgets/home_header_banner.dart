import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_page_title_block.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_pulse_chip.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// Who is signed in, what day it is, what the station is doing this minute, and
/// the one action an operator starts the morning with — a bare line on the
/// page, not a card.
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
/// Under it sits the **pulse strip**: what leaves next, what is already
/// rolling, and how many seats are still on sale. Three facts that are true
/// only right now, which is precisely what the KPI row underneath cannot say —
/// a KPI is a whole day's total, and "٧ رحلات اليوم" does not tell an operator
/// at 07:40 that the 08:00 is about to go. It costs one line, it is derived
/// from the trips already loaded, and it disappears entirely on a day with
/// nothing scheduled rather than printing three zeros.
///
/// Reads entirely off [OfficeContext] and [summary], both already resolved by
/// the time Home builds: no query of its own. Deliberately does not repeat the
/// bell or a profile menu — the shell's top bar and sidebar already carry both.
class HomeHeaderBanner extends StatelessWidget {
  const HomeHeaderBanner({
    super.key,
    required this.office,
    required this.summary,
    this.onRefresh,
    this.onCreateTrip,
    this.now,
    this.updatedAt,
  });

  final OfficeContext office;

  /// The loaded page. The banner reads only today's board off it — the trip
  /// count folded into the context line, and the three live facts in the pulse
  /// strip.
  final DashboardHomeSummary summary;

  final VoidCallback? onRefresh;

  /// Primary action. Opens the trip planner itself, not the trips list — the
  /// difference between one click and "navigate, then find the button".
  final VoidCallback? onCreateTrip;

  /// Injectable clock, so the greeting, the date and the pulse strip are
  /// testable.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashboardPageTitleBlock(
          title: '${_greetingFor(at)}، ${office.displayName}',
          monogramSource: officeName,
          meta: [
            officeName,
            _formatArabicDate(at),
            summary.todayTripsCount == 0
                ? 'لا رحلات مجدولة اليوم'
                : '${summary.todayTripsCount} رحلة مجدولة اليوم',
            if (updatedAt != null) 'آخر تحديث ${_formatClock(updatedAt!)}',
          ],
          actions: [
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
        ),
        _PulseStrip(summary: summary, now: at),
      ],
    );
  }
}

/// The three facts that are only true this minute. Absent entirely on a day
/// with no board — a row of zeros is not a pulse.
class _PulseStrip extends StatelessWidget {
  const _PulseStrip({required this.summary, required this.now});

  final DashboardHomeSummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (summary.todayTrips.isEmpty) return const SizedBox.shrink();

    final next = summary.nextDeparture(now: now);
    final running = summary.tripsRunningNow.length;
    final seats = summary.seatsAvailableToday(now: now);

    final chips = <Widget>[
      if (next != null)
        DashboardPulseChip(
          icon: DashboardIcons.time,
          label: 'التالية',
          value:
              '${next.departure.isEmpty ? '--:--' : next.departure}'
              ' · ${next.route.isEmpty ? 'رحلة بدون مسار' : next.route}',
          tone: AppStatusTone.info,
        )
      else
        const DashboardPulseChip(
          icon: DashboardIcons.allClear,
          label: 'الجدول',
          value: 'انتهت رحلات اليوم',
          tone: AppStatusTone.neutral,
        ),
      if (running > 0)
        DashboardPulseChip(
          icon: DashboardIcons.liveOpsActive,
          label: 'جارية الآن',
          value: '$running',
          tone: AppStatusTone.success,
        ),
      DashboardPulseChip(
        icon: DashboardIcons.seats,
        label: 'مقاعد متاحة',
        value: '$seats',
        tone: seats == 0 ? AppStatusTone.neutral : AppStatusTone.warning,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.medium),
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        children: chips,
      ),
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
