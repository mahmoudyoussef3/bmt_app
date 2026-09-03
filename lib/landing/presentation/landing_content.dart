import 'package:flutter/material.dart';

import 'theme/landing_theme.dart';
import 'widgets/landing_shots.dart';

/// Every string and figure the landing page renders, lifted verbatim from the
/// `EWT Landing v2` design file's `renderVals()` block.
///
/// The page is a product shot: none of this is live data, and putting it in
/// one place keeps the section widgets to layout only — so a copy change is a
/// one-line edit here rather than a hunt through fifteen widget files.
class LandingContent {
  const LandingContent._();

  // ── Hero ────────────────────────────────────────────────────────────────
  static const heroBadge = 'نظام إدارة مكاتب النقل في مصر';
  static const heroHeadlineLead = 'إدارة مكتب النقل بالكامل، ';
  static const heroHeadlineAccent = 'من مكان واحد.';
  static const heroBody =
      'EWT تساعدك على إدارة الرحلات والخطوط والكباتن والحجوزات والمدفوعات، '
      'ومتابعة أداء مكتبك من خلال نظام واحد مصمم لعمليات النقل.';
  static const heroPrimaryCta = 'ابدأ إدارة مكتبك مع EWT';
  static const heroSecondaryCta = 'شاهد كيف تعمل المنصة';

  /// The key under the hero's three-device rig, in the order the rig lays
  /// them out on a wide screen (right → left in RTL): captain phone, console,
  /// rider phone. Without it the reader sees three screens and has to guess
  /// which app is which.
  static const heroSurfaces = <LandingPoint>[
    LandingPoint(icon: Icons.badge_rounded, title: 'تطبيق الكابتن', body: ''),
    LandingPoint(
      icon: Icons.dashboard_rounded,
      title: 'لوحة تحكم المكتب',
      body: '',
    ),
    LandingPoint(
      icon: Icons.phone_iphone_rounded,
      title: 'تطبيق الراكب',
      body: '',
    ),
  ];

  static const heroTrust = <LandingPoint>[
    LandingPoint(
      icon: Icons.tune_rounded,
      title: 'تحكم كامل',
      body: 'في عمليات مكتبك',
    ),
    LandingPoint(
      icon: Icons.visibility_rounded,
      title: 'رؤية واضحة',
      body: 'للحجوزات والرحلات والإيرادات',
    ),
    LandingPoint(
      icon: Icons.checklist_rounded,
      title: 'تشغيل أكثر تنظيمًا',
      body: 'بدون الاعتماد على المتابعة اليدوية',
    ),
    LandingPoint(
      icon: Icons.trending_up_rounded,
      title: 'نظام قابل للتوسع',
      body: 'ينمو مع مكتبك',
    ),
  ];

  // ── Hero product board ──────────────────────────────────────────────────
  /// The demo office the hero's three drawn screens report on.
  ///
  /// The rig used to embed real captures. At hero size the console capture is
  /// a wall of 9px type nobody reads, so the fold now draws a *reduced* board
  /// instead — the same screens, cut down to the four numbers, the three trips
  /// and the one chart a reader can actually take in at a glance. Everything
  /// below the fold is still photographed (see `LandingShots`), which is what
  /// keeps this board a summary rather than a claim: no figure here is stated
  /// beside a screenshot that contradicts it.
  static const boardConsoleTitle = 'لوحة تحكم EWT · مكتب الميجا للنقل';
  static const boardConsoleStamp = 'تحديث مباشر · 12 مارس 2026';
  static const boardOverview = 'نظرة عامة';

  /// Right → left, the way the segmented control reads in RTL.
  static const boardPeriods = <String>['اليوم', 'الأسبوع', 'الشهر'];

  static const boardKpis = <LandingKpi>[
    LandingKpi(
      icon: Icons.alt_route_rounded,
      label: 'رحلات اليوم',
      value: '24',
      unit: 'رحلة',
      delta: '+3 عن أمس',
      deltaColor: LandingPalette.good,
    ),
    LandingKpi(
      icon: Icons.event_seat_rounded,
      label: 'إجمالي الحجوزات',
      value: '186',
      unit: 'حجز',
      delta: '+12% هذا الأسبوع',
      deltaColor: LandingPalette.good,
    ),
    LandingKpi(
      icon: Icons.donut_small_rounded,
      label: 'نسبة الإشغال',
      value: '87%',
      delta: '+4% عن الأسبوع الماضي',
      deltaColor: LandingPalette.good,
    ),
    LandingKpi(
      icon: Icons.payments_rounded,
      label: 'إيرادات اليوم',
      value: '42,850',
      unit: 'ج.م',
      delta: '38,200 محصلة',
    ),
  ];

