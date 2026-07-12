import 'package:bmt_app/apps/captain/core/widgets/captain_awaiting_trips_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required VoidCallback onRefresh}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              child: CaptainAwaitingTripsView(
                onRefresh: () async => onRefresh(),
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
}
