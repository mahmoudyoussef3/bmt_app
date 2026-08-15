import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_filter_memory.dart';

void main() {
  setUp(DashboardFilterMemory.instance.clear);
  tearDown(DashboardFilterMemory.instance.clear);

  group('DashboardFilterMemory', () {
    test('a module that has never filtered reads null', () {
      expect(
        DashboardFilterMemory.instance.read<String>(DashboardFilterIds.tickets),
        isNull,
      );
    });

    test('hands back the same instance it was given', () {
      final filters = ['بانتظار المراجعة'];
      DashboardFilterMemory.instance.write(
        DashboardFilterIds.bookings,
        filters,
      );

      expect(
        DashboardFilterMemory.instance.read<List<String>>(
          DashboardFilterIds.bookings,
        ),
        same(filters),
      );
    });

    test('forget returns a module to its own defaults', () {
      DashboardFilterMemory.instance.write(DashboardFilterIds.bookings, 'x');
      DashboardFilterMemory.instance.forget(DashboardFilterIds.bookings);

      expect(
        DashboardFilterMemory.instance.read<String>(
          DashboardFilterIds.bookings,
        ),
        isNull,
      );
    });

    test('modules do not read each other', () {
      DashboardFilterMemory.instance.write(DashboardFilterIds.bookings, 'a');

      expect(
        DashboardFilterMemory.instance.read<String>(DashboardFilterIds.tickets),
        isNull,
      );
    });

    test('a type mismatch degrades to no memory rather than throwing', () {
      // If two modules ever collide on a key, the operator should see their
      // module's default filters — not a cast error over the whole screen.
      DashboardFilterMemory.instance.write(DashboardFilterIds.bookings, 'a');

      expect(
        DashboardFilterMemory.instance.read<int>(DashboardFilterIds.bookings),
        isNull,
      );
    });

    test('clear drops every module, which is what sign-out needs', () {
      DashboardFilterMemory.instance
        ..write(DashboardFilterIds.bookings, 'a')
        ..write(DashboardFilterIds.tickets, 'b');

      DashboardFilterMemory.instance.clear();

      expect(DashboardFilterMemory.instance.debugSnapshot, isEmpty);
    });
  });
}
