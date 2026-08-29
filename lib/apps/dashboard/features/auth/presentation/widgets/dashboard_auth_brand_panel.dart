import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

/// The EWT product name, kept in one place so the tall panel and the compact
/// band can never drift apart.
const String _brandName = 'EWT';
const String _brandFullName = 'Easy Way Transportation';

/// The brand half of the sign-in screen: a full-bleed sweep of the console's
/// own [DashboardColors.heroGradient] carrying the EWT lockup, the promise of
/// the product, and the three things the console actually does.
///
/// This is the one place in the dashboard that paints a brand-coloured field.
/// Everywhere past the login gate the console is deliberately quiet — warm
/// paper, borders instead of lift, blue spent only on a primary action — and
/// that restraint only reads as a choice if the operator has seen the brand
/// stated once, on the way in.
class DashboardAuthBrandPanel extends StatelessWidget {
  const DashboardAuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = DashboardColors.onHero(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: DashboardColors.heroGradient(context),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _Bloom(top: -110, end: -90, size: 320, opacity: 0.10),
          const _Bloom(bottom: -140, start: -110, size: 380, opacity: 0.07),
          PositionedDirectional(
            top: 48,
            start: 48,
            end: 48,
            child: DashboardBrandLockup(ink: ink, markSize: 60),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(48, 140, 48, 88),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لوحة تحكم مكتب النقل',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: AppTokens.spaceMd),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Text(
                          'أدر الرحلات والحجوزات والأسطول والمالية من مكان واحد، '
                          'وتابع أداء مكتبك لحظة بلحظة.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: ink.withValues(alpha: 0.82),
                                height: 1.7,
                              ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _BrandPoint(
                        icon: DashboardIcons.trips,
                        title: 'الرحلات والحجوزات',
                        detail: 'جدولة يومية ومتابعة المقاعد أولاً بأول',
                        ink: ink,
                      ),
                      const SizedBox(height: AppTokens.spaceLg),
                      _BrandPoint(
                        icon: DashboardIcons.fleet,
                        title: 'الأسطول والسائقون',
                        detail: 'مركبات وسائقون ورخص ومستندات في سجل واحد',
                        ink: ink,
                      ),
                      const SizedBox(height: AppTokens.spaceLg),
                      _BrandPoint(
                        icon: DashboardIcons.financial,
                        title: 'المالية والتقارير',
                        detail: 'إيرادات ومحفظة العملاء وتقارير جاهزة للتصدير',
                        ink: ink,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 48,
            end: 48,
            bottom: 32,
            child: Text(
              // An all-Latin line inside an RTL subtree: left to the ambient
              // direction the copyright sign and the year get pushed to the far
              // end and it renders as "…Transportation 2026 ©". The isolate
              // lets the run's own first strong character settle it instead.
              isolatedPlaceName('© 2026 $_brandName — $_brandFullName'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ink.withValues(alpha: 0.62),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The narrow-viewport form of [DashboardAuthBrandPanel]: the same gradient and
/// the same lockup, laid out horizontally in a band above the form.
///
/// The three product points are dropped rather than stacked — on a phone the
/// operator is signing in, not being sold to, and a band tall enough to hold
/// them would push the password field off screen.
class DashboardAuthBrandBand extends StatelessWidget {
  const DashboardAuthBrandBand({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = DashboardColors.onHero(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: DashboardColors.heroGradient(context),
      ),
      child: Stack(
        children: [
          const _Bloom(top: -90, end: -70, size: 220, opacity: 0.10),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DashboardBrandLockup(ink: ink, markSize: 48),
                  const SizedBox(height: AppTokens.spaceLg),
                  Text(
                    'لوحة تحكم مكتب النقل',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The EWT mark beside the EWT name — the lockup, never one half alone.
///
/// The mark is lit *from* the gradient rather than filled with the brand
/// colour: `brand_glyph.png` is a white-on-transparent silhouette, and a
/// brand-blue plate under it on a brand-blue field would disappear.
class DashboardBrandLockup extends StatelessWidget {
  const DashboardBrandLockup({
    super.key,
    required this.ink,
    this.markSize = 60,
  });

  final Color ink;
  final double markSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ink.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(markSize * 0.3),
            border: Border.all(color: ink.withValues(alpha: 0.24), width: 1.5),
          ),
          child: Padding(
            padding: EdgeInsets.all(markSize * 0.2),
            child: Image.asset(
              'assets/branding/brand_glyph.png',
              fit: BoxFit.contain,
              color: ink,
              errorBuilder: (_, _, _) => Icon(
                DashboardIcons.fleetActive,
                size: markSize * 0.46,
                color: ink,
              ),
            ),
          ),
        ),
        SizedBox(width: markSize * 0.27),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _brandName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ink,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _brandFullName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ink.withValues(alpha: 0.78),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One capability line on the brand panel: a glass icon square, what it is, and
/// what it does. Every one of the three names a module the console really ships
/// — nothing here promises a screen that does not exist.
class _BrandPoint extends StatelessWidget {
  const _BrandPoint({
    required this.icon,
    required this.title,
    required this.detail,
    required this.ink,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ink.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            border: Border.all(color: ink.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, size: 19, color: ink),
        ),
        const SizedBox(width: AppTokens.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ink.withValues(alpha: 0.72),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A soft off-canvas glow that keeps the gradient from reading as a flat
/// rectangle. Positioned directionally so it stays in the same visual corner
/// when the console is mirrored.
class _Bloom extends StatelessWidget {
  const _Bloom({
    this.top,
    this.bottom,
    this.start,
    this.end,
    required this.size,
    required this.opacity,
  });

  final double? top;
  final double? bottom;
  final double? start;
  final double? end;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: top,
      bottom: bottom,
      start: start,
      end: end,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // A radial falloff, not a flat fill: a solid circle at this opacity
          // reads as a disc with a visible edge rather than as light.
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: opacity),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
