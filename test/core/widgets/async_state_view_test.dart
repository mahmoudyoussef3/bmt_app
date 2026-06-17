import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmt_app/core/widgets/async_state_view.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  const data = Text('المحتوى');

  testWidgets('loading shows a progress indicator', (tester) async {
    await tester.pumpWidget(
      _host(const AsyncStateView(
        status: AsyncViewStatus.loading,
        child: data,
      )),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('المحتوى'), findsNothing);
  });

  testWidgets('error shows message and retry that fires callback',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _host(AsyncStateView(
        status: AsyncViewStatus.error,
        errorMessage: 'فشل التحميل',
        onRetry: () => retried = true,
        child: data,
      )),
    );

    expect(find.text('فشل التحميل'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    expect(retried, isTrue);
  });

  testWidgets('error without onRetry hides the retry button', (tester) async {
    await tester.pumpWidget(
      _host(const AsyncStateView(
        status: AsyncViewStatus.error,
        child: data,
      )),
    );

    expect(find.text('إعادة المحاولة'), findsNothing);
  });

  testWidgets('empty shows title and optional action', (tester) async {
    await tester.pumpWidget(
      _host(AsyncStateView(
        status: AsyncViewStatus.empty,
        emptyTitle: 'لا توجد بيانات',
        emptyAction: FilledButton(onPressed: () {}, child: const Text('إضافة')),
        child: data,
      )),
    );

    expect(find.text('لا توجد بيانات'), findsOneWidget);
    expect(find.text('إضافة'), findsOneWidget);
  });

  testWidgets('data renders the child', (tester) async {
    await tester.pumpWidget(
      _host(const AsyncStateView(
        status: AsyncViewStatus.data,
        child: data,
      )),
    );

    expect(find.text('المحتوى'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
