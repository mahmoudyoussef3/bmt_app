import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
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
        LayoutBuilder(
          builder: (context, constraints) {
            final identity = _Identity(
              greeting: '${_greetingFor(at)}، ${office.displayName}',
              contextLine: _contextLine(
                officeName: officeName,
                date: at,
                tripsToday: summary.todayTripsCount,
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
        ),
        _PulseStrip(summary: summary, now: at),
      ],
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
      tripsToday == 0
          ? 'لا رحلات مجدولة اليوم'
          : '$tripsToday رحلة مجدولة اليوم',
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
        _PulseChip(
          icon: DashboardIcons.time,
          label: 'التالية',
          value:
              '${next.departure.isEmpty ? '--:--' : next.departure}'
              ' · ${next.route.isEmpty ? 'رحلة بدون مسار' : next.route}',
          tone: AppStatusTone.info,
        )
      else
        const _PulseChip(
          icon: DashboardIcons.allClear,
          label: 'الجدول',
          value: 'انتهت رحلات اليوم',
          tone: AppStatusTone.neutral,
        ),
      if (running > 0)
        _PulseChip(
          icon: DashboardIcons.liveOpsActive,
          label: 'جارية الآن',
          value: '$running',
          tone: AppStatusTone.success,
        ),
      _PulseChip(
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

/// A bare-page chip: a hairline outline, a tinted glyph, a muted caption and
/// the figure in ink. Deliberately not [DashboardStatusChip] — that badge
/// tints its whole fill, which is right for a status cell in a dense table and
/// wrong for three chips sitting directly under a page title, where three
/// filled blocks would read as three warnings.
class _PulseChip extends StatelessWidget {
  const _PulseChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = DashboardColors.status(context, tone);

    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DashboardColors.panel(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: style.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
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
