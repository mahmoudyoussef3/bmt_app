import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart';

/// Wednesday 19 August 2026, mid-afternoon. Deliberately mid-month, because
/// every interesting difference between a rolling and a calendar window
/// disappears on the last day of one.
final _now = DateTime(2026, 8, 19, 15, 30);

void main() {
  group('rolling windows', () {
    test('today is today, from midnight', () {
      final window = FinanceWindow.resolve(FinancePeriod.today, _now);

      expect(window.start, DateTime(2026, 8, 19));
      expect(window.end, _now);
    });

    test('today compares against the same hours of yesterday', () {
      // Not against the whole of yesterday: at 15:30 that would measure a
      // fifteen-hour window against a twenty-four-hour one and report a
      // collapse every single afternoon.
      final window = FinanceWindow.resolve(FinancePeriod.today, _now);
      final before = window.previous!;

      expect(before.start, DateTime(2026, 8, 18));
      expect(before.end, DateTime(2026, 8, 18, 15, 30));
    });

    test('a seven-day window counts today as one of the seven', () {
      final window = FinanceWindow.resolve(FinancePeriod.week, _now);

      expect(window.start, DateTime(2026, 8, 13));
      expect(window.range.contains(DateTime(2026, 8, 13)), isTrue);
      expect(window.range.contains(DateTime(2026, 8, 12, 23, 59)), isFalse);
    });

    test('the previous window is the same window, one length earlier', () {
      final window = FinanceWindow.resolve(FinancePeriod.month, _now);
      final before = window.previous!;

      expect(before.start, DateTime(2026, 6, 21));
      expect(before.end, DateTime(2026, 7, 20, 15, 30));
      expect(before.end.isBefore(window.start!), isTrue);
      expect(
        before.end.difference(before.start!),
        window.end.difference(window.start!),
        reason: 'both windows must be the same shape, not just the same length',
      );
    });
  });

  group('calendar windows', () {
    test('this month runs from the 1st to now, not 30 days back', () {
      // The whole reason calendar presets exist: on the 19th these two answers
      // differ by eleven days of revenue, and an owner closing a month means
      // this one.
      final window = FinanceWindow.resolve(FinancePeriod.thisMonth, _now);

      expect(window.start, DateTime(2026, 8, 1));
      expect(window.end, _now);
      expect(window.label, contains('أغسطس 2026'));
      expect(window.isComplete, isFalse);
    });

    test('last month is the whole of the previous calendar month', () {
      final window = FinanceWindow.resolve(FinancePeriod.lastMonth, _now);

      expect(window.start, DateTime(2026, 7, 1));
      expect(window.range.contains(DateTime(2026, 7, 31, 23, 59, 59)), isTrue);
      expect(window.range.contains(DateTime(2026, 8, 1)), isFalse);
      expect(window.isComplete, isTrue);
      expect(window.label, contains('يوليو 2026'));
    });

    test('month to date compares against the same span of last month', () {
      // Nineteen days against nineteen days. Comparing a partial August with
      // the whole of July would report a collapse every month.
      final window = FinanceWindow.resolve(FinancePeriod.thisMonth, _now);
      final before = window.previous!;

      expect(before.start, DateTime(2026, 7, 1));
      expect(before.end.day, 19);
      expect(window.previousLabel, 'نفس المدة من الشهر الماضي');
    });

    test('a complete month compares against the month before it', () {
      final window = FinanceWindow.resolve(FinancePeriod.lastMonth, _now);
      final before = window.previous!;

      expect(before.start, DateTime(2026, 6, 1));
      expect(before.end.month, 6);
      expect(before.end.day, 30);
      expect(window.previousLabel, contains('يونيو'));
    });

    test('January reaches back into the previous year', () {
      final january = DateTime(2027, 1, 12, 9);
      final window = FinanceWindow.resolve(FinancePeriod.thisMonth, january);

      expect(window.start, DateTime(2027, 1, 1));
      expect(window.previous!.start, DateTime(2026, 12, 1));
    });

    test('a month-to-date comparison never spills past the shorter month', () {
      // 31 March against February: the previous window has to stop at the 28th
      // rather than borrowing three days of March.
      final march31 = DateTime(2026, 3, 31, 18);
      final window = FinanceWindow.resolve(FinancePeriod.thisMonth, march31);
      final before = window.previous!;

      expect(before.start, DateTime(2026, 2, 1));
      expect(before.end.month, 2);
      expect(before.end.day, 28);
    });
  });

  group('unbounded and custom', () {
    test('all-time has no lower bound and nothing to compare to', () {
      final window = FinanceWindow.resolve(FinancePeriod.all, _now);

      expect(window.start, isNull);
      expect(window.isBounded, isFalse);
      expect(window.previous, isNull);
      expect(window.range.contains(DateTime(2019, 1, 1)), isTrue);
    });

    test('a chosen range is used verbatim and compares like for like', () {
      final window = FinanceWindow.resolve(
        FinancePeriod.custom,
        _now,
        custom: FinanceDateRange(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 10, 23, 59, 59, 999),
        ),
      );

      expect(window.start, DateTime(2026, 8, 1));
      expect(window.label, '2026/08/01 — 2026/08/10');

      final before = window.previous!;
      expect(before.end.isBefore(window.start!), isTrue);
      expect(before.start, DateTime(2026, 7, 22));
      expect(
        before.end.difference(before.start!).inDays,
        window.end.difference(window.start!).inDays,
      );
    });

    test('custom with no range falls back rather than resolving to nothing', () {
      // The cubit refuses this transition, but a window that resolved to an
      // empty range would report a confident zero, which is worse than a
      // default.
      final window = FinanceWindow.resolve(FinancePeriod.custom, _now);

      expect(window.period, FinancePeriod.month);
      expect(window.start, isNotNull);
    });
  });

  test('every preset resolves to a bounded, ordered, labelled window', () {
    for (final period in FinancePeriod.values) {
      final window = FinanceWindow.resolve(period, _now);

      expect(window.label, isNotEmpty, reason: '${period.name} has no label');
      expect(
        window.previousLabel,
        isNotEmpty,
        reason: '${period.name} has no comparison label',
      );
      final start = window.start;
      if (start != null) {
        expect(
          start.isAfter(window.end),
          isFalse,
          reason: '${period.name} starts after it ends',
        );
      }
    }
  });
}
