import 'package:flutter/material.dart';

import 'theme/landing_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Value types
//
// One small immutable record per repeated shape in the design's `renderVals()`
// block. The sections stay layout-only: they read these lists and draw them,
// so a copy or figure change is a one-line edit here rather than a hunt
// through nineteen widget files.
// ─────────────────────────────────────────────────────────────────────────────

/// An icon with a title and an optional supporting line — the design's
/// `problems`, `operations`, `why`, `captainBenefits`, `heroTrust`,
/// `modulesA/B` and `trustItems` all wear this shape.
@immutable
class LandingPoint {
  const LandingPoint({required this.icon, required this.title, this.body = ''});

  final IconData icon;
  final String title;
  final String body;
}

/// A metric tile with a leading icon — the hero console's four KPIs.
@immutable
class LandingKpi {
  const LandingKpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.delta,
    required this.deltaColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String delta;
  final Color deltaColor;
}

/// A metric tile without an icon — the dashboard tabs' six-up grid.
@immutable
class LandingStat {
  const LandingStat({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaColor,
  });

  final String label;
  final String value;
  final String delta;
  final Color deltaColor;
}

/// A bare label/value pair — the modules hub's mini grid and the analytics
/// card's footer figures.
@immutable
class LandingMini {
  const LandingMini({required this.label, required this.value});

  final String label;
  final String value;
}

