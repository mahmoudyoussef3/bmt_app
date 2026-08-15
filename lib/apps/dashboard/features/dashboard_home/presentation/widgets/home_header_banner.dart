import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Who is signed in, which office they are looking at, what day it is — and
/// the one action an operator starts the morning with.
///
/// Reads entirely off [OfficeContext], which the shell already resolves at
/// sign-in: no query of its own. Deliberately does not repeat the bell or a
/// profile menu — the shell's top bar and sidebar carry both, and this is the
/// screen body, not another copy of the chrome around it. The office's
/// marketplace listing state moved to the sidebar for the same reason: it is
/// standing context, not today's news.
class HomeHeaderBanner extends StatelessWidget {
  const HomeHeaderBanner({
    super.key,
    required this.office,
    this.onRefresh,
    this.onCreateTrip,
    this.onOpenBookings,
    this.now,
  });

  final OfficeContext office;
  final VoidCallback? onRefresh;

  /// Primary action. Opens the trip planner itself, not the trips list — the
  /// difference between one click and "navigate, then find the button".
  final VoidCallback? onCreateTrip;

  final VoidCallback? onOpenBookings;

  /// Injectable clock, so the greeting and the date are testable.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final at = now ?? DateTime.now();
    final officeName = office.officeName.trim().isEmpty
        ? 'مكتبك'
        : office.officeName.trim();
    final onHero = DashboardColors.onHero(context);

    return Container(
      // Deliberately shorter than a hero: the banner says who and when, and
      // every pixel it takes is a pixel of today's numbers pushed down. Same
      // trim the module headers took.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      decoration: BoxDecoration(
        gradient: DashboardColors.heroGradient(context),
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = _Identity(
            greeting: _greetingFor(at),
            name: office.displayName,
            officeName: officeName,
            date: _formatArabicDate(at),
            onHero: onHero,
          );
          final actions = _Actions(
            onCreateTrip: onCreateTrip,
            onOpenBookings: onOpenBookings,
            onRefresh: onRefresh,
            onHero: onHero,
          );

          if (constraints.maxWidth < 720) {
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
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.medium),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.greeting,
    required this.name,
    required this.officeName,
    required this.date,
    required this.onHero,
  });

  final String greeting;
  final String name;
  final String officeName;
  final String date;
  final Color onHero;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$greeting، $name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleLarge?.copyWith(
            color: onHero,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$officeName · $date',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(color: onHero.withAlpha(200)),
        ),
      ],
    );
  }
}

/// One primary action, one secondary, one utility — in that order and no more.
/// A header with five buttons makes the operator choose before they have read
/// a single number.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.onHero,
    this.onCreateTrip,
    this.onOpenBookings,
    this.onRefresh,
  });

  final Color onHero;
  final VoidCallback? onCreateTrip;
  final VoidCallback? onOpenBookings;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (onCreateTrip != null)
          FilledButton.icon(
            onPressed: onCreateTrip,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.surface,
              foregroundColor: scheme.primary,
            ),
            icon: const Icon(DashboardIcons.add, size: 18),
            label: const Text('رحلة جديدة'),
          ),
        if (onOpenBookings != null)
          OutlinedButton.icon(
            onPressed: onOpenBookings,
            style: OutlinedButton.styleFrom(
              foregroundColor: onHero,
              side: BorderSide(color: onHero.withAlpha(110)),
            ),
            icon: const Icon(DashboardIcons.bookings, size: 18),
            label: const Text('الحجوزات'),
          ),
        if (onRefresh != null)
          IconButton(
            tooltip: 'تحديث البيانات',
            onPressed: onRefresh,
            icon: const Icon(DashboardIcons.refresh, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: onHero,
              backgroundColor: onHero.withAlpha(28),
            ),
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
