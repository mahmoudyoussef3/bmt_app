import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/office_profile/domain/entities/office_profile.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/presentation/widgets/office_identity_form.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/presentation/widgets/office_join_code_card.dart';

/// Behaviour of the two controls the redesign introduced — the service-area
/// chip editor and the join code's credential treatment — plus the guarantees
/// the form makes about saving and read-only access.
void main() {
  OfficeProfile profile({
    String name = 'مكتب الميجا للنقل',
    String description = 'خدمة نقل يومي بين بنها والقاهرة.',
    List<String> serviceAreas = const ['بنها'],
    String? phone = '01012345678',
    String joinCode = 'MEGA4821',
    bool joinCodeReadFailed = false,
    DateTime? rotatedAt,
  }) => OfficeProfile(
    id: 'office-1',
    name: name,
    slug: 'mega-transport',
    description: description,
    serviceAreas: serviceAreas,
    status: 'active',
    listingStatus: 'listed',
    rating: 4.6,
    ratingsCount: 128,
    joinCode: joinCode,
    joinCodeReadFailed: joinCodeReadFailed,
    phone: phone,
    joinCodeRotatedAt: rotatedAt,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(1100, 2000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget form({
    required OfficeProfile value,
    bool canEdit = true,
    ValueChanged<OfficeProfileEdit>? onSave,
    OfficeProfileFormHandle? handle,
  }) => OfficeIdentityForm(
    profile: value,
    isSaving: false,
    isUploadingLogo: false,
    canEdit: canEdit,
    handle: handle,
    onSave: onSave ?? (_) {},
    onUploadLogo: (_, _) async => null,
  );

  group('service areas', () {
    testWidgets('the add chip opens an input that appends a chip', (
      tester,
    ) async {
      OfficeProfileEdit? saved;
      await pump(tester, form(value: profile(), onSave: (e) => saved = e));

      expect(find.widgetWithText(InputChip, 'طنطا'), findsNothing);

      await tester.tap(find.text('إضافة منطقة'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'مثال: القاهرة'),
        'طنطا',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(InputChip, 'طنطا'), findsOneWidget);

      await tester.tap(find.text('حفظ بيانات المكتب'));
      await tester.pumpAndSettle();

      expect(saved?.serviceAreas, ['بنها', 'طنطا']);
    });

    testWidgets('a duplicate area is dropped, whatever its case', (
      tester,
    ) async {
      await pump(tester, form(value: profile(serviceAreas: const ['Tanta'])));

      await tester.tap(find.text('إضافة منطقة'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'مثال: القاهرة'),
        'tanta',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(InputChip, 'Tanta'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'tanta'), findsNothing);
    });
  });

  group('saving', () {
    testWidgets('a broken field is listed as a button, not just refused', (
      tester,
    ) async {
      OfficeProfileEdit? saved;
      await pump(tester, form(value: profile(), onSave: (e) => saved = e));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'مكتب الميجا للنقل'),
        'م',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ بيانات المكتب'));
      await tester.pumpAndSettle();

      expect(saved, isNull);
      // The banner names the field and jumps to it — "fix the red fields" with
      // no idea which is the failure mode this replaces.
      expect(find.text('اسم المكتب'), findsWidgets);
      expect(find.byType(ActionChip), findsWidgets);
    });

    testWidgets('a blank description never blocks the save', (tester) async {
      OfficeProfileEdit? saved;
      await pump(
        tester,
        form(
          value: profile(description: ''),
          onSave: (e) => saved = e,
        ),
      );

      await tester.tap(find.text('حفظ بيانات المكتب'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.description, isEmpty);
    });

    testWidgets('the unsaved marker appears only once something changed', (
      tester,
    ) async {
      final handle = OfficeProfileFormHandle();
      await pump(tester, form(value: profile(), handle: handle));

      expect(find.text('تغييرات غير محفوظة'), findsNothing);
      expect(handle.hasUnsavedChanges, isFalse);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'مكتب الميجا للنقل'),
        'مكتب الميجا للنقل والسفر',
      );
      await tester.pumpAndSettle();

      expect(find.text('تغييرات غير محفوظة'), findsOneWidget);
      expect(handle.hasUnsavedChanges, isTrue);
    });

    testWidgets('a support agent gets the data without the controls', (
      tester,
    ) async {
      await pump(tester, form(value: profile(), canEdit: false));

      expect(find.text('حفظ بيانات المكتب'), findsNothing);
      expect(find.text('إضافة منطقة'), findsNothing);
      expect(
        find.text('العرض فقط — تعديل بيانات المكتب متاح لحساب المالك.'),
        findsOneWidget,
      );
      // The values themselves are still on screen — read-only is not hidden.
      expect(find.text('مكتب الميجا للنقل'), findsWidgets);
    });
  });

  group('join code card', () {
    Widget card(
      OfficeProfile value, {
      bool canRotate = true,
      VoidCallback? onRotate,
    }) => OfficeJoinCodeCard(
      profile: value,
      canRotate: canRotate,
      isRotating: false,
      onRotate: onRotate ?? () {},
      onRetry: () {},
    );

    testWidgets('the code is masked until it is asked for', (tester) async {
      await pump(tester, card(profile()));

      expect(find.text('MEGA4821'), findsNothing);
      expect(find.text('••••••••'), findsOneWidget);

      await tester.tap(find.byTooltip('إظهار الكود'));
      await tester.pumpAndSettle();

      expect(find.text('MEGA4821'), findsOneWidget);
    });

    testWidgets('rotation is confirmed before anything is issued', (
      tester,
    ) async {
      var rotations = 0;
      await pump(tester, card(profile(), onRotate: () => rotations++));

      await tester.tap(find.text('تدوير الكود'));
      await tester.pumpAndSettle();
      expect(find.text('تدوير كود الانضمام؟'), findsOneWidget);

      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(rotations, 0);

      await tester.tap(find.text('تدوير الكود'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إصدار كود جديد'));
      await tester.pumpAndSettle();

      expect(rotations, 1);
    });

    testWidgets('a support agent can copy but not rotate', (tester) async {
      await pump(tester, card(profile(), canRotate: false));

      expect(find.text('نسخ الكود'), findsOneWidget);
      expect(find.text('تدوير الكود'), findsNothing);
    });

    testWidgets('a failed read is not dressed up as a missing code', (
      tester,
    ) async {
      await pump(tester, card(profile(joinCode: '', joinCodeReadFailed: true)));

      expect(find.textContaining('تعذّر قراءة كود الانضمام'), findsOneWidget);
      expect(find.textContaining('لم يُصدر كود'), findsNothing);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });

    testWidgets('no code at all offers to issue one', (tester) async {
      await pump(tester, card(profile(joinCode: '')));

      expect(find.textContaining('لم يُصدر كود'), findsOneWidget);
      expect(find.text('إصدار كود'), findsOneWidget);
    });

    testWidgets('the rotation date is shown only when the database gave one', (
      tester,
    ) async {
      await pump(tester, card(profile()));
      expect(find.textContaining('آخر تدوير'), findsNothing);

      await pump(
        tester,
        card(
          profile(rotatedAt: DateTime.now().subtract(const Duration(days: 96))),
        ),
      );
      expect(find.textContaining('آخر تدوير'), findsOneWidget);
    });
  });
}