  static const boardTripsTitle = 'الرحلات القادمة';
  static const boardTripsAction = 'عرض الكل';
  static const boardTrips = <LandingBoardTrip>[
    LandingBoardTrip(
      origin: 'القاهرة',
      destination: 'الإسكندرية',
      meta: '08:30 ص · كابتن محمود',
      seats: '12 / 14',
      status: 'مؤكدة',
      tone: LandingTone.good,
    ),
    LandingBoardTrip(
      origin: 'القاهرة',
      destination: 'المنصورة',
      meta: '10:00 ص · كابتن سيد',
      seats: '11 / 14',
      status: 'قادمة',
      tone: LandingTone.brand,
    ),
    LandingBoardTrip(
      origin: 'القاهرة',
      destination: 'طنطا',
      meta: '12:30 م · كابتن رمضان',
      seats: '14 / 14',
      status: 'مكتملة الحجز',
      tone: LandingTone.warn,
    ),
  ];

  static const boardChartTitle = 'الحجوزات خلال الأسبوع';
  static const boardChartTotal = 'إجمالي 1,184 حجز';

  /// Bar heights in [LandingBarChart]'s own 130-unit view box, and the week
  /// running left → right the way every other chart on this page runs.
  static const boardChartHeights = <double>[51, 66, 56, 76, 70, 92, 84];
  static const boardChartLabels = <String>[
    'سبت',
    'أحد',
    'اثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
  ];

  // The rider phone in the rig.
  static const boardRiderApp = 'تطبيق العميل';
  static const boardRiderTitle = 'رحلتك القادمة تبدأ من هنا';
  static const boardRiderFrom = 'القاهرة';
  static const boardRiderTo = 'الإسكندرية';
  static const boardRiderSearch = 'ابحث عن رحلة';
  static const boardRiderBooking = 'حجزك الحالي';
  static const boardRiderOrigin = 'موقف عبود';
  static const boardRiderDestination = 'سيدي جابر';
  static const boardRiderDepart =
      'الانطلاق 13:00 · كن في نقطة الانطلاق قبل 10 دقائق';
  static const boardRiderSeat = 'المقعد A3';
  static const boardRiderStatus = 'مؤكدة';
  static const boardRiderTrack = 'تتبع الرحلة';

  // The captain phone in the rig.
  static const boardCaptainLive = 'رحلة جارية · كابتن محمود';
  static const boardCaptainOrigin = 'القاهرة';
  static const boardCaptainDestination = 'الإسكندرية';
  static const boardCaptainVehicle = 'تويوتا هايبس · ق ٢٧ م';
  static const boardCaptainChips = <({String value, String label})>[
    (value: '13:00', label: 'التوقيت'),
    (value: '7 / 11', label: 'صعدوا'),
    (value: '2 / 5', label: 'المحطات'),
  ];
  static const boardCaptainNext = 'المحطة القادمة';
  static const boardCaptainStop = 'استراحة كيلو 100';
  static const boardCaptainEta = 'الوصول المتوقع 14:40';
  static const boardCaptainProgress = 0.62;
  static const boardCaptainProgressLabel = '62%';
  static const boardCaptainCta = 'تسجيل الوصول للمحطة';

  // ── Problem ─────────────────────────────────────────────────────────────
  static const problems = <LandingPoint>[
    LandingPoint(
      icon: Icons.scatter_plot_rounded,
      title: 'حجوزات متفرقة',
      body: 'صعوبة معرفة حالة كل حجز ومقعد.',
    ),
    LandingPoint(
      icon: Icons.schedule_rounded,
      title: 'متابعة الرحلات',
      body: 'صعوبة معرفة حالة الرحلات والكباتن في الوقت المناسب.',
    ),
    LandingPoint(
      icon: Icons.help_outline_rounded,
      title: 'أرقام غير واضحة',
      body: 'صعوبة متابعة الإيرادات والمدفوعات والمصروفات.',
    ),
    LandingPoint(
      icon: Icons.phone_in_talk_rounded,
      title: 'تشغيل يعتمد عليك',
      body: 'كل قرار وكل متابعة تحتاج تدخل منك.',
    ),
  ];

