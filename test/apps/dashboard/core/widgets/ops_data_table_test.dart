import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';

Widget _host(Widget child, {bool scroll = false}) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: scroll ? SingleChildScrollView(child: child) : child,
      ),
    ),
  );
}

void main() {
  const columns = [
    OpsColumn('الاسم', flex: 2, sortable: true),
    OpsColumn('الحالة', flex: 1),
  ];

  List<List<Widget>> rowsFor(List<String> names) =>
      names.map((n) => <Widget>[Text(n), const Text('نشط')]).toList();

  testWidgets('renders headers and row cells', (tester) async {
    await tester.pumpWidget(
      _host(
        OpsDataTable(
          columns: columns,
          rows: rowsFor(const ['أحمد', 'محمد']),
          total: 2,
          currentPage: 0,
          pageSize: 8,
          onPageChanged: (_) {},
        ),
      ),
    );

    expect(find.text('الاسم'), findsOneWidget);
    expect(find.text('أحمد'), findsOneWidget);
    expect(find.text('محمد'), findsOneWidget);
  });

  testWidgets('shows empty label when no rows', (tester) async {
    await tester.pumpWidget(
      _host(
        OpsDataTable(
          columns: columns,
          rows: const [],
          total: 0,
          currentPage: 0,
          pageSize: 8,
          onPageChanged: (_) {},
          emptyLabel: 'لا يوجد سائقون',
        ),
      ),
    );

    expect(find.text('لا يوجد سائقون'), findsOneWidget);
  });

  testWidgets('renders without exception inside unbounded scroll host', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        scroll: true,
        OpsDataTable(
          columns: columns,
          rows: rowsFor(List.generate(8, (i) => 'سائق $i')),
          total: 8,
          currentPage: 0,
          pageSize: 8,
          onPageChanged: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('سائق 0'), findsOneWidget);
    expect(find.text('سائق 7'), findsOneWidget);
  });

  testWidgets('fires onSort with the tapped column index', (tester) async {
    int? sorted;
    await tester.pumpWidget(
      _host(
        OpsDataTable(
          columns: columns,
          rows: rowsFor(const ['أحمد']),
          total: 1,
          currentPage: 0,
          pageSize: 8,
          onPageChanged: (_) {},
          onSort: (i) => sorted = i,
        ),
      ),
    );

    await tester.tap(find.text('الاسم'));
    expect(sorted, 0);
  });

  testWidgets('pagination next/prev are gated by page bounds', (tester) async {
    int? requested;
    await tester.pumpWidget(
      _host(
        OpsDataTable(
          columns: columns,
          rows: rowsFor(const ['أحمد']),
          total: 16,
          currentPage: 0,
          pageSize: 8,
          onPageChanged: (p) => requested = p,
        ),
      ),
    );

    // Previous is disabled on the first page.
    await tester.tap(find.byTooltip('السابق'));
    expect(requested, isNull);

    // Next advances to page index 1.
    await tester.tap(find.byTooltip('التالي'));
    expect(requested, 1);
  });
}