/// A finance KPI: one number, its own ink, and the shared `ج.م` suffix.
@immutable
class LandingMoney {
  const LandingMoney({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

/// A row in the hero console's "upcoming trips" panel.
@immutable
class LandingTrip {
  const LandingTrip({
    required this.route,
    required this.time,
    required this.captain,
    required this.seats,
    required this.status,
    required this.tone,
  });

  final String route;
  final String time;
  final String captain;
  final String seats;
  final String status;
  final LandingTone tone;
}

/// A row in the dashboard section's trips table.
@immutable
class LandingTripRow {
  const LandingTripRow({
    required this.id,
    required this.line,
    required this.captain,
    required this.time,
    required this.seats,
    required this.status,
    required this.tone,
  });

  final String id;
  final String line;
  final String captain;
  final String time;
  final String seats;
  final String status;
  final LandingTone tone;
}

/// A row in the bookings table.
@immutable
class LandingBooking {
  const LandingBooking({
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

/// One chip in the bookings toolbar. The first is a brand fill rather than a
/// tint, which is why [solid] exists instead of a sixth [LandingTone].
@immutable
class LandingFilterChip {
  const LandingFilterChip({required this.label, this.tone, this.solid = false});

  final String label;
  final LandingTone? tone;
  final bool solid;
}

/// A named meter: label, trailing figure, fill fraction and bar colour.
@immutable
class LandingMeterDatum {
  const LandingMeterDatum({
    required this.name,
    required this.trailing,
    required this.fraction,
    this.color = LandingPalette.brand,
  });

  final String name;
  final String trailing;
  final double fraction;
  final Color color;
}

/// A numbered "how it works" card.
@immutable
class LandingStepCard {
  const LandingStepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String number;
  final IconData icon;
  final String title;
  final String body;
}

/// A rung on the growth ladder — the bar deepens toward brand as it climbs.
@immutable
class LandingGrowthStep {
  const LandingGrowthStep({
    required this.number,
    required this.title,
    required this.borderColor,
    required this.barColor,
  });

  final String number;
  final String title;
  final Color borderColor;
  final Color barColor;
}

@immutable
class LandingFaqItem {
  const LandingFaqItem(this.question, this.answer);

  final String question;
  final String answer;
}

@immutable
class LandingFooterColumn {
  const LandingFooterColumn({required this.title, required this.links});

  final String title;
  final List<String> links;
}

/// One tab of the dashboard console: six KPIs and a trend chart. The chart is
/// given as points in the design's own 420×160 SVG space, so the port is the
/// path data rather than a re-derivation of it.
@immutable
class LandingDashboardTab {
  const LandingDashboardTab({
    required this.label,
    required this.kpis,
    required this.chartTitle,
    required this.chartNote,
    required this.points,
  });

  final String label;
  final List<LandingStat> kpis;
  final String chartTitle;
  final String chartNote;
  final List<Offset> points;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Every string and figure the landing page renders, lifted verbatim from the
/// `EWT Landing v2` design file.
///
/// None of it is live data: the page is a product shot, and the office it
/// reports on is a demonstration office.
class LandingContent {
  const LandingContent._();

  // ── Brand ───────────────────────────────────────────────────────────────
  static const brandName = 'EWT';
  static const brandFullName = 'Easy Way Transportation';

  // ── Header ──────────────────────────────────────────────────────────────
  static const navHome = 'الرئيسية';
  static const navFeatures = 'المميزات';
  static const navHowItWorks = 'كيف تعمل EWT؟';
  static const navDashboard = 'لوحة التحكم';
  static const navFaq = 'الأسئلة الشائعة';
  static const navContact = 'تواصل معنا';
  static const signIn = 'تسجيل الدخول';
  static const getStarted = 'ابدأ مع EWT';

  // ── Hero ────────────────────────────────────────────────────────────────
  static const heroBadge = 'نظام إدارة مكاتب النقل في مصر';
  static const heroHeadline = 'إدارة مكتب النقل بالكامل، ';
  static const heroHeadlineAccent = 'من مكان واحد.';
  static const heroBody =
      'EWT تساعدك على إدارة الرحلات والخطوط والكباتن والحجوزات والمدفوعات، '
      'ومتابعة أداء مكتبك من خلال نظام واحد مصمم لعمليات النقل.';
  static const heroPrimaryCta = 'ابدأ إدارة مكتبك مع EWT';
  static const heroSecondaryCta = 'شاهد كيف تعمل المنصة';

  // The label under the captain phone standing to the right of the console.
  // The screen inside it is a capture, not copy — see `LandingShots`.
  static const heroCaptainCaption = 'تطبيق الكابتن';

  // The console in the middle of the rig.
  static const heroConsoleUrl = 'console.ewt.eg';
  static const heroConsoleTitle = 'لوحة تحكم EWT · مكتب الميجا للنقل';
  static const heroConsoleStamp = 'تحديث مباشر · 12 مارس 2026';
  static const heroConsoleOverview = 'نظرة عامة';
  static const heroConsoleRanges = ['اليوم', 'الأسبوع', 'الشهر'];
  static const heroConsoleCaption = 'لوحة تحكم المكتب';

  static const heroKpis = <LandingKpi>[
    LandingKpi(
      icon: Icons.route_rounded,
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
      unit: '',
      delta: '+4% عن الأسبوع الماضي',
      deltaColor: LandingPalette.good,
    ),
    LandingKpi(
      icon: Icons.payments_rounded,
      label: 'إيرادات اليوم',
      value: '42,850',
      unit: 'ج.م',
      delta: '38,200 محصلة',
      deltaColor: LandingPalette.muted,
    ),
  ];

  static const heroChartTitle = 'الحجوزات خلال الأسبوع';
  static const heroChartNote = 'إجمالي 1,184 حجز';

  /// Bar heights in the design's own 340×130 units, measured up from the
  /// baseline at y=114.
  static const heroChartHeights = <double>[48, 64, 56, 80, 72, 94, 86];
  static const heroChartLabels = <String>[
    'سبت',
    'أحد',
    'اثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
  ];

  static const heroTripsTitle = 'الرحلات القادمة';
  static const heroTripsAction = 'عرض الكل';
  static const heroTrips = <LandingTrip>[
    LandingTrip(
      route: 'القاهرة → الإسكندرية',
      time: '08:30 ص',
      captain: 'كابتن محمود',
      seats: '12 / 14',
      status: 'مؤكدة',
      tone: LandingTone.good,
    ),
    LandingTrip(
      route: 'القاهرة → المنصورة',
      time: '10:00 ص',
      captain: 'كابتن سيد',
      seats: '11 / 14',
      status: 'قادمة',
      tone: LandingTone.brand,
    ),
    LandingTrip(
      route: 'القاهرة → طنطا',
      time: '12:30 م',
      captain: 'كابتن رمضان',
      seats: '14 / 14',
      status: 'مكتملة الحجز',
      tone: LandingTone.warn,
    ),
  ];

  // Likewise for the rider phone on the left of it.
  static const heroRiderCaption = 'تطبيق الراكب';

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

  // ── The challenge ───────────────────────────────────────────────────────
  static const problemEyebrow = 'التحدي';
  static const problemHeadline = 'مكتبك كبر... وطريقة إدارته لازم تكبر معاه';
  static const problemLead =
      'مع زيادة الرحلات والكباتن والحجوزات، المتابعة اليدوية بتاخد وقت '
      'وبتخلي الوصول للصورة الكاملة أصعب.';
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
  static const problemBannerText = 'EWT تجمع كل ده في نظام واحد.';
  static const problemBannerCta = 'شوف لوحة التحكم';

  // ── Modules ─────────────────────────────────────────────────────────────
  static const modulesHeadline = 'كل ما تحتاجه لإدارة مكتبك، في منصة واحدة';
  static const modulesLead =
      'بدل ما تدير أجزاء منفصلة، EWT تجمع العملية كلها في مكان واحد.';
  static const modulesStart = <LandingPoint>[
    LandingPoint(icon: Icons.route_rounded, title: 'الرحلات'),
    LandingPoint(icon: Icons.alt_route_rounded, title: 'الخطوط'),
    LandingPoint(icon: Icons.badge_rounded, title: 'الكباتن'),
    LandingPoint(icon: Icons.event_seat_rounded, title: 'الحجوزات'),
  ];
  static const modulesEnd = <LandingPoint>[
    LandingPoint(icon: Icons.payments_rounded, title: 'المدفوعات'),
    LandingPoint(icon: Icons.bar_chart_rounded, title: 'التقارير'),
    LandingPoint(icon: Icons.manage_accounts_rounded, title: 'المستخدمين'),
    LandingPoint(icon: Icons.group_rounded, title: 'العملاء'),
  ];
  static const modulesHubTitle = 'لوحة تحكم EWT';
  static const modulesHubCaption = 'المركز الذي تُدار منه العملية بالكامل';
  static const modulesHubMini = <LandingMini>[
    LandingMini(label: 'رحلات اليوم', value: '24'),
    LandingMini(label: 'الحجوزات', value: '186'),
    LandingMini(label: 'الإشغال', value: '87%'),
    LandingMini(label: 'الإيرادات', value: '42.8 أ'),
  ];

  // ── Dashboard ───────────────────────────────────────────────────────────
  static const dashboardEyebrow = 'لوحة التحكم';
  static const dashboardHeadline = 'شوف مكتبك بالكامل من لوحة تحكم واحدة';
  static const dashboardLead =
      'كل رحلة، كل حجز، وكل رقم مهم — في شاشة واحدة تتابعها في أي وقت.';
  static const dashboardPanelTitle = 'تشغيل اليوم';

  static const dashboardTabs = <LandingDashboardTab>[
    LandingDashboardTab(
      label: 'نظرة عامة',
      kpis: [
        LandingStat(
          label: 'الرحلات اليوم',
          value: '24',
          delta: '+3 عن أمس',
          deltaColor: LandingPalette.good,
        ),
        LandingStat(
          label: 'الحجوزات',
          value: '186',
          delta: '+12%',
          deltaColor: LandingPalette.good,
        ),
        LandingStat(
          label: 'نسبة الإشغال',
          value: '87%',
          delta: '+4%',
          deltaColor: LandingPalette.good,
        ),
        LandingStat(
          label: 'الإيرادات',
          value: '42,850',
          delta: 'ج.م اليوم',
          deltaColor: LandingPalette.muted,
        ),
        LandingStat(
          label: 'المصروفات',
          value: '12,400',
          delta: 'ج.م اليوم',
          deltaColor: LandingPalette.warn,
        ),
        LandingStat(
          label: 'صافي الحركة',
          value: '30,450',
          delta: 'ج.م',
          deltaColor: LandingPalette.good,
        ),
      ],
      chartTitle: 'الإيرادات خلال 7 أيام',
      chartNote: 'ج.م',
      points: [
        Offset(8, 104),
        Offset(74, 92),
        Offset(140, 96),
        Offset(206, 70),
        Offset(272, 76),
        Offset(338, 48),
        Offset(412, 34),
      ],
    ),
    LandingDashboardTab(
      label: 'الرحلات',
      kpis: [
        LandingStat(
          label: 'رحلات مؤكدة',
          value: '18',
          delta: 'من 24',
          deltaColor: LandingPalette.good,
        ),
        LandingStat(
          label: 'قادمة',
          value: '4',
          delta: 'خلال 3 ساعات',
          deltaColor: LandingPalette.brandInk,
        ),
        LandingStat(
          label: 'مكتملة',
          value: '11',
          delta: 'اليوم',
          deltaColor: LandingPalette.muted,
        ),
        LandingStat(
          label: 'ملغاة',
          value: '1',
          delta: '−2 عن أمس',
          deltaColor: LandingPalette.good,
        ),
        LandingStat(
          label: 'الخطوط النشطة',
          value: '12',
          delta: 'خط',
          deltaColor: LandingPalette.muted,
        ),
        LandingStat(
          label: 'متوسط الإشغال',
          value: '87%',
          delta: 'لكل رحلة',
          deltaColor: LandingPalette.good,
        ),
      ],
      chartTitle: 'الرحلات المنفذة خلال 7 أيام',
      chartNote: 'رحلة',
      points: [
        Offset(8, 96),
        Offset(74, 84),
        Offset(140, 90),
        Offset(206, 66),
        Offset(272, 58),
        Offset(338, 62),
        Offset(412, 40),
      ],
    ),
    LandingDashboardTab(
      label: 'الحجوزات',
      kpis: [
        LandingStat(
          label: 'حجوزات اليوم',
          value: '186',
          delta: '+12%',
          deltaColor: LandingPalette.good,
        ),
        LandingStat(
          label: 'مؤكدة',
          value: '151',
          delta: '81%',
          deltaColor: LandingPalette.good,
        ),
        LandingStat(
          label: 'معلقة الدفع',
          value: '27',
          delta: 'تحتاج متابعة',
          deltaColor: LandingPalette.warn,
        ),
        LandingStat(
          label: 'ملغاة',
          value: '8',
          delta: '4%',
          deltaColor: LandingPalette.muted,
        ),
        LandingStat(
          label: 'مقاعد محجوزة',
          value: '294',
          delta: 'من 338',
          deltaColor: LandingPalette.muted,
        ),
        LandingStat(
          label: 'متوسط المقعد',
          value: '168',
          delta: 'ج.م',
          deltaColor: LandingPalette.muted,
        ),
      ],
      chartTitle: 'الحجوزات خلال 7 أيام',
      chartNote: 'حجز',
      points: [
        Offset(8, 110),
        Offset(74, 86),
        Offset(140, 94),
        Offset(206, 74),
        Offset(272, 54),
        Offset(338, 60),
        Offset(412, 30),
      ],
    ),
    LandingDashboardTab(
      label: 'المالية',
      kpis: [
        LandingStat(
          label: 'إيرادات اليوم',
          value: '42,850',
          delta: 'ج.م',
          deltaColor: LandingPalette.good,
        ),
        LandingStat(
          label: 'المدفوعات',
          value: '38,200',
          delta: 'محصلة',
          deltaColor: LandingPalette.good,
        ),
        LandingStat(
          label: 'مبالغ معلقة',
          value: '4,650',
          delta: 'قيد التحصيل',
          deltaColor: LandingPalette.warn,
        ),
        LandingStat(
          label: 'المصروفات',
          value: '12,400',
          delta: 'ج.م',
          deltaColor: LandingPalette.warn,
        ),
        LandingStat(
          label: 'صافي الحركة',
          value: '30,450',
          delta: 'ج.م',
          deltaColor: LandingPalette.good,
        ),
        LandingStat(
          label: 'أعلى خط إيرادًا',
          value: '14,200',
          delta: 'القاهرة → الإسكندرية',
          deltaColor: LandingPalette.muted,
        ),
      ],
      chartTitle: 'الإيرادات المحصلة خلال 7 أيام',
      chartNote: 'ج.م',
      points: [
        Offset(8, 114),
        Offset(74, 100),
        Offset(140, 88),
        Offset(206, 80),
        Offset(272, 64),
        Offset(338, 50),
        Offset(412, 32),
      ],
    ),
  ];

  static const dashboardTopLinesTitle = 'أعلى الخطوط إشغالًا';
  static const dashboardTopLines = <LandingMeterDatum>[
    LandingMeterDatum(
      name: 'القاهرة → الإسكندرية',
      trailing: '92%',
      fraction: 0.92,
      color: LandingPalette.brand,
    ),
    LandingMeterDatum(
      name: 'القاهرة → المنصورة',
      trailing: '86%',
      fraction: 0.86,
      color: LandingPalette.brand,
    ),
    LandingMeterDatum(
      name: 'القاهرة → طنطا',
      trailing: '79%',
      fraction: 0.79,
      color: LandingPalette.navy,
    ),
    LandingMeterDatum(
      name: 'الجيزة → أسيوط',
      trailing: '68%',
      fraction: 0.68,
      color: LandingPalette.navy,
    ),
  ];

  static const tripTableHeaders = <String>[
    'الرحلة',
    'الخط',
    'الكابتن',
    'الانطلاق',
    'المقاعد',
    'الحالة',
  ];
  static const tripRows = <LandingTripRow>[
    LandingTripRow(
      id: 'TR-1042',
      line: 'القاهرة → الإسكندرية',
      captain: 'محمود عبده',
      time: '08:30 ص',
      seats: '12 / 14',
      status: 'مؤكدة',
      tone: LandingTone.good,
    ),
    LandingTripRow(
      id: 'TR-1043',
      line: 'القاهرة → المنصورة',
      captain: 'سيد فتحي',
      time: '10:00 ص',
      seats: '11 / 14',
      status: 'قادمة',
      tone: LandingTone.brand,
    ),
    LandingTripRow(
      id: 'TR-1044',
      line: 'القاهرة → طنطا',
      captain: 'رمضان علي',
      time: '12:30 م',
      seats: '14 / 14',
      status: 'قادمة',
      tone: LandingTone.brand,
    ),
    LandingTripRow(
      id: 'TR-1039',
      line: 'الجيزة → أسيوط',
      captain: 'أحمد صابر',
      time: '06:15 ص',
      seats: '13 / 14',
      status: 'مكتملة',
      tone: LandingTone.neutral,
    ),
    LandingTripRow(
      id: 'TR-1038',
      line: 'القاهرة → بورسعيد',
      captain: 'كريم منصور',
      time: '05:45 ص',
      seats: '9 / 14',
      status: 'مكتملة',
      tone: LandingTone.neutral,
    ),
    LandingTripRow(
      id: 'TR-1036',
      line: 'القاهرة → الإسكندرية',
      captain: '—',
      time: '04:30 ص',
      seats: '0 / 14',
      status: 'ملغاة',
      tone: LandingTone.bad,
    ),
  ];

  // ── Operations ──────────────────────────────────────────────────────────
  static const operationsEyebrow = 'إدارة العمليات';
  static const operationsHeadline = 'شغّل مكتبك بشكل أكثر تنظيمًا';
  static const operations = <LandingPoint>[
    LandingPoint(
      icon: Icons.alt_route_rounded,
      title: 'إدارة الخطوط',
      body: 'أنشئ خطوط النقل ونقاط الانطلاق والوصول ونظم رحلاتك بسهولة.',
    ),
    LandingPoint(
      icon: Icons.route_rounded,
      title: 'إدارة الرحلات',
      body: 'أنشئ الرحلات وحدد مواعيدها وكباتنها وتابع حالتها.',
    ),
    LandingPoint(
      icon: Icons.badge_rounded,
      title: 'إدارة الكباتن',
      body: 'اعرف الكابتن المسؤول عن كل رحلة وتابع مهامه التشغيلية.',
    ),
    LandingPoint(
      icon: Icons.event_seat_rounded,
      title: 'إدارة الحجوزات',
      body: 'تابع المقاعد والحجوزات وحالة كل حجز من مكان واحد.',
    ),
    LandingPoint(
      icon: Icons.manage_accounts_rounded,
      title: 'إدارة المستخدمين',
      body:
          'امنح موظفي المكتب الصلاحيات المناسبة وساعد فريقك على العمل بشكل '
          'منظم.',
    ),
    LandingPoint(
      icon: Icons.group_rounded,
      title: 'إدارة العملاء',
      body: 'احتفظ برؤية واضحة لحجوزات وعملاء مكتبك.',
    ),
  ];

  // ── Captain app ─────────────────────────────────────────────────────────
  static const captainEyebrow = 'تطبيق الكابتن';
  static const captainHeadline = 'الكابتن يعرف مهمته، وأنت تعرف حالة الرحلة';
  static const captainLead =
      'كل كابتن يشوف الرحلات المسندة إليه وتفاصيلها، بينما تظل أنت على اطلاع '
      'كامل بحالة التشغيل من لوحة التحكم.';
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
  static const captainClosing =
      'خلّي الكابتن ينفذ دوره... وأنت تفضل مسيطر على العملية.';

  // ── Bookings ────────────────────────────────────────────────────────────
  static const bookingsEyebrow = 'الحجوزات';
  static const bookingsHeadline = 'الحجوزات تحت سيطرتك';
  static const bookingsLead =
      'تعرف مين حجز، على أي رحلة، وأي مقعد، وحالة الدفع.';
  static const bookingsPanelTitle = 'حجوزات اليوم · 186 حجز';
  static const bookingFilters = <LandingFilterChip>[
    LandingFilterChip(label: 'الكل', solid: true),
    LandingFilterChip(label: 'مؤكدة', tone: LandingTone.good),
    LandingFilterChip(label: 'معلقة', tone: LandingTone.warn),
    LandingFilterChip(label: 'ملغاة', tone: LandingTone.bad),
  ];
  static const bookingHeaders = <String>[
    'العميل',
    'الرحلة',
    'المقعد',
    'الدفع',
    'الحالة',
  ];
  static const bookings = <LandingBooking>[
    LandingBooking(
      initial: 'م',
      name: 'محمد إبراهيم',
      trip: 'القاهرة → الإسكندرية · 08:30 ص',
      seat: 'A4',
      pay: 'مدفوع',
      payTone: LandingTone.good,
      status: 'مؤكدة',
      statusTone: LandingTone.good,
    ),
    LandingBooking(
      initial: 'س',
      name: 'سارة عبد الله',
      trip: 'القاهرة → المنصورة · 10:00 ص',
      seat: 'B2',
      pay: 'مدفوع',
      payTone: LandingTone.good,
      status: 'مؤكدة',
      statusTone: LandingTone.good,
    ),
    LandingBooking(
      initial: 'ط',
      name: 'طارق حسن',
      trip: 'القاهرة → طنطا · 12:30 م',
      seat: 'C1',
      pay: 'معلق',
      payTone: LandingTone.warn,
      status: 'قيد التأكيد',
      statusTone: LandingTone.warn,
    ),
    LandingBooking(
      initial: 'ن',
      name: 'نورهان سمير',
      trip: 'الجيزة → أسيوط · 06:15 ص',
      seat: 'A1',
      pay: 'مدفوع',
      payTone: LandingTone.good,
      status: 'مكتملة',
      statusTone: LandingTone.neutral,
    ),
    LandingBooking(
      initial: 'ك',
      name: 'كريم فؤاد',
      trip: 'القاهرة → بورسعيد · 05:45 ص',
      seat: 'D3',
      pay: 'مسترد',
      payTone: LandingTone.neutral,
      status: 'ملغاة',
      statusTone: LandingTone.bad,
    ),
    LandingBooking(
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
  static const financeEyebrow = 'الحركة المالية';
  static const financeHeadline = 'اعرف فلوس مكتبك رايحة فين';
  static const financeLead =
      'تابع حركة الإيرادات والمدفوعات والمصروفات من مكان واحد، وخلي قراراتك '
      'مبنية على أرقام واضحة.';
  static const currencySuffix = 'ج.م';
  static const financeKpis = <LandingMoney>[
    LandingMoney(
      label: 'إيرادات اليوم',
      value: '42,850',
      color: LandingPalette.ink,
    ),
    LandingMoney(
      label: 'المدفوعات',
      value: '38,200',
      color: LandingPalette.good,
    ),
    LandingMoney(
      label: 'المبالغ المعلقة',
      value: '4,650',
      color: LandingPalette.warn,
    ),
    LandingMoney(
      label: 'المصروفات',
      value: '12,400',
      color: LandingPalette.ink,
    ),
  ];
  static const financeChartTitle = 'الإيرادات مقابل المصروفات';
  static const financeChartNote = 'آخر 8 أسابيع';
  static const financeRevenueLabel = 'الإيرادات';
  static const financeExpenseLabel = 'المصروفات';

  /// Points in the design's 420×170 space.
  static const financeRevenue = <Offset>[
    Offset(8, 110),
    Offset(66, 96),
    Offset(124, 102),
    Offset(182, 72),
    Offset(240, 80),
    Offset(298, 52),
    Offset(356, 44),
    Offset(412, 28),
  ];
  static const financeExpenses = <Offset>[
    Offset(8, 126),
    Offset(66, 120),
    Offset(124, 124),
    Offset(182, 112),
    Offset(240, 116),
    Offset(298, 106),
    Offset(356, 102),
    Offset(412, 98),
  ];
  static const financeMarkers = <Offset>[
    Offset(182, 72),
    Offset(298, 52),
    Offset(412, 28),
  ];
  static const financePayStatus = <LandingMeterDatum>[
    LandingMeterDatum(
      name: 'مدفوعة',
      trailing: '89%',
      fraction: 0.89,
      color: LandingPalette.good,
    ),
    LandingMeterDatum(
      name: 'معلقة',
      trailing: '8%',
      fraction: 0.08,
      color: LandingPalette.warn,
    ),
    LandingMeterDatum(
      name: 'مستردة',
      trailing: '3%',
      fraction: 0.03,
      color: LandingPalette.muted,
    ),
  ];

  // ── Analytics ───────────────────────────────────────────────────────────
  static const analyticsEyebrow = 'التقارير والمؤشرات';
  static const analyticsHeadline = 'مش بس تدير مكتبك... افهم أداءه';
  static const analyticsLead = 'لما تكون الأرقام واضحة، قراراتك بتكون أفضل.';
  static const analyticsTopBookedTitle = 'أكثر الخطوط حجزًا';
  static const analyticsTopBooked = <LandingMeterDatum>[
    LandingMeterDatum(
      name: 'القاهرة → الإسكندرية',
      trailing: '412 حجز',
      fraction: 1,
    ),
    LandingMeterDatum(
      name: 'القاهرة → المنصورة',
      trailing: '298 حجز',
      fraction: 0.72,
    ),
    LandingMeterDatum(
      name: 'القاهرة → طنطا',
      trailing: '241 حجز',
      fraction: 0.58,
    ),
    LandingMeterDatum(
      name: 'الجيزة → أسيوط',
      trailing: '176 حجز',
      fraction: 0.43,
    ),
  ];
  static const analyticsOccupancyTitle = 'نسبة إشغال الرحلات';

  /// `stroke-dasharray: 262 302` on a r=48 ring — 262 / 2πr.
  static const analyticsOccupancyFraction = 0.87;
  static const analyticsOccupancyValue = '87%';
  static const analyticsOccupancyCaption = 'متوسط الشهر';
  static const analyticsOccupancyFooter = '12 خطًا نشطًا · 1,248 رحلة';
  static const analyticsPeriodTitle = 'الإيرادات حسب الفترة';
  static const analyticsPeriodHeights = <double>[50, 66, 78, 88];
  static const analyticsPeriodLabels = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
  ];
  static const analyticsMini = <LandingMini>[
    LandingMini(label: 'الرحلات المكتملة', value: '1,182'),
    LandingMini(label: 'متوسط المقعد', value: '168 ج.م'),
  ];

  // ── Rider experience ────────────────────────────────────────────────────
  static const clientEyebrow = 'تجربة العميل';
  static const clientHeadline =
      'قدّم لعملائك تجربة أفضل، بدون ما تزود الحمل على فريقك';
  static const clientLead =
      'كل ما العميل يقدر يعمله بنفسه، يقلل الضغط على مكتبك وفريقك.';
  static const clientPoints = <String>[
    'استعراض الرحلات المتاحة ومواعيدها',
    'حجز المقعد وتأكيد الرحلة',
    'الدفع ومتابعة حالة الحجز',
    'الوصول لتفاصيل الرحلة بدون مكالمات',
    'استفسارات أقل على فريق المكتب',
  ];

  // ── Before / after ──────────────────────────────────────────────────────
  static const comparisonHeadline = 'من إدارة مشتتة... إلى تشغيل منظم';
  static const comparisonBeforeTitle = 'قبل EWT';
  static const comparisonAfterTitle = 'مع EWT';
  static const comparisonBefore = <String>[
    'متابعة على واتساب',
    'مكالمات كثيرة',
    'جداول متفرقة',
    'صعوبة معرفة المقاعد',
    'متابعة يدوية للكباتن',
    'أرقام غير واضحة',
    'اعتماد كبير على صاحب المكتب',
  ];
  static const comparisonAfter = <String>[
    'منصة واحدة',
    'رحلات منظمة',
    'حجوزات واضحة',
    'متابعة الكباتن',
    'بيانات تشغيلية',
    'رؤية مالية',
    'تقارير ومؤشرات',
    'تحكم أفضل',
  ];

  // ── Growth ──────────────────────────────────────────────────────────────
  static const growthHeadline = 'ابدأ منظمًا... وكبّر مكتبك بثقة';
  static const growthLead = 'EWT تساعدك تحافظ على السيطرة مع نمو عملياتك.';
  static const growth = <LandingGrowthStep>[
    LandingGrowthStep(
      number: '01',
      title: 'مكتب صغير',
      borderColor: LandingPalette.border,
      barColor: LandingPalette.well,
    ),
    LandingGrowthStep(
      number: '02',
      title: 'رحلات أكثر',
      borderColor: LandingPalette.border,
      barColor: Color(0xFFD6E0F5),
    ),
    LandingGrowthStep(
      number: '03',
      title: 'كباتن أكثر',
      borderColor: LandingPalette.border,
      barColor: Color(0xFFB9CDF2),
    ),
    LandingGrowthStep(
      number: '04',
      title: 'حجوزات أكثر',
      borderColor: LandingPalette.brandLine,
      barColor: Color(0xFF8FB2EC),
    ),
    LandingGrowthStep(
      number: '05',
      title: 'فريق أكبر',
      borderColor: LandingPalette.brandLine,
      barColor: Color(0xFF5C8FE3),
    ),
    LandingGrowthStep(
      number: '06',
      title: 'عملية نقل أكثر تنظيمًا',
      borderColor: LandingPalette.brandLine,
      barColor: LandingPalette.brand,
    ),
  ];

  // ── Why EWT ─────────────────────────────────────────────────────────────
  static const whyHeadline = 'ليه أصحاب مكاتب النقل يختاروا EWT؟';
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
  static const stepsHeadline = 'ابدأ استخدام EWT في خطوات بسيطة';
  static const steps = <LandingStepCard>[
    LandingStepCard(
      number: '01',
      icon: Icons.store_rounded,
      title: 'سجّل مكتبك',
      body: 'أنشئ حساب مكتبك وابدأ إعداد النظام.',
    ),
    LandingStepCard(
      number: '02',
      icon: Icons.alt_route_rounded,
      title: 'أضف خطوطك ورحلاتك',
      body: 'نظّم عمليات النقل والمواعيد.',
    ),
    LandingStepCard(
      number: '03',
      icon: Icons.group_add_rounded,
      title: 'أضف فريقك وكباتنك',
      body: 'وزّع المهام والصلاحيات.',
    ),
    LandingStepCard(
      number: '04',
      icon: Icons.play_circle_rounded,
      title: 'ابدأ التشغيل',
      body: 'تابع الرحلات والحجوزات والمدفوعات من لوحة التحكم.',
    ),
  ];

  // ── Trust ───────────────────────────────────────────────────────────────
  static const trustHeadline = 'نظام مصمم حول طبيعة عمل مكاتب النقل';
  static const trustLead =
      'مبني على الخطوات الفعلية لتشغيل مكتب النقل: من إنشاء الرحلة، لإسناد '
      'الكابتن، للحجز، للدفع، للتقرير.';
  static const trustItems = <LandingPoint>[
    LandingPoint(
      icon: Icons.admin_panel_settings_rounded,
      title: 'صلاحيات المستخدمين',
    ),
    LandingPoint(icon: Icons.settings_suggest_rounded, title: 'إدارة العمليات'),
    LandingPoint(icon: Icons.track_changes_rounded, title: 'تتبع حالة الرحلات'),
    LandingPoint(icon: Icons.event_seat_rounded, title: 'إدارة الحجوزات'),
    LandingPoint(icon: Icons.payments_rounded, title: 'متابعة المدفوعات'),
    LandingPoint(icon: Icons.storage_rounded, title: 'بيانات مركزية'),
    LandingPoint(icon: Icons.bar_chart_rounded, title: 'تقارير تشغيلية'),
  ];

  // ── Closing CTA ─────────────────────────────────────────────────────────
  static const ctaHeadline = 'جاهز تدير مكتبك بشكل أذكى؟';
  static const ctaBody =
      'ابدأ مع EWT وخلي إدارة الرحلات والحجوزات والكباتن والمدفوعات أسهل '
      'وأكثر تنظيمًا.';

  // ── FAQ ─────────────────────────────────────────────────────────────────
  static const faqHeadline = 'الأسئلة الشائعة';
  static const faq = <LandingFaqItem>[
    LandingFaqItem(
      'ما هي EWT؟',
      'نظام لإدارة مكاتب النقل: الخطوط والرحلات والكباتن والحجوزات والمدفوعات '
          'والتقارير في لوحة تحكم واحدة.',
    ),
    LandingFaqItem(
      'هل EWT مناسبة لمكاتب النقل الصغيرة؟',
      'نعم. تبدأ بعدد محدود من الخطوط والرحلات، وتتوسع مع نمو مكتبك بدون تغيير '
          'النظام.',
    ),
    LandingFaqItem(
      'هل يمكنني إدارة أكثر من خط ورحلة؟',
      'نعم، يمكنك إنشاء عدد غير محدود من الخطوط والرحلات اليومية أو المتكررة '
          'ومتابعة إشغال كل خط.',
    ),
    LandingFaqItem(
      'هل يمكنني إضافة أكثر من كابتن؟',
      'نعم، تضيف كباتن مكتبك وتسند لكل رحلة كابتنها وتتابع تنفيذه من لوحة '
          'التحكم.',
    ),
    LandingFaqItem(
      'هل يمكن لموظفي المكتب استخدام النظام؟',
      'نعم، تضيف مستخدمين لفريقك وتمنح كل واحد الصلاحيات المناسبة لدوره.',
    ),
    LandingFaqItem(
      'هل يمكنني متابعة الحجوزات والمدفوعات؟',
      'نعم، تتابع كل حجز ومقعده وحالة الدفع، مع متابعة المبالغ المحصلة '
          'والمعلقة.',
    ),
    LandingFaqItem(
      'هل يوجد تطبيق للكابتن؟',
      'نعم، تطبيق الكابتن يعرض الرحلات المسندة إليه وتفاصيلها وحالتها، وكل '
          'تحديث يظهر لك في لوحة التحكم.',
    ),
    LandingFaqItem(
      'هل يستطيع العملاء الحجز من خلال النظام؟',
      'نعم، يمكن للعميل استعراض الرحلات المتاحة وحجز مقعده ومتابعة حالة حجزه.',
    ),
    LandingFaqItem(
      'كيف أبدأ استخدام EWT؟',
      'سجّل مكتبك، أضف خطوطك ورحلاتك وفريقك، وابدأ التشغيل والمتابعة من لوحة '
          'التحكم.',
    ),
  ];

  // ── Footer ──────────────────────────────────────────────────────────────
  static const footerBlurb = 'نظام واحد لإدارة مكتب النقل بالكامل.';
  static const footerColumns = <LandingFooterColumn>[
    LandingFooterColumn(
      title: 'المنصة',
      links: ['المميزات', 'لوحة التحكم', 'كيف تعمل EWT؟'],
    ),
    LandingFooterColumn(
      title: 'للمكاتب',
      links: ['إدارة الرحلات', 'إدارة الكباتن', 'إدارة الحجوزات', 'التقارير'],
    ),
    LandingFooterColumn(
      title: 'الدعم',
      links: ['الأسئلة الشائعة', 'تواصل معنا'],
    ),
    LandingFooterColumn(title: 'الحساب', links: ['تسجيل الدخول', 'إنشاء حساب']),
  ];
  static const footerCopyright = '© 2026 EWT — Easy Way Transportation';
  static const footerTagline = 'مصمم لمكاتب النقل في مصر';
}
