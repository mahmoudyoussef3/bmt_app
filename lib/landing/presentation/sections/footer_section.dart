import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_layout.dart';
import 'landing_header.dart';

/// The navy footer: the mark, four link columns and the legal line.
class FooterSection extends StatelessWidget {
  const FooterSection({super.key, required this.onLinkTap});

  final ValueChanged<String> onLinkTap;

  @override
  Widget build(BuildContext context) {
    final gap = landingClamp(context, min: 24, vw: 3, max: 38);
    return ColoredBox(
      color: LandingPalette.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: landingClamp(context, min: 42, vw: 5, max: 66),
            ),
            child: LandingContainer(
              child: LandingAutoGrid(
                minItemWidth: 180,
                spacing: gap,
                stretch: false,
                stagger: true,
                children: [
                  const _FooterBrand(),
                  for (final column in LandingContent.footerColumns)
                    _FooterColumn(column: column, onLinkTap: onLinkTap),
                ],
              ),
            ),
          ),
          SizedBox(height: landingClamp(context, min: 32, vw: 4, max: 48)),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
            child: LandingContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Text(
                        LandingContent.footerCopyright,
                        style: LandingType.label(
                          12.5,
                          color: Colors.white.withValues(alpha: 0.55),
                          weight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        LandingContent.footerTagline,
                        style: LandingType.label(
                          12.5,
                          color: Colors.white.withValues(alpha: 0.55),
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
        const LandingFooterMark(),
        const SizedBox(height: 15),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: Text(
            LandingContent.footerBlurb,
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
  const _FooterColumn({required this.column, required this.onLinkTap});

  final LandingFooterColumn column;
  final ValueChanged<String> onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          column.title,
          style: LandingType.metric(
            13,
            color: Colors.white,
          ).copyWith(letterSpacing: 0),
        ),
        const SizedBox(height: 13),
        for (var i = 0; i < column.links.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          _FooterLink(
            label: column.links[i],
            onTap: () => onLinkTap(column.links[i]),
          ),
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
    return Semantics(
      button: true,
      child: MouseRegion(
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
      ),
    );
  }
}
