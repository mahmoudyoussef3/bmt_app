import 'package:flutter/material.dart';

import 'sections/apps_section.dart';
import 'sections/business_intelligence_section.dart';
import 'sections/cta_section.dart';
import 'sections/features_section.dart';
import 'sections/footer_section.dart';
import 'sections/hero_section.dart';
import 'sections/landing_navbar.dart';
import 'sections/licensing_section.dart';
import 'sections/operations_story_section.dart';
import 'sections/pricing_section.dart';
import 'sections/problem_section.dart';
import 'sections/security_section.dart';
import 'sections/solution_section.dart';
import 'widgets/landing_container.dart';
import 'widgets/landing_info_dialog.dart';

/// The full long-form marketing page, assembled from one section widget per
/// [GlobalKey] anchor. [_scrollTo] is the one thing every "jump to a
/// section" action in the page shares — the navbar links, the footer's
/// product column and the hero's secondary CTA all resolve through it,
/// rather than each carrying its own [Scrollable.ensureVisible] call.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scrollController = ScrollController();

  final _productKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _intelligenceKey = GlobalKey();
  final _pricingKey = GlobalKey();
  final _contactKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  /// CTAs with no real destination yet get one honest dialog instead of a
  /// dead link — see [LandingInfoDialog] and the login/legal notes it was
  /// built for.
  void _showGetStartedDialog() {
    LandingInfoDialog.show(
      context,
      title: 'ابدأ مع EWT',
      message:
          'EWT تنضم مكاتب النقل إليها حالياً بمساعدة فريقنا مباشرة. '
          'تواصل معنا وسنساعدك في إعداد حساب مكتبك والبدء خطوة بخطوة.',
    );
  }

  void _showContactDialog() {
    LandingInfoDialog.show(
      context,
      title: 'تواصل معنا',
      message:
          'هذه نسخة تعريفية من منصة EWT. لمعرفة الخطة المناسبة لمكتبك أو '
          'لأي استفسار، يسعد فريق EWT بالتواصل معك.',
    );
  }

  void _showLoginDialog() {
    LandingInfoDialog.show(
      context,
      title: 'تسجيل الدخول',
      message: 'تسجيل الدخول متاح لمكاتب النقل المشتركة في EWT عبر لوحة التحكم الخاصة بمكتبك.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final links = [
      LandingNavLink(label: 'المنتج', onTap: () => _scrollTo(_productKey)),
      LandingNavLink(label: 'المزايا', onTap: () => _scrollTo(_featuresKey)),
      LandingNavLink(label: 'التقارير الذكية', onTap: () => _scrollTo(_intelligenceKey)),
      LandingNavLink(label: 'الأسعار', onTap: () => _scrollTo(_pricingKey)),
      LandingNavLink(label: 'تواصل', onTap: () => _scrollTo(_contactKey)),
    ];

    return Scaffold(
      body: Column(
        children: [
          LandingNavbar(
            links: links,
            onLogin: _showLoginDialog,
            onGetStarted: _showGetStartedDialog,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HeroSection(
                    onGetStarted: _showGetStartedDialog,
                    onSeeProduct: () => _scrollTo(_productKey),
                  ),
                  const LandingSectionPadding(child: ProblemSection()),
                  LandingSectionPadding(key: _productKey, child: const SolutionSection()),
                  LandingSectionPadding(key: _featuresKey, child: const FeaturesSection()),
                  const LandingSectionPadding(child: AppsSection()),
                  LandingSectionPadding(
                    key: _intelligenceKey,
                    child: const BusinessIntelligenceSection(),
                  ),
                  const LandingSectionPadding(child: OperationsStorySection()),
                  const LandingSectionPadding(child: LicensingSection()),
                  const LandingSectionPadding(tight: true, child: SecuritySection()),
                  LandingSectionPadding(
                    key: _pricingKey,
                    child: PricingSection(onContactSales: _showContactDialog),
                  ),
                  CtaSection(
                    onGetStarted: _showGetStartedDialog,
                    onContactSales: _showContactDialog,
                  ),
                  FooterSection(
                    key: _contactKey,
                    productLinks: links,
                    onLogin: _showLoginDialog,
                    onContactSales: _showContactDialog,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
