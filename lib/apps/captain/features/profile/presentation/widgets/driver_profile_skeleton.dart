import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';

import 'driver_profile_metrics.dart';

/// Mirrors the loaded profile layout: the identity hero, then the vehicle,
/// verification, account and settings groups — the same shimmer treatment the
/// home and history screens already use, instead of a bare spinner over an
/// otherwise-blank screen.
///
/// The hero's gradient is chrome, not data, so it paints at full fidelity
/// straight away and only the captain's own details shimmer. That keeps the
/// load→loaded transition to a cross-fade of the details rather than a jump
/// from a grey block to a coloured one.
class DriverProfileSkeleton extends StatelessWidget {
  const DriverProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeroSkeleton(),
        Expanded(
          child: ListView(
            padding: EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s20,
              CaptainDesignTokens.s24,
              CaptainDesignTokens.s20,
              CaptainBottomNav.reservedSpace(context),
            ),
            children: const [
              CaptainSkeleton(
                height: 180,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br20,
              ),
              SizedBox(height: CaptainDesignTokens.s24),
              CaptainSkeleton(
                height: 200,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br20,
              ),
              SizedBox(height: CaptainDesignTokens.s24),
              CaptainSkeleton(
                height: 160,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mirrors `DriverProfileHeader`: portrait, name, standing, then the two
/// lifetime-total tiles — at the same sizes and paddings, so the load→loaded
/// transition is a cross-fade rather than a jump.
class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: CaptainColors.primaryGradient(context),
        borderRadius: DriverProfileMetrics.heroRadius,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: DriverProfileMetrics.heroPadding,
          child: Column(
            children: const [
              // Tinted to sit on the gradient — the shared shimmer is tuned for
              // the app's neutral surfaces and disappears against the brand.
              _OnGradient(
                width: DriverProfileMetrics.avatarSize,
                height: DriverProfileMetrics.avatarSize,
                radius: DriverProfileMetrics.avatarSize / 2,
              ),
              SizedBox(height: CaptainDesignTokens.s16),
              _OnGradient(width: 190, height: 24, radius: 12),
              SizedBox(height: CaptainDesignTokens.s12),
              _OnGradient(width: 130, height: 26, radius: 13),
              SizedBox(height: CaptainDesignTokens.s24),
              Row(
                children: [
                  Expanded(
                    child: _OnGradient(
                      height: DriverProfileMetrics.statTileHeight,
                      radius: 20,
                    ),
                  ),
                  SizedBox(width: CaptainDesignTokens.s12),
                  Expanded(
                    child: _OnGradient(
                      height: DriverProfileMetrics.statTileHeight,
                      radius: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnGradient extends StatelessWidget {
  const _OnGradient({this.width, required this.height, required this.radius});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
