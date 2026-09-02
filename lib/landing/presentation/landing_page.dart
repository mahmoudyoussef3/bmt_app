import 'package:flutter/material.dart';

import 'sections/analytics_section.dart';
import 'sections/bookings_section.dart';
import 'sections/captain_section.dart';
import 'sections/client_section.dart';
import 'sections/comparison_section.dart';
import 'sections/cta_section.dart';
import 'sections/dashboard_section.dart';
import 'sections/faq_section.dart';
import 'sections/finance_section.dart';
import 'sections/footer_section.dart';
import 'sections/growth_section.dart';
import 'sections/hero_section.dart';
import 'sections/landing_navbar.dart';
import 'sections/modules_section.dart';
import 'sections/operations_section.dart';
import 'sections/problem_section.dart';
import 'sections/steps_section.dart';
import 'sections/trust_section.dart';
import 'sections/why_section.dart';
import 'theme/landing_theme.dart';
import 'widgets/landing_info_dialog.dart';

/// The EWT marketing site, assembled from the `EWT Landing v2` design.
///
/// Everything the header needs is derived from one scroll listener: whether
/// the page has left the top (which shrinks the header) and which anchor the
/// reader is currently inside (which marks the current nav link). Section
/// anchors are [GlobalKey]s rather than offsets so the marks stay correct as
/// sections reflow at different widths.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scrollController = ScrollController();

  final _topKey = GlobalKey();
  final _dashboardKey = GlobalKey();
  final _operationsKey = GlobalKey();
  final _analyticsKey = GlobalKey();
  final _stepsKey = GlobalKey();
  final _ctaKey = GlobalKey();
  final _faqKey = GlobalKey();

  bool _scrolled = false;
  int _activeLink = 0;

  /// The nav's anchors, in page order — the same list drives both the link
  /// rail and the current-section calculation.
  late final List<GlobalKey> _anchors = [
    _topKey,
    _operationsKey,
    _stepsKey,
    _dashboardKey,
    _faqKey,
    _ctaKey,
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 24;
    final active = _resolveActiveLink();
    if (scrolled != _scrolled || active != _activeLink) {
      setState(() {
        _scrolled = scrolled;
        _activeLink = active;
      });
    }
  }

  /// The current anchor is the last one whose top edge has passed just under
  /// the header. Anchors are listed in nav order, which is *not* page order
  /// («كيف تعمل EWT؟» sits after «لوحة التحكم» on the page), so the scan
  /// compares real positions rather than trusting the list's order.
  int _resolveActiveLink() {
    var best = 0;
    var bestTop = double.negativeInfinity;
    for (var i = 0; i < _anchors.length; i++) {
      final box = _anchors[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top <= 140 && top > bestTop) {
        bestTop = top;
        best = i;
      }
    }
    return best;
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
      // Leave the sticky header clear of the section it just scrolled to.
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      alignment: 0.06,
    );
  }

  void _showGetStarted() => LandingInfoDialog.show(
    context,
    title: 'ابدأ مع EWT',
    message:
        'مكاتب النقل بتنضم لـ EWT حاليًا بمساعدة فريقنا مباشرة. تواصل معنا '
        'وهنساعدك في إعداد حساب مكتبك وتجهيز خطوطك ورحلاتك خطوة بخطوة.',
  );

  void _showContact() => LandingInfoDialog.show(
    context,
    title: 'تواصل معنا',
    message:
        'دي نسخة تعريفية من منصة EWT. لمعرفة الخطة المناسبة لمكتبك أو لأي '
        'استفسار، فريق EWT يسعده التواصل معك.',
  );

  void _showLogin() => LandingInfoDialog.show(
    context,
    title: 'تسجيل الدخول',
    message:
        'تسجيل الدخول متاح لمكاتب النقل المشتركة في EWT عبر لوحة التحكم '
        'الخاصة بمكتبك.',
  );

  /// Footer links reuse the page's own anchors and dialogs, so no entry in
  /// the four columns is a dead end.
  void _onFooterLink(String label) {
    switch (label) {
      case 'المميزات':
      case 'إدارة الرحلات':
      case 'إدارة الكباتن':
      case 'إدارة الحجوزات':
        _scrollTo(_operationsKey);
      case 'لوحة التحكم':
        _scrollTo(_dashboardKey);
      case 'كيف تعمل EWT؟':
        _scrollTo(_stepsKey);
      case 'التقارير':
        _scrollTo(_analyticsKey);
      case 'الأسئلة الشائعة':
        _scrollTo(_faqKey);
      case 'تواصل معنا':
        _showContact();
      case 'تسجيل الدخول':
        _showLogin();
      case 'إنشاء حساب':
        _showGetStarted();
      default:
        _scrollTo(_topKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final links = [
      LandingNavLink(label: 'الرئيسية', onTap: () => _scrollTo(_topKey)),
      LandingNavLink(label: 'المميزات', onTap: () => _scrollTo(_operationsKey)),
      LandingNavLink(label: 'كيف تعمل EWT؟', onTap: () => _scrollTo(_stepsKey)),
      LandingNavLink(
        label: 'لوحة التحكم',
        onTap: () => _scrollTo(_dashboardKey),
      ),
      LandingNavLink(label: 'الأسئلة الشائعة', onTap: () => _scrollTo(_faqKey)),
      LandingNavLink(label: 'تواصل معنا', onTap: () => _scrollTo(_ctaKey)),
    ];

    return Scaffold(
      backgroundColor: LandingPalette.page,
      body: Column(
        children: [
          LandingNavbar(
            links: links,
            activeIndex: _activeLink,
            scrolled: _scrolled,
            onLogin: _showLogin,
            onGetStarted: _showGetStarted,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HeroSection(
                    key: _topKey,
                    onGetStarted: _showGetStarted,
                    onSeeDashboard: () => _scrollTo(_dashboardKey),
                  ),
                  ProblemSection(
                    onSeeDashboard: () => _scrollTo(_dashboardKey),
                  ),
                  const ModulesSection(),
                  DashboardSection(key: _dashboardKey),
                  OperationsSection(key: _operationsKey),
                  const CaptainSection(),
                  const BookingsSection(),
                  const FinanceSection(),
                  AnalyticsSection(key: _analyticsKey),
                  const ClientSection(),
                  const ComparisonSection(),
                  const GrowthSection(),
                  const WhySection(),
                  StepsSection(key: _stepsKey, onGetStarted: _showGetStarted),
                  const TrustSection(),
                  CtaSection(
                    key: _ctaKey,
                    onGetStarted: _showGetStarted,
                    onContact: _showContact,
                  ),
                  FaqSection(key: _faqKey),
                  FooterSection(onLinkTap: _onFooterLink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
