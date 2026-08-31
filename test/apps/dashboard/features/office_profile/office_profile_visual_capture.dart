/// Visual QA harness for ملف المكتب — the office's own record, and the only
/// long form in النظام.
///
/// Not a test of behaviour and deliberately not part of the suite's assertions:
/// run it with `--update-goldens` and look at the PNGs it writes to
/// `_captures/`.
///
///     flutter test test/apps/dashboard/features/office_profile/office_profile_visual_capture.dart --update-goldens
///
/// Unlike the older console captures, this one typesets with the **real**
/// [DashboardAppTheme] — every component style the form's fields, chips and
/// buttons actually get — by registering a host Arabic face under the family
/// names google_fonts asks for (`Cairo_regular`, falling back to `Cairo`).
/// Without that the binding draws every glyph as a box and the capture judges
/// nothing but layout.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/domain/entities/office_profile.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/domain/repositories/office_profile_repository.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/domain/usecases/office_profile_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/presentation/cubit/office_profile_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/presentation/screens/office_profile_screen.dart';

OfficeProfile _profile({
  String description =
      'خدمة نقل يومي مكيّف بين بنها والقاهرة الكبرى، بمواعيد ثابتة ومقاعد محجوزة.',
  String? logoUrl,
  String? phone = '01023 4567',
  List<String> serviceAreas = const [
    'بنها',
    'القرية الذكية',
    'مدينة نصر',
    'المهندسين',
  ],
  String listingStatus = 'draft',
  DateTime? rotatedAt,
}) => OfficeProfile(
  id: 'office-1',
  name: 'مكتب الميجا للنقل',
  slug: 'mega-transport',
  description: description,
  serviceAreas: serviceAreas,
  status: 'active',
  listingStatus: listingStatus,
  rating: 4.6,
  ratingsCount: 128,
  joinCode: 'MEGA4821',
  logoUrl: logoUrl,
  phone: phone,
  joinCodeRotatedAt: rotatedAt,
  updatedAt: DateTime(2026, 8, 30),
);

void main() {
  late ThemeData light;
  late ThemeData dark;

  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (file.existsSync()) {
      final bytes = ByteData.sublistView(file.readAsBytesSync());
      for (final family in const ['Cairo_regular', 'Cairo']) {
        await (FontLoader(family)..addFont(Future.value(bytes))).load();
      }
    }

    // The real theme reaches for Cairo through google_fonts, whose fetch the
    // test binding refuses — google_fonts swallows that failure itself, and the
    // families registered above then resolve the styles to the host face. (Do
    // not turn `allowRuntimeFetching` off to skip the attempt: that path throws
    // instead of logging, and the throw lands on whichever test is running.)
    await runZonedGuarded(() async {
      light = DashboardAppTheme.light();
      dark = DashboardAppTheme.dark();
    }, (_, _) {});
  });

  setUp(DashboardSectionStateStore.instance.clear);

  testWidgets('owner, draft office with an incomplete card — light', (
    tester,
  ) async {
    await _capture(
      tester,
      'office_profile_1_owner_light',
      theme: light,
      profile: _profile(),
      height: 2400,
    );
  });

  testWidgets('owner, listed office with a complete card — dark', (
    tester,
  ) async {
    await _capture(
      tester,
      'office_profile_2_owner_dark',
      theme: dark,
      profile: _profile(
        listingStatus: 'listed',
        logoUrl: 'https://cdn.example.com/logo.png',
        rotatedAt: DateTime.now().subtract(const Duration(days: 96)),
      ),
      height: 2400,
    );
  });

  testWidgets('support agent — read only', (tester) async {
    await _capture(
      tester,
      'office_profile_3_read_only_light',
      theme: light,
      profile: _profile(),
      canEdit: false,
      height: 2200,
    );
  });

  testWidgets('narrow window — the bands stack', (tester) async {
    await _capture(
      tester,
      'office_profile_4_narrow_light',
      theme: light,
      profile: _profile(description: '', phone: null, serviceAreas: const []),
      width: 720,
      height: 2400,
    );
  });
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required ThemeData theme,
  required OfficeProfile profile,
  double width = 1280,
  double height = 2200,
  bool canEdit = true,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repo = _StaticRepo(profile);
  final cubit = OfficeProfileCubit(
    getProfile: GetOfficeProfileUseCase(repo),
    updateProfile: UpdateOfficeProfileUseCase(repo),
    uploadLogo: UploadOfficeLogoUseCase(repo),
    rotateJoinCode: RotateOfficeJoinCodeUseCase(repo),
  );
  addTearDown(cubit.close);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: BlocProvider.value(
              value: cubit..load(),
              child: OfficeProfileScreen(canEdit: canEdit),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

class _StaticRepo implements OfficeProfileRepository {
  _StaticRepo(this.profile);

  final OfficeProfile profile;

  @override
  Future<OfficeProfile> getProfile() async => profile;

  @override
  Future<OfficeProfile> updateProfile(OfficeProfileEdit edit) async => profile;

  @override
  Future<String> uploadLogo({
    required Uint8List bytes,
    required String fileName,
  }) async => 'https://cdn.example.com/$fileName';

  @override
  Future<OfficeProfile> rotateJoinCode() async => profile;
}