  // ── Modules ─────────────────────────────────────────────────────────────
  static const modulesStart = <LandingPoint>[
    LandingPoint(icon: Icons.route_rounded, title: 'الرحلات', body: ''),
    LandingPoint(icon: Icons.alt_route_rounded, title: 'الخطوط', body: ''),
    LandingPoint(icon: Icons.badge_rounded, title: 'الكباتن', body: ''),
    LandingPoint(icon: Icons.event_seat_rounded, title: 'الحجوزات', body: ''),
  ];
  static const modulesEnd = <LandingPoint>[
    LandingPoint(icon: Icons.payments_rounded, title: 'المدفوعات', body: ''),
    LandingPoint(icon: Icons.bar_chart_rounded, title: 'التقارير', body: ''),
    LandingPoint(
      icon: Icons.manage_accounts_rounded,
      title: 'المستخدمين',
      body: '',
    ),
    LandingPoint(icon: Icons.group_rounded, title: 'العملاء', body: ''),
  ];
  static const coreMini = <({String label, String value})>[
    (label: 'رحلات اليوم', value: '24'),
    (label: 'الحجوزات', value: '186'),
    (label: 'الإشغال', value: '87%'),
    (label: 'الإيرادات', value: '42.8 أ'),
  ];

  // ── Dashboard section ───────────────────────────────────────────────────
  static const dashboardTabs = <LandingDashboardTab>[
    LandingDashboardTab(
      label: 'نظرة عامة',
      caption: 'الرحلات والحجوزات والتحصيل في شاشة واحدة، محدّثة طول اليوم.',
      shot: LandingShots.consoleHome,
    ),
    LandingDashboardTab(
      label: 'الرحلات',
      caption: 'كل رحلة بحالتها وكابتنها وعربيتها وعدد مقاعدها المحجوزة.',
      shot: LandingShots.consoleTrips,
    ),
    LandingDashboardTab(
      label: 'المسارات',
      caption: 'خطوطك ومحطاتها ومواعيدها، وأسعار كل مشوار بينها.',
      shot: LandingShots.consoleRoutes,
    ),
    LandingDashboardTab(
      label: 'الحجوزات',
      caption: 'مين حجز، على أي رحلة، وأي مقعد، وحالة الدفع.',
      shot: LandingShots.consoleBookings,
    ),
    LandingDashboardTab(
      label: 'الأسطول',
      caption: 'عربياتك وسائقينك ومستنداتهم، ومين مسند على إيه.',
      shot: LandingShots.consoleFleet,
    ),
    LandingDashboardTab(
      label: 'المالية',
      caption: 'التحصيل والمدفوعات والمصروفات، ومنين جه كل جنيه.',
      shot: LandingShots.consoleFinance,
    ),
    LandingDashboardTab(
      label: 'التقارير',
      caption: 'أداء الخطوط والإشغال والإيراد عبر الفترة اللي تختارها.',
      shot: LandingShots.consoleAnalytics,
    ),
  ];

  // ── Operations («المميزات») ─────────────────────────────────────────────
  /// The eight modules an office runs, in the same two groups the platform
  /// diagram above names them in — and each one pointing at the band further
  /// down the page that shows it working, so the features section reads as the
  /// page's index rather than a wall of equal cards.
  static const operationGroups = <LandingFeatureGroup>[
    LandingFeatureGroup(
      index: '٠١',
      label: 'التشغيل اليومي',
      caption: 'من إنشاء الخط لحد إقفال الرحلة',
      features: [
        LandingFeature(
          icon: Icons.alt_route_rounded,
          title: 'إدارة الخطوط',
          body: 'أنشئ خطوط النقل ونقاط الانطلاق والوصول ونظّم رحلاتك بسهولة.',
          capabilities: ['المحطات والمواعيد', 'سعر كل مشوار'],
          target: LandingFeatureTarget.dashboard,
          targetLabel: 'شوفها في لوحة التحكم',
        ),
        LandingFeature(
          icon: Icons.route_rounded,
          title: 'إدارة الرحلات',
          body: 'أنشئ الرحلات وحدد مواعيدها وكباتنها وتابع حالتها.',
          capabilities: ['كابتن وعربية', 'حالة الرحلة'],
          target: LandingFeatureTarget.dashboard,
          targetLabel: 'شوفها في لوحة التحكم',
        ),
        LandingFeature(
          icon: Icons.badge_rounded,
          title: 'إدارة الكباتن',
          body: 'اعرف الكابتن المسؤول عن كل رحلة وتابع مهامه التشغيلية.',
          capabilities: ['مهام مسندة', 'تنفيذ موثق'],
          target: LandingFeatureTarget.captain,
          targetLabel: 'شوفها في تطبيق الكابتن',
        ),
        LandingFeature(
          icon: Icons.event_seat_rounded,
          title: 'إدارة الحجوزات',
          body: 'تابع المقاعد والحجوزات وحالة كل حجز من مكان واحد.',
          capabilities: ['خريطة المقاعد', 'حالة الدفع'],
          target: LandingFeatureTarget.bookings,
          targetLabel: 'شوف شاشة الحجوزات',
        ),
      ],
    ),
    LandingFeatureGroup(
      index: '٠٢',
      label: 'المتابعة والإدارة',
      caption: 'الأرقام والصلاحيات اللي بتدير بيها مكتبك',
      features: [
        LandingFeature(
          icon: Icons.payments_rounded,
          title: 'المدفوعات والتحصيل',
          body:
              'تابع الإيرادات والمدفوعات والمصروفات واعرف فلوس مكتبك رايحة فين.',
          capabilities: ['إيرادات ومصروفات', 'حالة كل دفعة'],
          target: LandingFeatureTarget.finance,
          targetLabel: 'شوف الحركة المالية',
        ),
        LandingFeature(
          icon: Icons.bar_chart_rounded,
          title: 'تقارير الأداء',
          body: 'اقرأ أداء الخطوط والإشغال والإيراد عبر الفترة اللي تختارها.',
          capabilities: ['أداء الخطوط', 'نسب الإشغال'],
          target: LandingFeatureTarget.analytics,
          targetLabel: 'شوف التقارير',
        ),
        LandingFeature(
          icon: Icons.group_rounded,
          title: 'إدارة العملاء',
          body: 'احتفظ برؤية واضحة لعملاء مكتبك وحجوزاتهم.',
          capabilities: ['سجل الحجوزات', 'حجز من التطبيق'],
          target: LandingFeatureTarget.client,
          targetLabel: 'شوف تجربة العميل',
        ),
        LandingFeature(
          icon: Icons.manage_accounts_rounded,
          title: 'المستخدمون والصلاحيات',
          body:
              'امنح موظفي المكتب الصلاحيات المناسبة وساعد فريقك على العمل بشكل منظم.',
          capabilities: ['صلاحيات لكل دور', 'فريق منظم'],
          target: LandingFeatureTarget.dashboard,
          targetLabel: 'شوفها في لوحة التحكم',
        ),
      ],
    ),
  ];

