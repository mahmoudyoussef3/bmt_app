import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_brand.dart';
import '../widgets/landing_layout.dart';

/// The navy footer: the wordmark and one line about the product, four link
/// columns, and the copyright rule.
class FooterSection extends StatelessWidget {
  const FooterSection({super.key, required this.onLinkTap});

  /// Every footer link resolves through the page so a column entry either
  /// scrolls to its section or opens the same honest dialog the header's
  /// CTAs use — no dead anchors.
  final void Function(String label) onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: LandingPalette.navy,
      padding: EdgeInsets.only(
        top: landingClamp(context, min: 42, vw: 5, max: 66),
      ),
      child: LandingContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LandingAutoGrid(
              minItemWidth: 180,
              spacing: landingClamp(context, min: 24, vw: 3, max: 38),
              runSpacing: 32,
              children: [
                const _FooterBrand(),
                for (final column in LandingContent.footerColumns)
                  _FooterColumn(
                    title: column.title,
                    links: column.links,
                    onLinkTap: onLinkTap,
                  ),
              ],
            ),
            SizedBox(height: landingClamp(context, min: 32, vw: 4, max: 48)),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2026 EWT — Easy Way Transportation',
                    style: LandingType.label(
                      12.5,
                      color: Colors.white.withValues(alpha: 0.55),
                      weight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'مصمم لمكاتب النقل في مصر',
                    style: LandingType.label(
                      12.5,
                      color: Colors.white.withValues(alpha: 0.55),
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const LandingBrandMark(onDark: true),
        const SizedBox(height: 15),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: Text(
            'نظام واحد لإدارة مكتب النقل بالكامل.',
            style: LandingType.cardBody(
              13,
              color: Colors.white.withValues(alpha: 0.66),
            ).copyWith(height: 1.85),
          ),
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({
    required this.title,
    required this.links,
    required this.onLinkTap,
  });

  final String title;
  final List<String> links;
  final void Function(String label) onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: LandingType.cardTitle(13, color: Colors.white)),
        const SizedBox(height: 13),
        for (final (index, link) in links.indexed) ...[
          if (index > 0) const SizedBox(height: 9),
          _FooterLink(label: link, onTap: () => onLinkTap(link)),
        ],
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: LandingType.label(
            13,
            color: _hovered
                ? Colors.white
                : Colors.white.withValues(alpha: 0.66),
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
