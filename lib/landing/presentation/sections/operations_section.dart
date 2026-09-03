import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// «المميزات» — the eight modules an office runs, split into the two groups
/// the platform diagram above already names them in.
///
/// This band is the nav's «المميزات» target, so it is where a reader who
/// skipped the hero lands. That makes it an index, not a poster: the cards run
/// in two labelled halves rather than one undifferentiated field, each card
/// states two concrete things the module does, and each one hands off to the
/// band further down that shows it working — so arriving here never dead-ends.
class OperationsSection extends StatelessWidget {
  const OperationsSection({super.key, this.onOpen});

  /// Jumps to the section a card points at. Null in the capture harness,
  /// where there is no page to scroll — the cards then read as labels.
  final void Function(LandingFeatureTarget target)? onOpen;

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            eyebrow: 'المميزات',
            headline: 'شغّل مكتبك بشكل أكثر تنظيمًا',
            lead:
                'وحدات مترابطة تغطي دورة التشغيل كاملة — من إنشاء الخط، مرورًا '
                'بالرحلة والكابتن والحجز، وصولًا للتحصيل والتقارير.',
            maxWidth: 640,
          ),
          SizedBox(height: landingClamp(context, min: 28, vw: 3.5, max: 44)),
          for (final (index, group)
              in LandingContent.operationGroups.indexed) ...[
            if (index > 0)
              SizedBox(
                height: landingClamp(context, min: 30, vw: 3.5, max: 46),
              ),
            _FeatureGroupHeader(group: group),
            const SizedBox(height: 16),
            _FeatureGrid(features: group.features, onOpen: onOpen),
          ],
        ],
      ),
    );
  }
}

/// `٠١ · التشغيل اليومي ──────── caption` — the rule that splits the eight
/// cards. It collapses to two stacked lines before the caption would start
/// squeezing the label.
class _FeatureGroupHeader extends StatelessWidget {
  const _FeatureGroupHeader({required this.group});

  final LandingFeatureGroup group;

  @override
  Widget build(BuildContext context) {
    final numeral = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: LandingPalette.brandTint,
        borderRadius: LandingRadii.badgeR,
        border: Border.all(color: LandingPalette.brandLine),
      ),
      child: Text(
        group.index,
        style: LandingType.label(
          11.5,
          color: LandingPalette.brandInk,
          weight: FontWeight.w900,
        ),
      ),
    );
    final label = Text(group.label, style: LandingType.cardTitle(15.5));
    final caption = Text(
      group.caption,
      style: LandingType.label(12, color: LandingPalette.faint),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    const rule = SizedBox(
      height: 1,
      child: ColoredBox(color: LandingPalette.border),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The label wraps rather than truncates here: a group name is a
              // heading, and 320px-wide phones cannot fit the longer of the
              // two beside the numeral on one line.
              Row(
                children: [
                  numeral,
                  const SizedBox(width: 10),
                  Expanded(child: label),
                ],
              ),
              const SizedBox(height: 7),
              caption,
              const SizedBox(height: 12),
              rule,
            ],
          );
        }
        return Row(
          children: [
            numeral,
            const SizedBox(width: 10),
            label,
            const SizedBox(width: 14),
            const Expanded(child: rule),
            const SizedBox(width: 14),
            Flexible(child: caption),
          ],
        );
      },
    );
  }
}

/// Four cards per group, and the column count steps 4 → 2 → 1 so a group
/// never breaks into a ragged 3 + 1.
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features, required this.onOpen});

  final List<LandingFeature> features;
  final void Function(LandingFeatureTarget target)? onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return LandingAutoGrid(
          minItemWidth: 200,
          spacing: 13,
          maxColumns: width >= 1000
              ? 4
              : width >= 620
              ? 2
              : 1,
          children: [
            for (final feature in features)
              _FeatureCard(
                feature: feature,
                onTap: onOpen == null ? null : () => onOpen!(feature.target),
              ),
          ],
        );
      },
    );
  }
}

/// One feature card: icon, title, body, its two capabilities, and the band it
/// points at.
///
/// It carries its own hover state rather than sitting in a [LandingHoverCard]
/// because the hover has to reach the footer arrow as well as the border —
/// a card that lifts but whose "go here" affordance stays inert reads as
/// decoration rather than as a link.
class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.feature, required this.onTap});

  final LandingFeature feature;
  final VoidCallback? onTap;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;
  bool _focused = false;

  bool get _active => _hovered || _focused;

  @override
  Widget build(BuildContext context) {
    final feature = widget.feature;
    // The page is RTL, but the nudge is a physical offset: read the direction
    // rather than assuming, so the arrow always slides the way it points.
    final forward = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _active ? -3 : 0, 0),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: LandingPalette.surface,
        borderRadius: LandingRadii.cardR,
        border: Border.all(
          color: _active ? LandingPalette.brandLine : LandingPalette.border,
        ),
        boxShadow: _active
            ? const [
                BoxShadow(
                  color: Color(0x6B0B1B34),
                  offset: Offset(0, 22),
                  blurRadius: 40,
                  spreadRadius: -26,
                ),
              ]
            : LandingPalette.cardShadow,
      ),
      // `spaceBetween` over two blocks, not a `Spacer`: the equal-height row
      // measures every cell once with the height unbounded, and an `Expanded`
      // in an unbounded column throws on that pass.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              LandingIconSquare(icon: feature.icon, size: 40, iconSize: 20),
              const SizedBox(height: 14),
              Text(feature.title, style: LandingType.cardTitle(16)),
              const SizedBox(height: 7),
              Text(
                feature.body,
                style: LandingType.cardBody(13).copyWith(height: 1.75),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final capability in feature.capabilities)
                    _CapabilityChip(label: capability),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 1,
                  child: ColoredBox(color: LandingPalette.borderSoft),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        feature.targetLabel,
                        style: LandingType.label(
                          12,
                          color: _active
                              ? LandingPalette.brandInk
                              : LandingPalette.muted,
                          weight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      offset: Offset(_active ? 0.28 * forward : 0, 0),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 15,
                        color: _active
                            ? LandingPalette.brandInk
                            : LandingPalette.faint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.onTap == null) return card;

    return Semantics(
      button: true,
      label: '${feature.title} — ${feature.targetLabel}',
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap!();
              return null;
            },
          ),
        },
        child: GestureDetector(onTap: widget.onTap, child: card),
      ),
    );
  }
}

/// A capability: one short fact the module actually does, in a quiet pill so
/// the card's own body keeps the voice.
class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: LandingPalette.raised,
        borderRadius: LandingRadii.badgeR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: LandingPalette.brand,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          // Flexible, so a long capability wraps inside its pill on a narrow
          // card rather than pushing the row past the card's edge.
          Flexible(
            child: Text(
              label,
              style: LandingType.label(11.5, color: LandingPalette.muted),
            ),
          ),
        ],
      ),
    );
  }
}