  // ── Captain app ─────────────────────────────────────────────────────────
  static const captainBenefits = <LandingPoint>[
    LandingPoint(
      icon: Icons.assignment_ind_rounded,
      title: 'مهام واضحة',
      body: 'كل كابتن يشوف رحلاته المسندة إليه فقط.',
    ),
    LandingPoint(
      icon: Icons.sync_rounded,
      title: 'تحديث فوري',
      body: 'حالة الرحلة تظهر في لوحة التحكم مباشرة.',
    ),
    LandingPoint(
      icon: Icons.call_end_rounded,
      title: 'مكالمات أقل',
      body: 'متابعة أقل بالتليفون والواتساب.',
    ),
    LandingPoint(
      icon: Icons.fact_check_rounded,
      title: 'تنفيذ موثق',
      body: 'بداية ونهاية كل رحلة مسجلة في النظام.',
    ),
  ];

  // ── Bookings ────────────────────────────────────────────────────────────
  static const bookingFilters = <({String label, LandingTone? tone})>[
    (label: 'الكل', tone: null),
    (label: 'مؤكدة', tone: LandingTone.good),
    (label: 'معلقة', tone: LandingTone.warn),
    (label: 'ملغاة', tone: LandingTone.bad),
  ];

  static const bookings = <LandingBookingRow>[
    LandingBookingRow(
      initial: 'م',
      name: 'محمد إبراهيم',
      trip: 'القاهرة → الإسكندرية · 08:30 ص',
      seat: 'A4',
      pay: 'مدفوع',
      payTone: LandingTone.good,
      status: 'مؤكدة',
      statusTone: LandingTone.good,
    ),
    LandingBookingRow(
      initial: 'س',
      name: 'سارة عبد الله',
      trip: 'القاهرة → المنصورة · 10:00 ص',
      seat: 'B2',
      pay: 'مدفوع',
      payTone: LandingTone.good,
      status: 'مؤكدة',
      statusTone: LandingTone.good,
    ),
    LandingBookingRow(
      initial: 'ط',
      name: 'طارق حسن',
      trip: 'القاهرة → طنطا · 12:30 م',
      seat: 'C1',
      pay: 'معلق',
      payTone: LandingTone.warn,
      status: 'قيد التأكيد',
      statusTone: LandingTone.warn,
    ),
    LandingBookingRow(
      initial: 'ن',
      name: 'نورهان سمير',
      trip: 'الجيزة → أسيوط · 06:15 ص',
      seat: 'A1',
      pay: 'مدفوع',
      payTone: LandingTone.good,
      status: 'مكتملة',
      statusTone: LandingTone.neutral,
    ),
    LandingBookingRow(
      initial: 'ك',
      name: 'كريم فؤاد',
      trip: 'القاهرة → بورسعيد · 05:45 ص',
      seat: 'D3',
      pay: 'مسترد',
      payTone: LandingTone.neutral,
      status: 'ملغاة',
      statusTone: LandingTone.bad,
    ),
    LandingBookingRow(
      initial: 'ه',
      name: 'هبة مصطفى',
      trip: 'القاهرة → الإسكندرية · 02:00 م',
      seat: 'B5',
      pay: 'معلق',
      payTone: LandingTone.warn,
      status: 'مؤكدة',
      statusTone: LandingTone.good,
    ),
  ];

