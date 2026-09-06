import 'package:flutter/material.dart';

import '../theme/landing_theme.dart';
import 'landing_layout.dart';
import 'landing_motion.dart';

/// The tint + line + solid-text status pill used by every table, list and
/// filter row on the page. One badge, five tones — the design's `B` map.
class LandingBadge extends StatelessWidget {
  const LandingBadge({
    super.key,
    required this.label,
    required this.tone,
    this.dense = false,
  });

  final String label;
  final LandingTone tone;

  /// The smaller variant used inside the phone mockups.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: LandingRadii.badgeR,
        border: Border.all(color: tone.line),
      ),
      child: Text(
        label,
        style: LandingType.badge(
          color: tone.foreground,
        ).copyWith(fontSize: dense ? 10 : 10.5),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// A plain surface card: white, hairline border, contact shadow.
class LandingCard extends StatelessWidget {
  const LandingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.background = LandingPalette.surface,
    this.borderColor = LandingPalette.border,
    this.radius = LandingRadii.card,
    this.shadow = LandingPalette.cardShadow,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color background;
  final Color borderColor;
  final double radius;
  final List<BoxShadow> shadow;

  /// Set for cards whose children paint to the edge (tables, list panels).
  final bool clip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}

/// A [LandingCard] that responds to a mouse — the design's `style-hover`
/// rules, which are either a border tint or a small lift.
class LandingHoverCard extends StatefulWidget {
  const LandingHoverCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.lift = false,
    this.background = LandingPalette.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// True for the operations grid, whose cards translate up 3px and deepen
  /// their shadow; false for cards that only warm their border.
  final bool lift;
  final Color background;

  @override
  State<LandingHoverCard> createState() => _LandingHoverCardState();
}

class _LandingHoverCardState extends State<LandingHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          widget.lift && _hovered ? -3 : 0,
          0,
        ),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.background,
          borderRadius: LandingRadii.cardR,
          border: Border.all(
            color: _hovered ? LandingPalette.brandLine : LandingPalette.border,
          ),
          boxShadow: widget.lift && _hovered
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
        child: widget.child,
      ),
    );
  }
}

/// The rounded square that holds a feature icon — brand tint, brand line.
class LandingIconSquare extends StatelessWidget {
  const LandingIconSquare({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 22,
    this.background = LandingPalette.brandTint,
    this.borderColor = LandingPalette.brandLine,
    this.iconColor = LandingPalette.brandInk,
    this.radius = 12,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color background;
  final Color borderColor;
  final Color iconColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }
}

/// Eyebrow → headline → lead paragraph, the opening of every section.
///
/// [headlineMin] / [headlineMax] are the CSS clamp bounds, which differ per
/// section (40px for the page's main sections, 34–38px for the split bands).
class LandingSectionIntro extends StatelessWidget {
  const LandingSectionIntro({
    super.key,
    this.eyebrow,
    this.eyebrowColor = LandingPalette.brandInk,
    required this.headline,
    this.lead,
    this.maxWidth = 640,
    this.align = TextAlign.start,
    this.headlineMin = 25,
    this.headlineVw = 3.2,
    this.headlineMax = 40,
    this.onDark = false,
    this.center = false,
  });

  final String? eyebrow;
  final Color eyebrowColor;
  final String headline;
  final String? lead;
  final double maxWidth;
  final TextAlign align;
  final double headlineMin;
  final double headlineVw;
  final double headlineMax;

  /// Recolours the ramp for the navy bands, where the headline is white and
  /// the lead drops to 72% white.
  final bool onDark;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final size = landingClamp(
      context,
      min: headlineMin,
      vw: headlineVw,
      max: headlineMax,
    );
    final column = Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            textAlign: align,
            style: LandingType.eyebrow(color: eyebrowColor),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          headline,
          textAlign: align,
          style: LandingType.heading(
            size,
            color: onDark ? Colors.white : LandingPalette.ink,
          ),
        ),
        if (lead != null) ...[
          const SizedBox(height: 16),
          Text(
            lead!,
            textAlign: align,
            style: LandingType.lead(
              16,
              color: onDark
                  ? Colors.white.withValues(alpha: 0.72)
                  : LandingPalette.muted,
            ),
          ),
        ],
      ],
    );

    final constrained = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: column,
    );
    return center
        ? Center(child: constrained)
        : Align(
            alignment: AlignmentDirectional.centerStart,
            child: constrained,
          );
  }
}

/// The page's CTA buttons. Four shapes, all 54px tall on the marketing scale
/// (42px in the header), differing only in ground and border.
enum LandingButtonStyle {
  /// Brand fill, white label — the page's one primary action.
  primary,

  /// White fill, strong border — the hero's "watch how it works".
  secondary,

  /// Navy fill, white label — used inside light bands that already carry
  /// brand tint, where another blue button would be a second primary.
  navy,

  /// White fill on a navy band.
  onDark,

  /// Transparent with a white border, on a navy band.
  onDarkOutline,
}

class LandingButton extends StatefulWidget {
  const LandingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = LandingButtonStyle.primary,
    this.icon,
    this.leadingIcon,
    this.leadingIconColor,
    this.height = 54,
    this.expand = false,
  });

  final String label;
  final VoidCallback onPressed;
  final LandingButtonStyle style;

  /// Drawn after the label — in RTL that is the leftmost edge, which is where
  /// the design puts its forward arrows.
  final IconData? icon;

  /// Drawn before the label, for the buttons the design opens with a glyph.
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final double height;

  /// Fills the available width — used where the design gives the button a
  /// `flex: 1 1 200px` in a wrapping row.
  final bool expand;

  @override
  State<LandingButton> createState() => _LandingButtonState();
}

