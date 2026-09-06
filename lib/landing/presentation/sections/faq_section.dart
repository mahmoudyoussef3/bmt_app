import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_layout.dart';

/// «الأسئلة الشائعة» — an accordion in an 860px column, one panel open at a
/// time, the first open on arrival.
class FaqSection extends StatefulWidget {
  const FaqSection({super.key});

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      padTop: false,
      maxWidth: 860,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LandingContent.faqHeadline,
            textAlign: TextAlign.center,
            style: LandingType.heading(
              landingClamp(context, min: 24, vw: 3, max: 36),
            ),
          ),
          SizedBox(height: landingClamp(context, min: 20, vw: 3, max: 34)),
          for (var i = 0; i < LandingContent.faq.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _FaqPanel(
              item: LandingContent.faq[i],
              open: _open == i,
              onToggle: () => setState(() => _open = _open == i ? -1 : i),
            ),
          ],
        ],
      ),
    );
  }
}

class _FaqPanel extends StatelessWidget {
  const _FaqPanel({
    required this.item,
    required this.open,
    required this.onToggle,
  });

  final LandingFaqItem item;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: LandingPalette.surface,
        borderRadius: LandingRadii.cardR,
        border: Border.all(
          color: open ? LandingPalette.brandLine : LandingPalette.border,
        ),
        boxShadow: LandingPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.question,
                          style: LandingType.label(
                            14.5,
                            color: LandingPalette.ink,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.expand_more_rounded,
                          size: 21,
                          color: LandingPalette.brandInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: open
                ? TweenAnimationBuilder<double>(
                    // The answer fades in behind the opening panel rather
                    // than being revealed already fully inked by the height
                    // change alone.
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    builder: (context, t, child) =>
                        Opacity(opacity: t, child: child),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 17),
                      child: Text(
                        item.answer,
                        style: LandingType.cardBody(13.5).copyWith(height: 1.9),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