  // ── Finance ─────────────────────────────────────────────────────────────
  static const financeKpis = <LandingKpi>[
    LandingKpi(
      label: 'إيرادات اليوم',
      value: '42,850',
      valueColor: LandingPalette.ink,
    ),
    LandingKpi(
      label: 'المدفوعات',
      value: '38,200',
      valueColor: LandingPalette.good,
    ),
    LandingKpi(
      label: 'المبالغ المعلقة',
      value: '4,650',
      valueColor: LandingPalette.warn,
    ),
    LandingKpi(
      label: 'المصروفات',
      value: '12,400',
      valueColor: LandingPalette.ink,
    ),
  ];

  static const revenuePoints = <Offset>[
    Offset(8, 110),
    Offset(66, 96),
    Offset(124, 102),
    Offset(182, 72),
    Offset(240, 80),
    Offset(298, 52),
    Offset(356, 44),
    Offset(412, 28),
  ];
  static const expensePoints = <Offset>[
    Offset(8, 126),
    Offset(66, 120),
    Offset(124, 124),
    Offset(182, 112),
    Offset(240, 116),
    Offset(298, 106),
    Offset(356, 102),
    Offset(412, 98),
  ];
  static const revenueMarkers = <Offset>[
    Offset(182, 72),
    Offset(298, 52),
    Offset(412, 28),
  ];

  static const payStatus = <LandingMeterData>[
    LandingMeterData(
      name: 'مدفوعة',
      value: '89%',
      fraction: 0.89,
      color: LandingPalette.good,
    ),
    LandingMeterData(
      name: 'معلقة',
      value: '8%',
      fraction: 0.08,
      color: LandingPalette.warn,
    ),
    LandingMeterData(
      name: 'مستردة',
      value: '3%',
      fraction: 0.03,
      color: LandingPalette.muted,
    ),
  ];

  // ── Analytics ───────────────────────────────────────────────────────────
  static const topBooked = <LandingMeterData>[
    LandingMeterData(
      name: 'القاهرة → الإسكندرية',
      value: '412 حجز',
      fraction: 1.00,
      color: LandingPalette.brand,
    ),
    LandingMeterData(
      name: 'القاهرة → المنصورة',
      value: '298 حجز',
      fraction: 0.72,
      color: LandingPalette.brand,
    ),
    LandingMeterData(
      name: 'القاهرة → طنطا',
      value: '241 حجز',
      fraction: 0.58,
      color: LandingPalette.brand,
    ),
    LandingMeterData(
      name: 'الجيزة → أسيوط',
      value: '176 حجز',
      fraction: 0.43,
      color: LandingPalette.brand,
    ),
  ];
  static const periodHeights = <double>[50, 66, 78, 88];
  static const periodLabels = <String>['يناير', 'فبراير', 'مارس', 'أبريل'];
  static const analyticsMini = <({String label, String value})>[
    (label: 'الرحلات المكتملة', value: '1,182'),
    (label: 'متوسط المقعد', value: '168 ج.م'),
  ];

  // ── Client experience ───────────────────────────────────────────────────
  static const clientPoints = <String>[
    'استعراض الرحلات المتاحة ومواعيدها',
    'حجز المقعد وتأكيد الرحلة',
    'الدفع ومتابعة حالة الحجز',
    'الوصول لتفاصيل الرحلة بدون مكالمات',
    'استفسارات أقل على فريق المكتب',
  ];

