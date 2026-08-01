import 'package:bmt_app/apps/captain/core/widgets/captain_awaiting_trips_view.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required VoidCallback onRefresh,
    List<Widget> shortcuts = const [],
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              child: CaptainAwaitingTripsView(
                onRefresh: () async => onRefresh(),
                shortcuts: shortcuts,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('explains the wait and promises automatic arrival', (
    tester,
  ) async {
    await pump(tester, onRefresh: () {});
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('لا توجد رحلات مسندة بعد'), findsOneWidget);
    expect(find.text('تم تفعيل حسابك كسائق'), findsOneWidget);
    expect(find.text('بانتظار إسناد رحلة من العمليات'), findsOneWidget);
    expect(find.text('متصل بالعمليات — التحديث تلقائي'), findsOneWidget);
  });

  testWidgets('offers an explicit refresh', (tester) async {
    var refreshes = 0;
    await pump(tester, onRefresh: () => refreshes++);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('تحديث الآن'));
    await tester.pump();

    expect(refreshes, 1);
  });

  testWidgets('settles — nothing on the idle home animates forever', (
    tester,
  ) async {
    // The standby emblem used to breathe on a repeating controller. A captain's
    // phone sits in a cradle for a whole shift, so an animation that never
    // settles is a battery cost carrying no information — and it hangs
    // `pumpAndSettle` for every test that renders an empty day, which is why
    // this file used to pump a fixed duration instead.
    await pump(tester, onRefresh: () {});

    await tester.pumpAndSettle();

    expect(find.text('لا توجد رحلات مسندة بعد'), findsOneWidget);
  });

  testWidgets('an empty day is not a dead end — it offers somewhere to go', (
    tester,
  ) async {
    var opened = 0;
    await pump(
      tester,
      onRefresh: () {},
      shortcuts: [
        CaptainListRow(
          label: 'سجل رحلاتك',
          showChevron: true,
          onTap: () => opened++,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('بينما تنتظر'), findsOneWidget);
    await tester.tap(find.text('سجل رحلاتك'));
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('the onboarding home, which has no tabs yet, shows no shortcuts '
      'section at all', (tester) async {
    await pump(tester, onRefresh: () {});
    await tester.pumpAndSettle();

    expect(find.text('بينما تنتظر'), findsNothing);
  });
}
