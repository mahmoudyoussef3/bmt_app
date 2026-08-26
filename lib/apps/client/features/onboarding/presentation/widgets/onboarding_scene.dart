import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../animations/floating_animation.dart';

/// A small floating product card layered over an onboarding scene
/// (e.g. "Seat A12 · Confirmed", "ETA 12 min").
class OnboardingFloatingCard {
  const OnboardingFloatingCard({
    required this.icon,
    required this.title,
    required this.alignment,
    this.subtitle,
    this.accent,
    this.floatMagnitude = 7,
    this.floatSeconds = 4,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Alignment alignment;
  final Color? accent;
  final double floatMagnitude;
  final int floatSeconds;
}

/// Premium onboarding hero: a tinted, rounded "scene" with a glowing center
/// badge, a decorative backdrop, and floating product mini-cards. Fills the
/// bounded box it is given by the parent.
class OnboardingScene extends StatelessWidget {
  const OnboardingScene({
    super.key,
    required this.accent,
    required this.centerIcon,
    required this.cards,
  });

  final Color accent;
  final IconData centerIcon;
  final List<OnboardingFloatingCard> cards;

  @override
  Widget build(BuildContext context) {
    final surface = ClientColors.surfaceFor(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(accent.withAlpha(28), surface),
          border: Border.all(color: accent.withAlpha(40)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _SceneBackdropPainter(accent)),
            ),
            Center(
              child: _CenterBadge(accent: accent, icon: centerIcon),
            ),
            for (final card in cards)
              Align(
                alignment: card.alignment,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: FloatingAnimation(
                    magnitude: card.floatMagnitude,
                    duration: Duration(seconds: card.floatSeconds),
                    child: _MiniCard(card: card, sceneAccent: accent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CenterBadge extends StatelessWidget {
  const _CenterBadge({required this.accent, required this.icon});

  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      width: 124,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withAlpha(26),
        border: Border.all(color: accent.withAlpha(60), width: 1.5),
      ),
      child: Center(
        child: Container(
          height: 90,
          width: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent,
            boxShadow: [
              BoxShadow(
                color: accent.withAlpha(90),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Icon(icon, size: 44, color: Colors.white),
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.card, required this.sceneAccent});

  final OnboardingFloatingCard card;
  final Color sceneAccent;

  @override
  Widget build(BuildContext context) {
    final accent = card.accent ?? sceneAccent;
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: accent.withAlpha(28),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(card.icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelMedium(context).copyWith(
                    color: ClientColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (card.subtitle != null)
                  Text(
                    card.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.labelSmall(context).copyWith(
                      color: ClientColors.textTertiaryFor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneBackdropPainter extends CustomPainter {
  const _SceneBackdropPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final maxR = size.shortestSide * 0.5;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = accent.withAlpha(34);
    for (final factor in [1.0, 0.74, 0.5]) {
      canvas.drawCircle(center, maxR * factor, ring);
    }

    final dot = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withAlpha(46);
    const dots = [
      Offset(0.16, 0.2),
      Offset(0.86, 0.26),
      Offset(0.24, 0.82),
      Offset(0.8, 0.8),
    ];
    for (final d in dots) {
      canvas.drawCircle(Offset(size.width * d.dx, size.height * d.dy), 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _SceneBackdropPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