  /// The rider's four steps, each one a real screen of the app.
  ///
  /// The icon is not decoration: it is what marks the four cards as one
  /// sequence at a glance, on a row where every card is otherwise a phone.
  static const clientJourney =
      <({String step, IconData icon, String title, String body, String shot})>[
        (
          step: '١',
          icon: Icons.travel_explore_rounded,
          title: 'يدوّر على رحلته',
          body: 'كل الرحلات المتاحة على خطه، بمواعيدها وأسعارها.',
          shot: LandingShots.clientSearch,
        ),
        (
          step: '٢',
          icon: Icons.event_seat_rounded,
          title: 'يختار مقعده',
          body: 'خريطة مقاعد العربية، والمحجوز منها واضح قبل ما يدفع.',
          shot: LandingShots.clientSeats,
        ),
        (
          step: '٣',
          icon: Icons.my_location_rounded,
          title: 'يتابع رحلته',
          body: 'يشوف العربية على الخريطة ووقت وصولها، بدون مكالمة لمكتبك.',
          shot: LandingShots.clientTrack,
        ),
        (
          step: '٤',
          icon: Icons.account_balance_wallet_rounded,
          title: 'يدفع من محفظته',
          body: 'رصيده وحركة مدفوعاته في مكان واحد.',
          shot: LandingShots.clientWallet,
        ),
      ];
  // ── Before / after ──────────────────────────────────────────────────────
  /// The comparison is read as a table, one row per axis of the operation, so
  /// every complaint on the "before" side has its answer on the same line
  /// rather than in a loose second list the reader has to pair up themselves.
  static const comparisonLead =
      'كل بند في عمود «قبل» له مقابل مباشر في نفس السطر — نفس المهمة، بعد ما '
      'تدخل المنصة.';

  static const comparison = <({String axis, String before, String after})>[
    (
      axis: 'التواصل',
      before: 'متابعة على واتساب ومكالمات كثيرة',
      after: 'منصة واحدة لكل العمليات',
    ),
    (
      axis: 'الجدولة',
      before: 'جداول متفرقة لكل خط',
      after: 'رحلات وخطوط منظمة',
    ),
    (
      axis: 'الحجز',
      before: 'صعوبة معرفة المقاعد المتاحة',
      after: 'حجوزات ومقاعد واضحة',
    ),
    (
      axis: 'الكباتن',
      before: 'متابعة يدوية للكباتن',
      after: 'متابعة الكباتن من التطبيق',
    ),
    (
      axis: 'التشغيل',
      before: 'لا توجد صورة كاملة لليوم',
      after: 'بيانات تشغيلية لحظية',
    ),
    (
      axis: 'المال',
      before: 'أرقام غير واضحة',
      after: 'رؤية مالية وتقارير ومؤشرات',
    ),
    (
      axis: 'الإدارة',
      before: 'اعتماد كبير على صاحب المكتب',
      after: 'صلاحيات وتحكم موزّع على الفريق',
    ),
  ];

  static const comparisonOutcome =
      'النتيجة: وقت أقل في المتابعة اليدوية، وأرقام تقدر تبني عليها قرار.';

  // ── Growth ladder ───────────────────────────────────────────────────────
  static const growth =
      <({String step, String title, Color bar, bool brandBorder})>[
        (
          step: '01',
          title: 'مكتب صغير',
          bar: LandingPalette.well,
          brandBorder: false,
        ),
        (
          step: '02',
          title: 'رحلات أكثر',
          bar: Color(0xFFD6E0F5),
          brandBorder: false,
        ),
        (
          step: '03',
          title: 'كباتن أكثر',
          bar: Color(0xFFB9CDF2),
          brandBorder: false,
        ),
        (
          step: '04',
          title: 'حجوزات أكثر',
          bar: Color(0xFF8FB2EC),
          brandBorder: true,
        ),
        (
          step: '05',
          title: 'فريق أكبر',
          bar: Color(0xFF5C8FE3),
          brandBorder: true,
        ),
        (
          step: '06',
          title: 'عملية نقل أكثر تنظيمًا',
          bar: LandingPalette.brand,
          brandBorder: true,
        ),
      ];

  // ── Why EWT ─────────────────────────────────────────────────────────────
  static const why = <LandingPoint>[
    LandingPoint(
      icon: Icons.tune_rounded,
      title: 'تحكم أكبر',
      body: 'كل عمليات المكتب أمامك في مكان واحد.',
    ),
    LandingPoint(
      icon: Icons.timer_rounded,
      title: 'وقت أقل في المتابعة',
      body: 'خلّي النظام وفريقك يتولوا المهام اليومية.',
    ),
    LandingPoint(
      icon: Icons.visibility_rounded,
      title: 'رؤية أوضح',
      body: 'اعرف وضع الرحلات والحجوزات والأداء.',
    ),
    LandingPoint(
      icon: Icons.workspace_premium_rounded,
      title: 'تشغيل أكثر احترافية',
      body: 'نظام موحد بدل الأدوات المتفرقة.',
    ),
    LandingPoint(
      icon: Icons.sentiment_satisfied_rounded,
      title: 'تجربة أفضل للعميل',
      body: 'حجز ومتابعة بشكل أسهل.',
    ),
    LandingPoint(
      icon: Icons.trending_up_rounded,
      title: 'جاهز للنمو',
      body: 'نظام يساعد مكتبك على التوسع بدون زيادة الفوضى التشغيلية.',
    ),
  ];

