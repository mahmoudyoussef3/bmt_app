import 'package:flutter/material.dart';

import 'landing_content.dart';
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
import 'widgets/landing_reveal.dart';
import 'widgets/landing_scroll_aids.dart';

/// The EWT marketing site, assembled from the `EWT Landing v2` design.
///
/// Everything the header needs is derived from one scroll listener: whether
/// the page has left the top (which shrinks the header), which anchor the
/// reader is currently inside (which marks the current nav link), how far
/// down the page they are (the header's progress rule) and whether they are
/// far enough down to be offered the way back up. Section anchors are
/// [GlobalKey]s rather than offsets so the marks stay correct as sections
/// reflow at different widths.
///
/// The section order is the nav's order. It has to be: the header marks the
/// current section, and a page whose bands do not run in the order its links
/// do makes that mark jump backwards as the reader scrolls forwards.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scrollController = ScrollController();

  final _topKey = GlobalKey();
  final _operationsKey = GlobalKey();
  final _dashboardKey = GlobalKey();
  final _captainKey = GlobalKey();
  final _bookingsKey = GlobalKey();
  final _financeKey = GlobalKey();
  final _analyticsKey = GlobalKey();
  final _clientKey = GlobalKey();
  final _stepsKey = GlobalKey();
  final _faqKey = GlobalKey();
  final _ctaKey = GlobalKey();

  bool _scrolled = false;
  int _activeLink = 0;

  /// Read every frame the page moves, so they are notifiers rather than
  /// [setState] flags — a progress rule that rebuilt eighteen sections per
  /// frame would cost more than it is worth.
  final _progress = ValueNotifier<double>(0);
  final _showBackToTop = ValueNotifier<bool>(false);

  /// The nav's anchors, in page order — the same list drives both the link
  /// rail and the current-section calculation.
  late final List<GlobalKey> _anchors = [
    _topKey,
    _operationsKey,
    _dashboardKey,
    _stepsKey,
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
    _progress.dispose();
    _showBackToTop.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    final extent = position.maxScrollExtent;
    _progress.value = extent <= 0
        ? 0
        : (position.pixels / extent).clamp(0.0, 1.0);
    // One full screen past the hero — before that the header is still close
    // enough that a button back to it is noise.
    _showBackToTop.value = position.pixels > position.viewportDimension;

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
  /// the header.
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

  /// «المميزات» is the page's index: each feature card hands the reader to
  /// the band that shows that module working. Those bands are anchors but not
  /// nav entries — they stay out of [_anchors] so the header keeps marking
  /// the six links the reader can actually see.
  void _openFeature(LandingFeatureTarget target) => _scrollTo(switch (target) {
    LandingFeatureTarget.dashboard => _dashboardKey,
    LandingFeatureTarget.captain => _captainKey,
    LandingFeatureTarget.bookings => _bookingsKey,
    LandingFeatureTarget.finance => _financeKey,
    LandingFeatureTarget.analytics => _analyticsKey,
    LandingFeatureTarget.client => _clientKey,
  });

  void _scrollToTop() => _scrollController.animateTo(
    0,
    duration: const Duration(milliseconds: 520),
    curve: Curves.easeInOutCubic,
  );

  void _showGetStarted() => LandingInfoDialog.show(
    context,
    title: 'ابدأ مع EWT',
    message:
        'مكاتب النقل بتنضم لـ EWT حاليًا بمساعدة فريقنا مباشرة. تواصل معنا '
        'وهنساعدك في إعداد حساب مكتبك وتجهيز خطوطك ورحلاتك خطوة بخطوة.',
  );

  void _showContact() => LandingContactDialog.show(context);

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
        _scrollToTop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final links = [
      LandingNavLink(label: 'الرئيسية', onTap: _scrollToTop),
      LandingNavLink(label: 'المميزات', onTap: () => _scrollTo(_operationsKey)),
      LandingNavLink(
        label: 'لوحة التحكم',
        onTap: () => _scrollTo(_dashboardKey),
      ),
      LandingNavLink(label: 'كيف تعمل EWT؟', onTap: () => _scrollTo(_stepsKey)),
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
            progress: _progress,
            onLogin: _showLogin,
            onGetStarted: _showGetStarted,
          ),
          Expanded(
            child: Stack(
              children: [
                LandingRevealScope(
                  ticker: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The hero is above the fold by definition, so it is
                        // the one band that never waits to be revealed.
                        HeroSection(
                          key: _topKey,
                          onGetStarted: _showGetStarted,
                          onSeeDashboard: () => _scrollTo(_dashboardKey),
                        ),
                        LandingReveal(
                          child: ProblemSection(
                            onSeeDashboard: () => _scrollTo(_dashboardKey),
                          ),
                        ),
                        const LandingReveal(child: ModulesSection()),
                        // «المميزات» then «لوحة التحكم»: what the office runs,
                        // then the console it runs it from — and the nav's own
                        // order, which the rest of the page now follows.
                        LandingReveal(
                          key: _operationsKey,
                          child: OperationsSection(onOpen: _openFeature),
                        ),
                        LandingReveal(
                          key: _dashboardKey,
                          child: const DashboardSection(),
                        ),
                        LandingReveal(
                          key: _captainKey,
                          child: const CaptainSection(),
                        ),
                        LandingReveal(
                          key: _bookingsKey,
                          child: const BookingsSection(),
                        ),
                        LandingReveal(
                          key: _financeKey,
                          child: const FinanceSection(),
                        ),
                        LandingReveal(
                          key: _analyticsKey,
                          child: const AnalyticsSection(),
                        ),
                        LandingReveal(
                          key: _clientKey,
                          child: const ClientSection(),
                        ),
                        const LandingReveal(child: ComparisonSection()),
                        const LandingReveal(child: GrowthSection()),
                        const LandingReveal(child: WhySection()),
                        LandingReveal(
                          key: _stepsKey,
                          child: StepsSection(onGetStarted: _showGetStarted),
                        ),
                        const LandingReveal(child: TrustSection()),
                        // Objections are answered *before* the ask, so the
                        // closing band is the last thing the reader passes
                        // rather than something they scroll away from.
                        LandingReveal(key: _faqKey, child: const FaqSection()),
                        LandingReveal(
                          key: _ctaKey,
                          child: CtaSection(onGetStarted: _showGetStarted),
                        ),
                        LandingReveal(
                          child: FooterSection(onLinkTap: _onFooterLink),
                        ),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 20,
                  bottom: 20,
                  child: LandingBackToTop(
                    visible: _showBackToTop,
                    onPressed: _scrollToTop,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
