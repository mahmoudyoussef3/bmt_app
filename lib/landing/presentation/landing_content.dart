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

  // ── Operations ──────────────────────────────────────────────────────────
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
          'امنح موظفي المكتب الصلاحيات المناسبة وساعد فريقك على العمل بشكل منظم.',
    ),
    LandingPoint(
      icon: Icons.group_rounded,
      title: 'إدارة العملاء',
      body: 'احتفظ برؤية واضحة لحجوزات وعملاء مكتبك.',
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
  static const clientJourney =
      <({String step, String title, String body, String shot})>[
        (
          step: '١',
          title: 'يدوّر على رحلته',
          body: 'كل الرحلات المتاحة على خطه، بمواعيدها وأسعارها.',
          shot: LandingShots.clientSearch,
        ),
        (
          step: '٢',
          title: 'يختار مقعده',
          body: 'خريطة مقاعد العربية، والمحجوز منها واضح قبل ما يدفع.',
          shot: LandingShots.clientSeats,
        ),
        (
          step: '٣',
          title: 'يتابع رحلته',
          body: 'تفاصيل الحجز وحالة الرحلة بدون مكالمة واحدة لمكتبك.',
          shot: LandingShots.clientTrip,
        ),
        (
          step: '٤',
          title: 'يدفع من محفظته',
          body: 'رصيده وحركة مدفوعاته في مكان واحد.',
          shot: LandingShots.clientWallet,
        ),
      ];
  // ── Before / after ──────────────────────────────────────────────────────
  static const before = <String>[
    'متابعة على واتساب',
    'مكالمات كثيرة',
    'جداول متفرقة',
    'صعوبة معرفة المقاعد',
    'متابعة يدوية للكباتن',
    'أرقام غير واضحة',
    'اعتماد كبير على صاحب المكتب',
  ];
  static const after = <String>[
    'منصة واحدة',
    'رحلات منظمة',
    'حجوزات واضحة',
    'متابعة الكباتن',
    'بيانات تشغيلية',
    'رؤية مالية',
    'تقارير ومؤشرات',
    'تحكم أفضل',
  ];

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
  static const faq = <({String question, String answer})>[
    (
      question: 'ما هي EWT؟',
      answer:
          'نظام لإدارة مكاتب النقل: الخطوط والرحلات والكباتن والحجوزات والمدفوعات والتقارير في لوحة تحكم واحدة.',
    ),
    (
      question: 'هل EWT مناسبة لمكاتب النقل الصغيرة؟',
      answer:
          'نعم. تبدأ بعدد محدود من الخطوط والرحلات، وتتوسع مع نمو مكتبك بدون تغيير النظام.',
    ),
    (
      question: 'هل يمكنني إدارة أكثر من خط ورحلة؟',
      answer:
          'نعم، يمكنك إنشاء عدد غير محدود من الخطوط والرحلات اليومية أو المتكررة ومتابعة إشغال كل خط.',
    ),
    (
      question: 'هل يمكنني إضافة أكثر من كابتن؟',
      answer:
          'نعم، تضيف كباتن مكتبك وتسند لكل رحلة كابتنها وتتابع تنفيذه من لوحة التحكم.',
    ),
    (
      question: 'هل يمكن لموظفي المكتب استخدام النظام؟',
      answer:
          'نعم، تضيف مستخدمين لفريقك وتمنح كل واحد الصلاحيات المناسبة لدوره.',
    ),
    (
      question: 'هل يمكنني متابعة الحجوزات والمدفوعات؟',
      answer:
          'نعم، تتابع كل حجز ومقعده وحالة الدفع، مع متابعة المبالغ المحصلة والمعلقة.',
    ),
    (
      question: 'هل يوجد تطبيق للكابتن؟',
      answer:
          'نعم، تطبيق الكابتن يعرض الرحلات المسندة إليه وتفاصيلها وحالتها، وكل تحديث يظهر لك في لوحة التحكم.',
    ),
    (
      question: 'هل يستطيع العملاء الحجز من خلال النظام؟',
      answer:
          'نعم، يمكن للعميل استعراض الرحلات المتاحة وحجز مقعده ومتابعة حالة حجزه.',
    ),
    (
      question: 'كيف أبدأ استخدام EWT؟',
      answer:
          'سجّل مكتبك، أضف خطوطك ورحلاتك وفريقك، وابدأ التشغيل والمتابعة من لوحة التحكم.',
    ),
  ];

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

/// An icon + title + body triple — the page's most repeated shape, used by the
/// problem grid, the operations grid, the "why" grid and the trust rail.
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