  // ── Steps ───────────────────────────────────────────────────────────────
  static const steps =
      <({String num, IconData icon, String title, String body})>[
        (
          num: '01',
          icon: Icons.store_rounded,
          title: 'سجّل مكتبك',
          body: 'أنشئ حساب مكتبك وابدأ إعداد النظام.',
        ),
        (
          num: '02',
          icon: Icons.alt_route_rounded,
          title: 'أضف خطوطك ورحلاتك',
          body: 'نظّم عمليات النقل والمواعيد.',
        ),
        (
          num: '03',
          icon: Icons.group_add_rounded,
          title: 'أضف فريقك وكباتنك',
          body: 'وزّع المهام والصلاحيات.',
        ),
        (
          num: '04',
          icon: Icons.play_circle_outline_rounded,
          title: 'ابدأ التشغيل',
          body: 'تابع الرحلات والحجوزات والمدفوعات من لوحة التحكم.',
        ),
      ];

  // ── Trust rail ──────────────────────────────────────────────────────────
  static const trustItems = <({IconData icon, String title})>[
    (icon: Icons.admin_panel_settings_rounded, title: 'صلاحيات المستخدمين'),
    (icon: Icons.settings_suggest_rounded, title: 'إدارة العمليات'),
    (icon: Icons.track_changes_rounded, title: 'تتبع حالة الرحلات'),
    (icon: Icons.event_seat_rounded, title: 'إدارة الحجوزات'),
    (icon: Icons.payments_rounded, title: 'متابعة المدفوعات'),
    (icon: Icons.storage_rounded, title: 'بيانات مركزية'),
    (icon: Icons.bar_chart_rounded, title: 'تقارير تشغيلية'),
  ];

  // ── FAQ ─────────────────────────────────────────────────────────────────
  /// Each entry carries the rail's category. The categories run in page
  /// order and every question is contiguous with its neighbours, so the
  /// unfiltered list already reads as four groups before the reader
  /// narrows it.
  static const faq = <({String category, String question, String answer})>[
    (
      category: 'عن المنصة',
      question: 'ما هي EWT؟',
      answer:
          'نظام لإدارة مكاتب النقل: الخطوط والرحلات والكباتن والحجوزات والمدفوعات والتقارير في لوحة تحكم واحدة.',
    ),
    (
      category: 'عن المنصة',
      question: 'هل EWT مناسبة لمكاتب النقل الصغيرة؟',
      answer:
          'نعم. تبدأ بعدد محدود من الخطوط والرحلات، وتتوسع مع نمو مكتبك بدون تغيير النظام.',
    ),
    (
      category: 'التشغيل والفريق',
      question: 'هل يمكنني إدارة أكثر من خط ورحلة؟',
      answer:
          'نعم، يمكنك إنشاء عدد غير محدود من الخطوط والرحلات اليومية أو المتكررة ومتابعة إشغال كل خط.',
    ),
    (
      category: 'التشغيل والفريق',
      question: 'هل يمكنني إضافة أكثر من كابتن؟',
      answer:
          'نعم، تضيف كباتن مكتبك وتسند لكل رحلة كابتنها وتتابع تنفيذه من لوحة التحكم.',
    ),
    (
      category: 'التشغيل والفريق',
      question: 'هل يمكن لموظفي المكتب استخدام النظام؟',
      answer:
          'نعم، تضيف مستخدمين لفريقك وتمنح كل واحد الصلاحيات المناسبة لدوره.',
    ),
    (
      category: 'الحجز والتطبيقات',
      question: 'هل يمكنني متابعة الحجوزات والمدفوعات؟',
      answer:
          'نعم، تتابع كل حجز ومقعده وحالة الدفع، مع متابعة المبالغ المحصلة والمعلقة.',
    ),
    (
      category: 'الحجز والتطبيقات',
      question: 'هل يوجد تطبيق للكابتن؟',
      answer:
          'نعم، تطبيق الكابتن يعرض الرحلات المسندة إليه وتفاصيلها وحالتها، وكل تحديث يظهر لك في لوحة التحكم.',
    ),
    (
      category: 'الحجز والتطبيقات',
      question: 'هل يستطيع العملاء الحجز من خلال النظام؟',
      answer:
          'نعم، يمكن للعميل استعراض الرحلات المتاحة وحجز مقعده ومتابعة حالة حجزه.',
    ),
    (
      category: 'البدء',
      question: 'كيف أبدأ استخدام EWT؟',
      answer:
          'سجّل مكتبك، أضف خطوطك ورحلاتك وفريقك، وابدأ التشغيل والمتابعة من لوحة التحكم.',
    ),
  ];

