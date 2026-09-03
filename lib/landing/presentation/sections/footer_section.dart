import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_brand.dart';
import '../widgets/landing_contact.dart';
import '../widgets/landing_layout.dart';

/// The navy footer: an identity block that carries the real contact details,
/// the four link columns beside it, and the copyright rule.
///
/// The brand block is given its own half of the split rather than a fifth
/// equal cell — as one cell among five it read as another link column while
/// carrying none of the same content, and the reader who scrolled this far
/// looking for a way to reach the office had nothing to press.
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
        top: landingClamp(context, min: 44, vw: 5, max: 70),
        bottom: landingClamp(context, min: 18, vw: 2, max: 26),
      ),
      child: LandingContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LandingSplit(
              // 340px identity + 500px of columns.
              breakpoint: 840,
              startFlex: 4,
              endFlex: 7,
              gap: landingClamp(context, min: 32, vw: 3.5, max: 56),
              crossAxisAlignment: CrossAxisAlignment.start,
              start: const _FooterBrand(),
              end: LandingAutoGrid(
                minItemWidth: 140,
                spacing: landingClamp(context, min: 16, vw: 2, max: 28),
                runSpacing: 30,
                stretch: false,
                children: [
                  for (final column in LandingContent.footerColumns)
                    _FooterColumn(
                      title: column.title,
                      links: column.links,
                      onLinkTap: onLinkTap,
                    ),
                ],
              ),
            ),
            SizedBox(height: landingClamp(context, min: 34, vw: 4, max: 52)),
            Container(
              padding: const EdgeInsets.only(top: 18),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // A run of Latin and digits with no strong RTL character in
                  // it: left to the paragraph's direction it renders back to
                  // front, ending on the copyright sign.
                  Text(
                    '© 2026 EWT — Easy Way Transportation',
                    textDirection: TextDirection.ltr,
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
          constraints: const BoxConstraints(maxWidth: 290),
          child: Text(
            'نظام واحد لإدارة مكتب النقل بالكامل.',
            style: LandingType.cardBody(
              13,
              color: Colors.white.withValues(alpha: 0.66),
            ).copyWith(height: 1.85),
          ),
        ),
        const SizedBox(height: 18),
        for (final (index, channel) in LandingChannel.values.indexed) ...[
          if (index > 0) const SizedBox(height: 10),
          _FooterLink(
            label: channel.value,
            icon: channel.icon,
            ltr: true,
            semanticsLabel: '${channel.label} ${channel.value}',
            onTap: () => launchLandingUri(context, channel.uri),
          ),
        ],
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
        // The heading names the group; the links are what the reader is here
        // to press, so the brighter ink goes to them and not to the label.
        Text(
          title,
          style: LandingType.label(
            11.5,
            color: Colors.white.withValues(alpha: 0.45),
            weight: FontWeight.w800,
          ).copyWith(letterSpacing: 0.6),
        ),
        const SizedBox(height: 14),
        for (final (index, link) in links.indexed) ...[
          if (index > 0) const SizedBox(height: 10),
          _FooterLink(label: link, onTap: () => onLinkTap(link)),
        ],
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({
    required this.label,
    required this.onTap,
    this.icon,
    this.ltr = false,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback onTap;

  /// Set on the contact rows, which name their channel with a glyph.
  final IconData? icon;

  /// An address or a phone number reads left-to-right on this RTL page.
  final bool ltr;
  final String? semanticsLabel;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      widget.label,
      textDirection: widget.ltr ? TextDirection.ltr : null,
      style:
          LandingType.label(
            13,
            color: _hovered
                ? Colors.white
                : Colors.white.withValues(alpha: 0.72),
            weight: FontWeight.w600,
          ).copyWith(
            // The one hover affordance a link owes the reader.
            decoration: _hovered
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: Colors.white.withValues(alpha: 0.5),
          ),
    );

    return Semantics(
      button: true,
      label: widget.semanticsLabel ?? widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: widget.icon == null
              ? text
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      size: 15,
                      color: Colors.white.withValues(
                        alpha: _hovered ? 0.75 : 0.45,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Flexible(child: text),
                  ],
                ),
        ),
      ),
    );
  }
}
