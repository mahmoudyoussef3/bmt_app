import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_layout.dart';

/// «الأسئلة الشائعة» — a single-open accordion.
///
/// One panel at a time, as in the design: nine answers expanded at once would
/// bury the CTA above them, and the reader is comparing questions, not
/// reading the set.
class FaqSection extends StatefulWidget {
  const FaqSection({super.key});

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    final headline = landingClamp(context, min: 24, vw: 3, max: 36);
    return Padding(
      padding: EdgeInsets.only(bottom: landingSectionGap(context)),
      child: LandingContainer(
        maxWidth: 860,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الأسئلة الشائعة',
              textAlign: TextAlign.center,
              style: LandingType.heading(headline),
            ),
            SizedBox(height: landingClamp(context, min: 20, vw: 3, max: 34)),
            for (final (index, entry) in LandingContent.faq.indexed) ...[
              if (index > 0) const SizedBox(height: 10),
              _FaqTile(
                question: entry.question,
                answer: entry.answer,
                open: _open == index,
                onTap: () =>
                    setState(() => _open = _open == index ? -1 : index),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.open,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool open;
  final VoidCallback onTap;

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
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
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
                        question,
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
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 17),
                    child: Text(
                      answer,
                      style: LandingType.cardBody(13.5).copyWith(height: 1.9),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