class _LandingButtonState extends State<LandingButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color? line) = switch (widget.style) {
      LandingButtonStyle.primary => (
        _hovered ? LandingPalette.brandInk : LandingPalette.brand,
        Colors.white,
        null,
      ),
      LandingButtonStyle.secondary => (
        _hovered ? LandingPalette.raised : LandingPalette.surface,
        LandingPalette.ink,
        LandingPalette.borderStrong,
      ),
      LandingButtonStyle.navy => (LandingPalette.navy, Colors.white, null),
      LandingButtonStyle.onDark => (
        _hovered ? const Color(0xFFE9EEF7) : Colors.white,
        LandingPalette.navy,
        null,
      ),
      LandingButtonStyle.onDarkOutline => (
        _hovered ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
        Colors.white,
        Colors.white.withValues(alpha: 0.35),
      ),
    };

    final child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(
            widget.leadingIcon,
            size: widget.height >= 52 ? 20 : 18,
            color: widget.leadingIconColor ?? fg,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LandingType.label(
              widget.height >= 52 ? 15.5 : 13.5,
              color: fg,
              weight: FontWeight.w800,
            ),
          ),
        ),
        if (widget.icon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.icon, size: widget.height >= 52 ? 20 : 18, color: fg),
        ],
      ],
    );

    // The ring is a shadow rather than a wider border: a border is laid out
    // inside the box, so growing it on focus would nudge the label by a pixel
    // in a header row that is already the page's tightest.
    final ring = switch (widget.style) {
      LandingButtonStyle.onDark ||
      LandingButtonStyle.onDarkOutline => Colors.white,
      _ => LandingPalette.brandInk,
    };

    return Semantics(
      button: true,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            // The whole button gives under the finger rather than only
            // changing colour — on a page whose actions are all anchors, this
            // is the only acknowledgement the reader gets before the scroll
            // starts.
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: widget.height,
              padding: EdgeInsets.symmetric(
                horizontal: widget.height >= 52 ? 26 : 18,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: LandingRadii.buttonR,
                border: line == null ? null : Border.all(color: line),
                boxShadow: [
                  if (widget.style == LandingButtonStyle.primary)
                    BoxShadow(
                      color: LandingPalette.brand.withValues(alpha: 0.55),
                      offset: const Offset(0, 14),
                      blurRadius: 30,
                      spreadRadius: -14,
                    ),
                  if (_focused)
                    BoxShadow(
                      color: ring.withValues(alpha: 0.55),
                      spreadRadius: 3,
                    ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The 7px meter used for line occupancy, payment mix and top-booked routes.
class LandingMeter extends StatelessWidget {
  const LandingMeter({
    super.key,
    required this.fraction,
    this.color = LandingPalette.brand,
    this.height = 7,
  });

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: height,
        color: LandingPalette.well,
        // The bar grows out of its well as the panel holding it arrives — a
        // meter that is already full when the reader gets to it says nothing
        // about being a measurement.
        child: LandingRevealBuilder(
          builder: (context, t) => FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: fraction.clamp(0.0, 1.0) * t,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Label, value and meter — the repeated "name · percentage · bar" row.
class LandingMeterRow extends StatelessWidget {
  const LandingMeterRow({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    this.color = LandingPalette.brand,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                label,
                style: LandingType.label(12.5, color: LandingPalette.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: LandingType.label(
                12,
                color: LandingPalette.ink,
                weight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LandingMeter(fraction: fraction, color: color),
      ],
    );
  }
}

/// The fully-rounded chip the page uses for range switches, table filters and
/// the dashboard console's tab rail.
///
/// Three grounds, in the order the design reaches for them: a brand fill for
/// the current choice, a status tint for a filter that names a status, and a
/// bordered surface for everything else.
class LandingPill extends StatefulWidget {
  const LandingPill({
    super.key,
    required this.label,
    this.selected = false,
    this.tone,
    this.onTap,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    this.unselectedBackground,
  });

  final String label;
  final bool selected;
  final LandingTone? tone;
  final VoidCallback? onTap;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final Color? unselectedBackground;

  @override
  State<LandingPill> createState() => _LandingPillState();
}

class _LandingPillState extends State<LandingPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone;
    final (Color background, Color foreground, Color? line) = switch (tone) {
      final LandingTone t => (t.background, t.foreground, t.line),
      null when widget.selected => (LandingPalette.brand, Colors.white, null),
      null => (
        _hovered
            ? LandingPalette.raised
            : widget.unselectedBackground ?? Colors.transparent,
        LandingPalette.muted,
        LandingPalette.border,
      ),
    };

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: line == null ? null : Border.all(color: line),
      ),
      child: Text(
        widget.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: LandingType.label(
          widget.fontSize,
          color: foreground,
          weight: widget.selected || tone != null
              ? FontWeight.w800
              : FontWeight.w700,
        ),
      ),
    );

    if (widget.onTap == null) return chip;
    return Semantics(
      button: true,
      selected: widget.selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(onTap: widget.onTap, child: chip),
      ),
    );
  }
}
