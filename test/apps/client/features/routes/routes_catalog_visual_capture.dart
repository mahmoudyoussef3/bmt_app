// Temporary visual-verification harness (not a `_test.dart`, so `flutter test`
// does not collect it). Run explicitly:
//
//   flutter test test/apps/client/features/routes/routes_catalog_visual_capture.dart \
//     --update-goldens
//
// Writes PNGs of the routes catalog in each search case — idle, an endpoint
// hit, an intermediate-station hit, and no matches — in Arabic RTL and English
// LTR, so the "يمر عبر" caption can be judged by eye rather than trusted
// because its test passes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_details.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_stop.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_summary.dart';
import 'package:bmt_app/apps/client/features/routes/domain/repositories/routes_directory_repository.dart';
import 'package:bmt_app/apps/client/features/routes/domain/usecases/get_routes_usecase.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_directory_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/screens/routes_directory_screen.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// flutter_test ships an empty font manifest, so every glyph — Arabic text and
/// Material icons alike — renders as a blank box unless real fonts are loaded.
/// Copied from `hiace_visual_capture.dart`, which needs it for the same reason.
Future<void> _loadFonts() async {
  var dir = File(Platform.resolvedExecutable).parent;
  var icons = '';
  for (var i = 0; i < 6 && icons.isEmpty; i++) {
    final candidate = File(
      '${dir.path}/material_fonts/MaterialIcons-Regular.otf',
    );
    if (candidate.existsSync()) icons = candidate.path;
    dir = dir.parent;
  }

  final fonts = <String, String>{
    'Arial': '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
    'Roboto': '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
    if (icons.isNotEmpty) 'MaterialIcons': icons,
  };

  for (final entry in fonts.entries) {
    final file = File(entry.value);
    if (!file.existsSync()) continue;
    final loader = FontLoader(entry.key)
      ..addFont(
        file.readAsBytes().then(
          (bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
        ),
      );
    await loader.load();
  }
}

List<RouteStop> _stops(List<String> names) => [
  for (var i = 0; i < names.length; i++)
    RouteStop(id: 's${i + 1}', name: names[i], order: i + 1),
];

final _arabicCatalog = <RouteSummary>[
  RouteSummary(
    id: 'A',
    name: 'خط القاهرة — المنصورة',
    startCity: 'القاهرة',
    endCity: 'المنصورة',
    distance: '١٢٠ كم',
    duration: 'ساعتان ونصف',
    officeName: 'شركة الدلتا للنقل',
    stops: _stops(['القاهرة', 'شبين الكوم', 'بنها', 'طنطا', 'المنصورة']),
  ),
  RouteSummary(
    id: 'B',
    name: 'خط القاهرة — الزقازيق',
    startCity: 'القاهرة',
    endCity: 'الزقازيق',
    distance: '٨٠ كم',
    duration: 'ساعة ونصف',
    officeName: 'شركة الشرقية',
    stops: _stops(['القاهرة', 'مسطرد', 'الزقازيق']),
  ),
  RouteSummary(
    id: 'C',
    name: 'خط القاهرة — الإسكندرية',
    startCity: 'القاهرة',
    endCity: 'الإسكندرية',
    distance: '٢٢٠ كم',
    duration: '٣ ساعات',
    officeName: 'النيل إكسبريس',
    stops: _stops(['القاهرة', 'بنها', 'طنطا', 'دمنهور', 'الإسكندرية']),
  ),
];

final _englishCatalog = <RouteSummary>[
  RouteSummary(
    id: 'A',
    name: 'Cairo — Mansoura',
    startCity: 'Cairo',
    endCity: 'Mansoura',
    distance: '120 km',
    duration: '2h 30m',
    officeName: 'Delta Lines',
    stops: _stops(['Cairo', 'Shibin El Kom', 'Banha', 'Tanta', 'Mansoura']),
  ),
  RouteSummary(
    id: 'B',
    name: 'Cairo — Zagazig',
    startCity: 'Cairo',
    endCity: 'Zagazig',
    distance: '80 km',
    duration: '1h 30m',
    officeName: 'Sharqia Transport',
    stops: _stops(['Cairo', 'Mostorod', 'Zagazig']),
  ),
];

class _FakeRepository implements RoutesDirectoryRepository {
  const _FakeRepository(this.routes);

  final List<RouteSummary> routes;

  @override
  Future<List<RouteSummary>> getRoutes() async => routes;

  @override
  Future<RouteDetails> getRouteDetails(String routeId) =>
      throw UnimplementedError();
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required List<RouteSummary> catalog,
  required String query,
  required Locale locale,
  Brightness brightness = Brightness.light,
}) async {
  final cubit = RoutesDirectoryCubit(
    GetRoutesUseCase(_FakeRepository(catalog)),
  );
  addTearDown(cubit.close);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Not `ClientTheme.light()`: it builds its text theme from google_fonts,
      // which tries to fetch Outfit over a network the test binding blocks.
      // `ClientColors`/`ClientTypography` read only the brightness and the base
      // text theme from here, so the palette on screen is still the real one —
      // the glyphs are just Arial instead of Outfit.
      theme: ThemeData(brightness: brightness, fontFamily: 'Arial'),
      home: RepaintBoundary(
        key: key,
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: ClientColors.backgroundFor(context),
            body: SafeArea(
              child: BlocProvider.value(
                value: cubit,
                child: RoutesDirectoryScreen(onOpenRoute: (_, [_]) {}),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await cubit.load();
  await tester.pump();
  if (query.isNotEmpty) {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

void main() {
  setUpAll(_loadFonts);

  // One test: each `testWidgets` re-enters the binding and the capture run
  // stalls between cases, so the whole set is rendered in a single body.
  testWidgets('routes catalog captures', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const arabic = Locale('ar');
    const english = Locale('en');

    await _capture(
      tester,
      'catalog_1_ar_idle',
      catalog: _arabicCatalog,
      query: '',
      locale: arabic,
    );

    await _capture(
      tester,
      'catalog_2_ar_via_station',
      catalog: _arabicCatalog,
      query: 'بنها',
      locale: arabic,
    );

    await _capture(
      tester,
      'catalog_3_ar_endpoint',
      catalog: _arabicCatalog,
      query: 'المنصورة',
      locale: arabic,
    );

    await _capture(
      tester,
      'catalog_4_ar_no_results',
      catalog: _arabicCatalog,
      query: 'أسوان',
      locale: arabic,
    );

    await _capture(
      tester,
      'catalog_5_ar_via_station_dark',
      catalog: _arabicCatalog,
      query: 'طنطا',
      locale: arabic,
      brightness: Brightness.dark,
    );

    await _capture(
      tester,
      'catalog_6_en_via_station',
      catalog: _englishCatalog,
      query: 'shibin',
      locale: english,
    );
  });
}
