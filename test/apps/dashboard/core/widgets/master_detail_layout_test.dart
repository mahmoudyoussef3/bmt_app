import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/master_detail_layout.dart';

Widget _host({
  required double width,
  required Widget child,
  bool scroll = false,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: scroll ? SingleChildScrollView(child: child) : child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  const master = Text('قائمة السائقين');
  const detail = Text('تفاصيل السائق');

  testWidgets('desktop width shows master and detail side by side',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _host(
        width: 1300,
        child: const MasterDetailLayout(master: master, detail: detail),
      ),
    );

    expect(find.text('قائمة السائقين'), findsOneWidget);
    expect(find.text('تفاصيل السائق'), findsOneWidget);
  });

  testWidgets('desktop with no detail shows placeholder + master',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _host(
        width: 1300,
        child: const MasterDetailLayout(
          master: master,
          placeholderTitle: 'اختر سائقاً',
        ),
      ),
    );

    expect(find.text('قائمة السائقين'), findsOneWidget);
    expect(find.text('اختر سائقاً'), findsOneWidget);
  });

  testWidgets('narrow width pushes detail over master', (tester) async {
    await tester.pumpWidget(
      _host(
        width: 700,
        child: const MasterDetailLayout(master: master, detail: detail),
      ),
    );

    expect(find.text('تفاصيل السائق'), findsOneWidget);
    expect(find.text('قائمة السائقين'), findsNothing);
  });

  testWidgets('narrow width without detail shows master full width',
      (tester) async {
    await tester.pumpWidget(
      _host(
        width: 700,
        child: const MasterDetailLayout(master: master),
      ),
    );

    expect(find.text('قائمة السائقين'), findsOneWidget);
  });

  testWidgets('split renders without exception under unbounded height host',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _host(
        width: 1300,
        scroll: true,
        child: const MasterDetailLayout(master: master, detail: detail),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('تفاصيل السائق'), findsOneWidget);
  });
}
