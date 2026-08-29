import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// The brand block an auth screen opens with, drawn on the header band that
/// [CaptainAuthScaffold] paints behind it.
///
/// The rest of the captain app is deliberately flat chrome on a quiet canvas —
/// but the sign-in screen is the one surface that has to say *whose* app this
/// is before it asks for anything, and it is the only screen a captain sees
/// while deciding whether they are even in the right place. It matches the
/// rider app's auth hero for the same reason: one company, one front door.
class CaptainAuthHero extends StatelessWidget {
  const CaptainAuthHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.badge,
  });

  final String title;
  final String subtitle;

  /// Replaces the brand glyph. The join flow uses one so the two screens are
  /// distinguishable at a glance rather than by their headings alone.
  final IconData? icon;

  /// A small pill above the title — the app's own name, not a status.
  final String? badge;

  /// A 568pt-tall phone is still a supported device, and on one the full-size
  /// hero pushes the sign-in button below the fold — the captain has to scroll
  /// to reach the only control on the screen. Below this height the block gives
  /// up its badge and a third of its mark rather than the form's headroom.
  static bool compactFor(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 700;

  @override
  Widget build(BuildContext context) {
    final ink = ClientColors.onHeroFor(context);
    final compact = compactFor(context);

    return Column(
      children: [
        _GlassMark(icon: icon, ink: ink, size: compact ? 60 : 76),
        SizedBox(
          height: compact ? CaptainDesignTokens.s12 : CaptainDesignTokens.s20,
        ),
        if (!compact && badge != null) ...[
          _HeroBadge(text: badge!, ink: ink),
          const SizedBox(height: CaptainDesignTokens.s12),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style:
              (compact
                      ? CaptainTypography.titleLarge(context)
                      : CaptainTypography.headlineMedium(context))
                  .copyWith(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
        ),
        const SizedBox(height: CaptainDesignTokens.s8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: CaptainTypography.bodySmall(
            context,
          ).copyWith(color: ink.withValues(alpha: 0.82), height: 1.55),
        ),
      ],
    );
  }
}

/// The app mark, lit from the band rather than filled with the brand colour —
/// [CaptainBrandMark]'s gradient is the same blue the band is painted in, so on
/// this surface it would be invisible.
class _GlassMark extends StatelessWidget {
  const _GlassMark({required this.icon, required this.ink, required this.size});

  final IconData? icon;
  final Color ink;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.31),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
          width: 1.5,
        ),
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.46, color: ink)
          : Padding(
              padding: EdgeInsets.all(size * 0.2),
              child: Image.asset(
                'assets/branding/brand_glyph.png',
                fit: BoxFit.contain,
                color: ink,
                errorBuilder: (_, _, _) => Icon(
                  Icons.directions_bus_rounded,
                  size: size * 0.46,
                  color: ink,
                ),
              ),
            ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.text, required this.ink});

  final String text;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s12,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: CaptainDesignTokens.brPill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: CaptainTypography.labelSmall(
          context,
        ).copyWith(color: ink, fontWeight: FontWeight.w800, letterSpacing: 0.4),
      ),
    );
  }
}
