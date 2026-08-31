/// Visual QA harness for «الباقات والميزات».
///
/// The plan workspace is the console's densest editing surface — forty-seven
/// rows of typed controls under a product header — and the things that were
/// wrong with it (a hand-span of empty space between a feature's name and its
/// switch, two filter axes wearing identical chips, a price pill indistinguish-
/// able from a trial pill) are claims you can only settle by looking. Not a
/// test of behaviour and deliberately not part of the suite's assertions: run
/// it with `--update-goldens` and read the PNGs it writes to `_captures/`.
///
///     flutter test test/apps/dashboard/features/platform_licensing/platform_catalog_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/entities/licensing_catalog.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_state.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/screens/platform_catalog_screen.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';

const _captureFont = 'CaptureArabic';

/// Resolved by walking up from the running test binary until the SDK's font
/// cache appears: `flutter_tester` sits at a different depth per platform, so
/// counting `.parent`s is a guess that breaks on someone else's machine.
File? _findMaterialIcons() {
  const suffix = 'artifacts/material_fonts/MaterialIcons-Regular.otf';
  var dir = File(Platform.resolvedExecutable).parent;
  for (var hop = 0; hop < 8; hop++) {
    final candidate = File('${dir.path}/$suffix');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}

class _FakeLicensingCubit extends Cubit<PlatformLicensingState>
    implements PlatformLicensingCubit {
  _FakeLicensingCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

const _categories = [
  FeatureCategory(key: 'ops', nameAr: 'التشغيل', sortOrder: 1),
  FeatureCategory(key: 'sales', nameAr: 'المبيعات والعملاء', sortOrder: 2),
  FeatureCategory(key: 'fleet', nameAr: 'الأسطول', sortOrder: 3),
  FeatureCategory(key: 'finance', nameAr: 'المالية', sortOrder: 4),
];

/// Shaped after the real catalog: a mix of switches, limits with units, and a
/// couple of features with no code behind them yet.
const _features = <CatalogFeature>[
  CatalogFeature(
    key: 'trips',
    nameAr: 'الرحلات',
    nameEn: 'trips',
    descriptionAr:
        'إنشاء الرحلات وجدولتها وبيع تذاكرها — القدرة الأساسية التي يقوم '
        'عليها المكتب.',
    categoryKey: 'ops',
    valueType: 'boolean',
    defaultValue: true,
    status: 'active',
    isEnforced: true,
    sortOrder: 1,
  ),
  CatalogFeature(
    key: 'routes',
    nameAr: 'خطوط السير',
    nameEn: 'routes',
    descriptionAr: 'بناء الخطوط ومحطاتها وأسعار المسافات بينها.',
    categoryKey: 'ops',
    valueType: 'boolean',
    defaultValue: true,
    status: 'active',
    isEnforced: true,
    sortOrder: 2,
  ),
  CatalogFeature(
    key: 'max_routes',
    nameAr: 'حد خطوط السير',
    nameEn: 'max routes',
    descriptionAr: 'أقصى عدد خطوط سير فعّالة في وقت واحد.',
    categoryKey: 'ops',
    valueType: 'limit',
    defaultValue: 3,
    unitAr: 'خط',
    meterKind: 'stock',
    status: 'active',
    isEnforced: true,
    sortOrder: 3,
  ),
  CatalogFeature(
    key: 'max_trips_per_month',
    nameAr: 'حد الرحلات شهريًا',
    nameEn: 'max trips per month',
    descriptionAr: 'عدّاد تراكمي يُصفَّر مع بداية كل شهر ميلادي.',
    categoryKey: 'ops',
    valueType: 'limit',
    defaultValue: 60,
    unitAr: 'رحلة',
    meterKind: 'flow',
    meterPeriod: 'month',
    status: 'active',
    isEnforced: true,
    sortOrder: 4,
  ),
  CatalogFeature(
    key: 'max_live_trips',
    nameAr: 'حد الرحلات الجارية',
    nameEn: 'max live trips',
    descriptionAr: 'كم رحلة يمكن أن تكون على الطريق في اللحظة نفسها.',
    categoryKey: 'ops',
    valueType: 'limit',
    defaultValue: 2,
    unitAr: 'رحلة',
    meterKind: 'stock',
    status: 'active',
    isEnforced: true,
    sortOrder: 5,
  ),
  CatalogFeature(
    key: 'live_tracking',
    nameAr: 'التتبع المباشر',
    nameEn: 'live tracking',
    descriptionAr: 'بث موقع المركبة للراكب وللمكتب أثناء الرحلة.',
    categoryKey: 'ops',
    valueType: 'boolean',
    defaultValue: false,
    status: 'active',
    isEnforced: true,
    sortOrder: 6,
  ),
  CatalogFeature(
    key: 'live_ops_center',
    nameAr: 'مركز التشغيل المباشر',
    nameEn: 'live ops center',
    descriptionAr:
        'شاشة المتابعة اللحظية للرحلات النشطة وحالة التتبع وبلاغات الكباتن.',
    categoryKey: 'ops',
    valueType: 'boolean',
    defaultValue: false,
    status: 'active',
    isEnforced: false,
    sortOrder: 7,
  ),
  CatalogFeature(
    key: 'customers',
    nameAr: 'ملف العميل',
    nameEn: 'customers',
    descriptionAr: 'سجل العميل الكامل: حجوزاته واشتراكاته ومحفظته وتذاكره.',
    categoryKey: 'sales',
    valueType: 'boolean',
    defaultValue: true,
    status: 'active',
    isEnforced: true,
    sortOrder: 1,
  ),
  CatalogFeature(
    key: 'passenger_packages',
    nameAr: 'باقات الركاب',
    nameEn: 'passenger packages',
    descriptionAr: 'بيع باقات رحلات متعددة للراكب بسعر مخفّض عن التذكرة.',
    categoryKey: 'sales',
    valueType: 'boolean',
    defaultValue: false,
    status: 'active',
    isEnforced: true,
    sortOrder: 2,
  ),
  CatalogFeature(
    key: 'marketplace_listing',
    nameAr: 'العرض في السوق',
    nameEn: 'marketplace listing',
    descriptionAr: 'ظهور المكتب ورحلاته لركاب التطبيق خارج عملائه الحاليين.',
    categoryKey: 'sales',
    valueType: 'boolean',
    defaultValue: false,
    status: 'active',
    isEnforced: true,
    sortOrder: 3,
  ),
  CatalogFeature(
    key: 'loyalty',
    nameAr: 'برنامج الولاء',
    nameEn: 'loyalty',
    categoryKey: 'sales',
    valueType: 'boolean',
    defaultValue: false,
    status: 'active',
    isEnforced: false,
    sortOrder: 4,
  ),
  CatalogFeature(
    key: 'max_drivers',
    nameAr: 'حد السائقين',
    nameEn: 'max drivers',
    descriptionAr: 'عدد السائقين المسجَّلين في المكتب.',
    categoryKey: 'fleet',
    valueType: 'limit',
    defaultValue: 5,
    unitAr: 'سائق',
    meterKind: 'stock',
    status: 'active',
    isEnforced: true,
    sortOrder: 1,
  ),
  CatalogFeature(
    key: 'max_vehicles',
    nameAr: 'حد المركبات',
    nameEn: 'max vehicles',
    descriptionAr: 'عدد المركبات في أسطول المكتب.',
    categoryKey: 'fleet',
    valueType: 'limit',
    defaultValue: 5,
    unitAr: 'مركبة',
    meterKind: 'stock',
    status: 'active',
    isEnforced: true,
    sortOrder: 2,
  ),
  CatalogFeature(
    key: 'fleet_documents',
    nameAr: 'وثائق الأسطول',
    nameEn: 'fleet documents',
    descriptionAr: 'رفع رخص السائقين والمركبات وتنبيه انتهائها.',
    categoryKey: 'fleet',
    valueType: 'boolean',
    defaultValue: true,
    status: 'active',
    isEnforced: true,
    sortOrder: 3,
  ),
  CatalogFeature(
    key: 'wallet',
    nameAr: 'محفظة العملاء',
    nameEn: 'wallet',
    descriptionAr: 'رصيد قابل للإنفاق داخل التطبيق، بدفتر حركات مزدوج القيد.',
    categoryKey: 'finance',
    valueType: 'boolean',
    defaultValue: false,
    status: 'active',
    isEnforced: true,
    sortOrder: 1,
  ),
  CatalogFeature(
    key: 'refunds',
    nameAr: 'طلبات الاسترداد',
    nameEn: 'refunds',
    descriptionAr: 'استقبال طلبات استرداد الركاب والبتّ فيها من لوحة المكتب.',
    categoryKey: 'finance',
    valueType: 'boolean',
    defaultValue: false,
    status: 'active',
    isEnforced: true,
    sortOrder: 2,
  ),
  CatalogFeature(
    key: 'cashback',
    nameAr: 'الاسترداد النقدي',
    nameEn: 'cashback',
    descriptionAr: 'نسبة تُعاد إلى محفظة الراكب بعد كل رحلة مكتملة.',
    categoryKey: 'finance',
    valueType: 'boolean',
    defaultValue: false,
    status: 'disabled',
    isEnforced: true,
    sortOrder: 3,
  ),
  CatalogFeature(
    key: 'finance_reports',
    nameAr: 'التقارير المالية',
    nameEn: 'finance reports',
    descriptionAr: 'كشوف الإيراد والتحصيل والذمم، وتصديرها.',
    categoryKey: 'finance',
    valueType: 'boolean',
    defaultValue: true,
    status: 'active',
    isEnforced: true,
    sortOrder: 4,
  ),
];

const _catalog = FeatureCatalog(categories: _categories, features: _features);

const _plan = LicensingPlan(
  id: 'plan-starter',
  key: 'starter',
  nameAr: 'الأساسية',
  nameEn: 'Starter',
  taglineAr:
      'لمكتب يبدأ بخط أو خطين ويريد بيع التذاكر ومتابعة رحلاته بلا أدوات '
      'تشغيل متقدمة.',
  status: 'active',
  isPublic: true,
  priceMonthly: 1500,
  priceYearly: 16500,
  trialDays: 0,
  officeCount: 0,
  revision: 3,
);

PlanDetail get _detail => PlanDetail(
  plan: _plan,
  values: const {
    'trips': true,
    'routes': true,
    'max_routes': 5,
    'max_trips_per_month': 100,
    'max_live_trips': 3,
    'live_tracking': true,
    'live_ops_center': false,
    'customers': true,
    'passenger_packages': true,
    'marketplace_listing': true,
    'max_drivers': 12,
    'max_vehicles': FeatureValue.unlimited,
    'fleet_documents': true,
    'wallet': false,
    'refunds': true,
  },
  offices: const [],
  revisions: const [],
);

PlatformLicensingLoaded get _state => PlatformLicensingLoaded(
  catalog: _catalog,
  plans: const [_plan],
  selectedPlan: _detail,
);

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (file.existsSync()) {
      final loader = FontLoader(_captureFont)
        ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      await loader.load();
    }
    final icons = _findMaterialIcons();
    if (icons != null) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
      await loader.load();
    }
  });

  setUp(DashboardSectionStateStore.instance.clear);

  testWidgets('the plan workspace on a wide console', (tester) async {
    await _capture(tester, 'catalog_1_workspace_wide', const Size(1920, 1200));
  });

  testWidgets('the plan workspace on a laptop', (tester) async {
    await _capture(
      tester,
      'catalog_2_workspace_laptop',
      const Size(1280, 1100),
    );
  });

  testWidgets('the plan workspace on a narrow console', (tester) async {
    await _capture(tester, 'catalog_3_workspace_narrow', const Size(880, 1200));
  });

  testWidgets('the plan workspace with unsaved edits', (tester) async {
    await _capture(
      tester,
      'catalog_4_workspace_dirty',
      const Size(1920, 1200),
      dirty: true,
    );
  });
}

Future<void> _capture(
  WidgetTester tester,
  String name,
  Size size, {
  bool dirty = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider<PlatformLicensingCubit>.value(
          value: _FakeLicensingCubit(_state),
          child: const Scaffold(body: PlatformCatalogScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  if (dirty) {
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
  }

  await expectLater(
    find.byType(PlatformCatalogScreen),
    matchesGoldenFile('_captures/$name.png'),
  );
}

/// Rebuilt from the palette rather than taken from `DashboardAppTheme`: that
/// one builds its type through google_fonts, which fetches over the blocked
/// test network and throws *after* the test completes.
ThemeData _theme() {
  final scheme = lightColorSchemeFromPalette();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: const Color(0xFFF5F6F8),
    canvasColor: const Color(0xFFF5F6F8),
    cardColor: scheme.surface,
    dividerColor: scheme.outlineVariant,
    extensions: [AppSurfaceStyle.flat(scheme)],
  );
}
