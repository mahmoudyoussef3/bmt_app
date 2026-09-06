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
import 'sections/landing_header.dart';
import 'sections/modules_section.dart';
import 'sections/operations_section.dart';
import 'sections/problem_section.dart';
import 'sections/steps_section.dart';
import 'sections/trust_section.dart';
import 'sections/why_section.dart';
import 'theme/landing_theme.dart';
import 'widgets/landing_motion.dart';

/// The EWT marketing site, assembled from the `EWT Landing v2` design.
///
/// The bands run in the design's own order, and every call to action is an
/// anchor into one of them — the header, the hero, the challenge banner, the
/// steps band and the closing panel all move the reader down the same page
/// rather than opening anything.
///
/// The header carries the page's only piece of state: past 24px of scroll it
/// tightens and grows a shadow. Anchors are [GlobalKey]s rather than measured
/// offsets, so they stay correct as the sections reflow at any width.
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
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
      // Leave the sticky header clear of the band it just scrolled to.
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      alignment: 0.06,
    );
  }

  void _scrollToTop() => _scrollController.animateTo(
    0,
    duration: const Duration(milliseconds: 520),
    curve: Curves.easeInOutCubic,
  );

  /// The footer's four columns reuse the page's own anchors, so no entry in
  /// them is a dead end.
  void _onFooterLink(String label) {
    switch (label) {
      case 'المميزات':
      case 'إدارة الرحلات':
      case 'إدارة الكباتن':
      case 'إدارة الحجوزات':
        _scrollTo(_operationsKey);
      case 'لوحة التحكم':
        _scrollTo(_dashboardKey);
      case 'التقارير':
        _scrollTo(_analyticsKey);
      case 'كيف تعمل EWT؟':
        _scrollTo(_stepsKey);
      case 'الأسئلة الشائعة':
        _scrollTo(_faqKey);
      case 'تواصل معنا':
      case 'تسجيل الدخول':
      case 'إنشاء حساب':
        _scrollTo(_ctaKey);
      default:
        _scrollToTop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final links = [
      LandingNavItem(label: LandingContent.navHome, onTap: _scrollToTop),
      LandingNavItem(
        label: LandingContent.navFeatures,
        onTap: () => _scrollTo(_operationsKey),
      ),
      LandingNavItem(
        label: LandingContent.navHowItWorks,
        onTap: () => _scrollTo(_stepsKey),
      ),
      LandingNavItem(
        label: LandingContent.navDashboard,
        onTap: () => _scrollTo(_dashboardKey),
      ),
      LandingNavItem(
        label: LandingContent.navFaq,
        onTap: () => _scrollTo(_faqKey),
      ),
      LandingNavItem(
        label: LandingContent.navContact,
        onTap: () => _scrollTo(_ctaKey),
      ),
    ];

    return Scaffold(
      backgroundColor: LandingPalette.page,
      body: Column(
        children: [
          LandingHeader(
            links: links,
            scrolled: _scrolled,
            onSignIn: () => _scrollTo(_ctaKey),
            onGetStarted: () => _scrollTo(_ctaKey),
          ),
          Expanded(
            // Everything under here is allowed to move: the scope hands the
            // page's scroll ticks to the reveals, and it is also the switch
            // that keeps the per-section capture harness perfectly still.
            child: LandingRevealScope(
              ticker: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The fold has no scroll to wait for, so it plays on load
                    // — and it is the one band that arrives in pieces, the
                    // copy leading the rig by a beat.
                    LandingReveal(
                      rise: 16,
                      child: HeroSection(
                        key: _topKey,
                        onGetStarted: () => _scrollTo(_ctaKey),
                        onSeeDashboard: () => _scrollTo(_dashboardKey),
                      ),
                    ),
                    LandingReveal(
                      child: ProblemSection(
                        onSeeDashboard: () => _scrollTo(_dashboardKey),
                      ),
                    ),
                    const LandingReveal(child: ModulesSection()),
                    LandingReveal(child: DashboardSection(key: _dashboardKey)),
                    LandingReveal(
                      child: OperationsSection(key: _operationsKey),
                    ),
                    const LandingReveal(child: CaptainSection()),
                    const LandingReveal(child: BookingsSection()),
                    const LandingReveal(child: FinanceSection()),
                    LandingReveal(child: AnalyticsSection(key: _analyticsKey)),
                    const LandingReveal(child: ClientSection()),
                    const LandingReveal(child: ComparisonSection()),
                    const LandingReveal(child: GrowthSection()),
                    const LandingReveal(child: WhySection()),
                    LandingReveal(
                      child: StepsSection(
                        key: _stepsKey,
                        onGetStarted: () => _scrollTo(_ctaKey),
                      ),
                    ),
                    const LandingReveal(child: TrustSection()),
                    LandingReveal(
                      child: CtaSection(
                        key: _ctaKey,
                        onGetStarted: _scrollToTop,
                        onContact: () => _scrollTo(_faqKey),
                      ),
                    ),
                    LandingReveal(child: FaqSection(key: _faqKey)),
                    LandingReveal(
                      child: FooterSection(onLinkTap: _onFooterLink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