  // ── Closing band ────────────────────────────────────────────────────────
  /// What a reader actually gets after pressing the closing CTA. Every line
  /// is something the page has already shown or the onboarding dialog
  /// already promises — the band sets expectations, it does not invent them.
  static const ctaAssurances = <String>[
    'إعداد حساب مكتبك بمساعدة فريقنا',
    'تجهيز خطوطك ورحلاتك خطوة بخطوة',
    'متابعة كل شيء من لوحة تحكم واحدة',
  ];

  // ── Contact ─────────────────────────────────────────────────────────────
  static const contactEmail = 'mahmoudyousse220@gmail.com';
  static const contactPhone = '01204154971';

  // ── Footer ──────────────────────────────────────────────────────────────
  static const footerColumns = <({String title, List<String> links})>[
    (title: 'المنصة', links: ['المميزات', 'لوحة التحكم', 'كيف تعمل EWT؟']),
    (
      title: 'للمكاتب',
      links: ['إدارة الرحلات', 'إدارة الكباتن', 'إدارة الحجوزات', 'التقارير'],
    ),
    (title: 'الدعم', links: ['الأسئلة الشائعة', 'تواصل معنا']),
    (title: 'الحساب', links: ['تسجيل الدخول', 'إنشاء حساب']),
  ];
}

/// The band «المميزات» hands the reader off to for a given feature. Every
/// card has one: a feature the page never demonstrates has no business being
/// advertised in the index.
enum LandingFeatureTarget {
  dashboard,
  captain,
  bookings,
  finance,
  analytics,
  client,
}

/// One card in «المميزات»: what the module is, two concrete things it does,
/// and where on the page it is shown working.
class LandingFeature {
  const LandingFeature({
    required this.icon,
    required this.title,
    required this.body,
    required this.capabilities,
    required this.target,
    required this.targetLabel,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<String> capabilities;
  final LandingFeatureTarget target;
  final String targetLabel;
}

/// A named run of features — the heading rule that splits the eight cards
/// into two readable halves instead of one eight-card field.
class LandingFeatureGroup {
  const LandingFeatureGroup({
    required this.index,
    required this.label,
    required this.caption,
    required this.features,
  });

  final String index;
  final String label;
  final String caption;
  final List<LandingFeature> features;
}

/// An icon + title + body triple — the page's most repeated shape, used by the
/// problem grid, the "why" grid and the trust rail.
class LandingPoint {
  const LandingPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

/// A metric tile: a number, its unit, and a coloured delta beneath it.
class LandingKpi {
  const LandingKpi({
    this.icon,
    required this.label,
    required this.value,
    this.unit = '',
    this.delta = '',
    this.deltaColor = LandingPalette.muted,
    this.valueColor = LandingPalette.ink,
  });

  final IconData? icon;
  final String label;
  final String value;
  final String unit;
  final String delta;
  final Color deltaColor;
  final Color valueColor;
}

class LandingBookingRow {
  const LandingBookingRow({
    required this.initial,
    required this.name,
    required this.trip,
    required this.seat,
    required this.pay,
    required this.payTone,
    required this.status,
    required this.statusTone,
  });

  final String initial;
  final String name;
  final String trip;
  final String seat;
  final String pay;
  final LandingTone payTone;
  final String status;
  final LandingTone statusTone;
}

/// One row of the hero board's «الرحلات القادمة» panel.
///
/// The endpoints are held apart rather than pre-joined into `'A → B'`: the
/// panel renders them through [RouteDirectionText], which is the only form
/// that still means *origin → destination* after the bidi algorithm has had
/// its say.
class LandingBoardTrip {
  const LandingBoardTrip({
    required this.origin,
    required this.destination,
    required this.meta,
    required this.seats,
    required this.status,
    required this.tone,
  });

  final String origin;
  final String destination;

  /// Departure time and captain, on one quiet line under the route.
  final String meta;

  /// Booked over capacity — a Latin run, so the panel isolates it.
  final String seats;
  final String status;
  final LandingTone tone;
}

class LandingMeterData {
  const LandingMeterData({
    required this.name,
    required this.value,
    required this.fraction,
    this.color = LandingPalette.brand,
  });

  final String name;
  final String value;
  final double fraction;
  final Color color;
}

/// One tab of the dashboard product shot — its own KPI set and trend series.
/// One tab of the console section — a real screen of the product, named and
/// described.
///
/// It used to carry invented KPIs and a chart, which the section drew itself.
/// Now the section shows the console screenshot instead, and invented figures
/// beside a real screen would simply contradict the numbers in it.
class LandingDashboardTab {
  const LandingDashboardTab({
    required this.label,
    required this.caption,
    required this.shot,
  });

  final String label;

  /// One line on what this screen answers, read before the screenshot.
  final String caption;

  /// A `LandingShots` path — the capture this tab shows.
  final String shot;
}
