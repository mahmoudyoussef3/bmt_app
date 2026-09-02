/// Visual QA harness for the EWT marketing site.
///
/// The landing page is a design import — its whole job is to look like
/// `EWT Landing v2.dc.html` — and none of that can be judged from code. Not a
/// test of behaviour: run it with `--update-goldens` and read the PNGs it
/// writes to `_captures/`.
///
///     flutter test test/landing/landing_visual_capture.dart --update-goldens
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show AssetManifest, FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bmt_app/landing/presentation/landing_page.dart';
import 'package:bmt_app/landing/presentation/sections/analytics_section.dart';
import 'package:bmt_app/landing/presentation/sections/bookings_section.dart';
import 'package:bmt_app/landing/presentation/sections/captain_section.dart';
import 'package:bmt_app/landing/presentation/sections/client_section.dart';
import 'package:bmt_app/landing/presentation/sections/comparison_section.dart';
import 'package:bmt_app/landing/presentation/sections/cta_section.dart';
import 'package:bmt_app/landing/presentation/sections/dashboard_section.dart';
import 'package:bmt_app/landing/presentation/sections/faq_section.dart';
import 'package:bmt_app/landing/presentation/sections/finance_section.dart';
import 'package:bmt_app/landing/presentation/sections/footer_section.dart';
import 'package:bmt_app/landing/presentation/sections/growth_section.dart';
import 'package:bmt_app/landing/presentation/sections/hero_section.dart';
import 'package:bmt_app/landing/presentation/sections/modules_section.dart';
import 'package:bmt_app/landing/presentation/sections/operations_section.dart';
import 'package:bmt_app/landing/presentation/sections/problem_section.dart';
import 'package:bmt_app/landing/presentation/sections/steps_section.dart';
import 'package:bmt_app/landing/presentation/sections/trust_section.dart';
import 'package:bmt_app/landing/presentation/sections/why_section.dart';
import 'package:bmt_app/landing/presentation/theme/landing_theme.dart';
import 'package:bmt_app/landing/presentation/widgets/landing_shots.dart';

/// Everything the page can mount an [Image] for.
///
/// The product shots are the part of this page a capture most needs to show,
/// and `Image.asset` decodes off the frame loop — inside `pump` it never
/// arrives, so without this every shot photographs as an empty frame.
const _images = <String>[
  'assets/images/app_icon.png',
  LandingShots.clientHome,
  LandingShots.clientSearch,
  LandingShots.clientSeats,
  LandingShots.clientTrip,
  LandingShots.clientWallet,
  LandingShots.captainMap,
  LandingShots.captainHome,
  LandingShots.captainTrip,
  LandingShots.consoleOverview,
  LandingShots.consoleHome,
  LandingShots.consoleTrips,
  LandingShots.consoleRoutes,
  LandingShots.consoleBookings,
  LandingShots.consoleFleet,
  LandingShots.consoleFinance,
  LandingShots.consoleAnalytics,
];

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();

    // google_fonts would otherwise fetch every Cairo weight over HTTP; under
    // the test binding each request 400s and reports as a test error.
    GoogleFonts.config.allowRuntimeFetching = false;
    // It resolves `Cairo_w900`-style families and falls back to the bare
    // family name, so registering one host Arabic face as `Cairo` covers every
    // weight the page asks for.
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (file.existsSync()) {
      final bytes = ByteData.sublistView(file.readAsBytesSync());
      for (final family in ['Cairo', 'Cairo_regular']) {
        await (FontLoader(family)..addFont(Future.value(bytes))).load();
      }
    }

    // Decode each asset here, in a real async pass, and park it in the image
    // cache under the key `AssetImage` will ask for. The alternative —
    // `tester.runAsync` inside each capture — opens the real event loop, and
    // google_fonts' load failure lands on it and fails the test outright.
    await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final asset in _images) {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      binding.imageCache.putIfAbsent(
        AssetBundleImageKey(bundle: rootBundle, name: asset, scale: 1),
        () => OneFrameImageStreamCompleter(
          SynchronousFuture(ImageInfo(image: frame.image)),
        ),
      );
    }
  });

  testWidgets('page — desktop', (tester) async {
    await _capture(
      tester,
      'page_desktop',
      const LandingPage(),
      width: 1440,
      height: 1000,
    );
  });

  testWidgets('page — mobile', (tester) async {
    await _capture(
      tester,
      'page_mobile',
      const LandingPage(),
      width: 430,
      height: 932,
    );
  });

  for (final (name, section, height) in <(String, Widget, double)>[
    ('hero', HeroSection(onGetStarted: _noop, onSeeDashboard: _noop), 1500),
    ('problem', ProblemSection(onSeeDashboard: _noop), 700),
    ('modules', const ModulesSection(), 620),
    ('dashboard', const DashboardSection(), 1150),
    ('operations', const OperationsSection(), 700),
    ('captain', const CaptainSection(), 800),
    ('bookings', const BookingsSection(), 750),
    ('finance', const FinanceSection(), 800),
    ('analytics', const AnalyticsSection(), 750),
    ('client', const ClientSection(), 1300),
    ('comparison', const ComparisonSection(), 700),
    ('growth', const GrowthSection(), 500),
    ('why', const WhySection(), 650),
    ('steps', StepsSection(onGetStarted: _noop), 620),
    ('trust', const TrustSection(), 450),
    ('cta', CtaSection(onGetStarted: _noop, onContact: _noop), 480),
    ('faq', const FaqSection(), 900),
    ('footer', FooterSection(onLinkTap: _ignore), 420),
  ]) {
    testWidgets('section — $name', (tester) async {
      await _capture(
        tester,
        'section_$name',
        SingleChildScrollView(child: section),
        width: 1440,
        height: height,
      );
    });
  }
}

void _noop() {}
void _ignore(String _) {}

Future<void> _capture(
  WidgetTester tester,
  String name,
  Widget child, {
  required double width,
  required double height,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  // google_fonts attempts a fetch under the test binding and logs the failure;
  // absorbing it here keeps the complaint off whichever test runs next.
  await runZonedGuarded(() async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: LandingPalette.page,
          colorScheme: ColorScheme.fromSeed(
            seedColor: LandingPalette.brand,
            brightness: Brightness.light,
            surface: LandingPalette.surface,
          ),
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: RepaintBoundary(
            key: key,
            child: Scaffold(backgroundColor: LandingPalette.page, body: child),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));
  }, (error, stack) {});

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}
