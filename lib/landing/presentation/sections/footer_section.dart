import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import '../widgets/landing_container.dart';
import '../widgets/landing_info_dialog.dart';
import 'landing_navbar.dart' show LandingNavLink;

/// The page's closing band: brand mark, section links, and the legal /
/// account links that a SaaS footer is expected to carry.
///
/// [productLinks] reuses [LandingNavLink] from the navbar rather than a
/// footer-local type — same list of destinations, so the two never drift out
/// of sync when a section is renamed.
class FooterSection extends StatelessWidget {
  const FooterSection({
    super.key,
    required this.productLinks,
    required this.onLogin,
    required this.onContactSales,
  });

  final List<LandingNavLink> productLinks;
  final VoidCallback onLogin;
  final VoidCallback onContactSales;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mobile = LandingContainer.isMobile(context);
    final year = DateTime.now().year;

    return Container(
      color: scheme.surfaceContainerLowest,
      child: LandingContainer(
        maxWidth: 1160,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: mobile ? 40 : 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              mobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BrandColumn(scheme: scheme),
                        const SizedBox(height: AppSpacing.xLarge),
                        _LinksColumn(
                          title: 'المنتج',
                          links: productLinks
                              .map((l) => (label: l.label, onTap: l.onTap))
                              .toList(),
                        ),
                        const SizedBox(height: AppSpacing.xLarge),
                        _AccountColumn(onLogin: onLogin, onContactSales: onContactSales),
                        const SizedBox(height: AppSpacing.xLarge),
                        _LegalColumn(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _BrandColumn(scheme: scheme)),
                        Expanded(
                          child: _LinksColumn(
                            title: 'المنتج',
                            links: productLinks
                                .map((l) => (label: l.label, onTap: l.onTap))
                                .toList(),
                          ),
                        ),
                        Expanded(
                          child: _AccountColumn(
                            onLogin: onLogin,
                            onContactSales: onContactSales,
                          ),
                        ),
                        Expanded(child: _LegalColumn()),
                      ],
                    ),
              const SizedBox(height: AppSpacing.xLarge),
              Divider(color: scheme.outlineVariant),
              const SizedBox(height: AppSpacing.medium),
              Text(
                '© $year EWT — Easy Way Transportation',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandColumn extends StatelessWidget {
  const _BrandColumn({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
              child: Icon(DashboardIcons.fleetActive, size: 16, color: scheme.onPrimary),
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              'EWT',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            'منصة تشغيل تساعد مكاتب النقل على إدارة أعمالها ومتابعة أدائها '
            'والنمو من مكان واحد.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.6),
          ),
        ),
      ],
    );
  }
}

class _LinksColumn extends StatelessWidget {
  const _LinksColumn({required this.title, required this.links});

  final String title;
  final List<({String label, VoidCallback onTap})> links;

  @override
  Widget build(BuildContext context) {
    return _FooterColumn(
      title: title,
      children: [
        for (final link in links) _FooterLink(label: link.label, onTap: link.onTap),
      ],
    );
  }
}

class _AccountColumn extends StatelessWidget {
  const _AccountColumn({required this.onLogin, required this.onContactSales});

  final VoidCallback onLogin;
  final VoidCallback onContactSales;

  @override
  Widget build(BuildContext context) {
    return _FooterColumn(
      title: 'الحساب',
      children: [
        _FooterLink(label: 'تسجيل الدخول', onTap: onLogin),
        _FooterLink(label: 'تواصل معنا', onTap: onContactSales),
      ],
    );
  }
}

class _LegalColumn extends StatelessWidget {
  const _LegalColumn();

  @override
  Widget build(BuildContext context) {
    return _FooterColumn(
      title: 'قانوني',
      children: [
        _FooterLink(
          label: 'الخصوصية',
          onTap: () => LandingInfoDialog.show(
            context,
            title: 'سياسة الخصوصية',
            message: 'سياسة الخصوصية الخاصة بمكاتب النقل المشتركة في EWT قيد الإعداد. '
                'تواصل معنا إذا احتجت تفاصيل الآن.',
          ),
        ),
        _FooterLink(
          label: 'الشروط والأحكام',
          onTap: () => LandingInfoDialog.show(
            context,
            title: 'الشروط والأحكام',
            message: 'شروط استخدام EWT الخاصة بمكاتب النقل قيد الإعداد. '
                'تواصل معنا إذا احتجت تفاصيل الآن.',
          ),
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        ...children,
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: InkWell(
        onTap: onTap,
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
