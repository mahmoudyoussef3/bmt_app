import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';

import 'driver_profile_metrics.dart';

/// Mirrors the loaded profile layout: identity header, then stats,
/// verification, vehicle and info cards — the same shimmer treatment the home
/// and history screens already use, instead of a bare spinner over an
/// otherwise-blank screen.
///
/// The header's gradient is chrome, not data, so it paints at full fidelity
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
        const _HeaderSkeleton(),
        Expanded(
          child: ListView(
            padding: EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s24,
              CaptainDesignTokens.s24,
              CaptainDesignTokens.s24,
              CaptainBottomNav.reservedSpace(context),
            ),
            children: const [
              CaptainSkeleton(
                height: 120,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br24,
              ),
              SizedBox(height: CaptainDesignTokens.s16),
              CaptainSkeleton(
                height: 180,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br24,
              ),
              SizedBox(height: CaptainDesignTokens.s16),
              CaptainSkeleton(
                height: 200,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br24,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mirrors `DriverProfileHeader`'s identity row: avatar leading, name beside
/// it, standing trailing — at the same toolbar height, so the load→loaded
/// transition is a cross-fade rather than a jump.
class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: CaptainColors.primaryGradient(context),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: DriverProfileMetrics.toolbarHeight(context),
          child: const Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: CaptainDesignTokens.s24,
            ),
            child: Row(
              children: [
                // Tinted to sit on the gradient — the shared shimmer is tuned
                // for the app's neutral surfaces and disappears against the
                // brand.
                _OnGradientSkeleton(
                  width: DriverProfileMetrics.avatarSize,
                  height: DriverProfileMetrics.avatarSize,
                  radius: DriverProfileMetrics.avatarSize / 2,
                ),
                SizedBox(width: CaptainDesignTokens.s12),
                Expanded(
                  child: _OnGradientSkeleton(width: 150, height: 18, radius: 9),
                ),
                SizedBox(width: CaptainDesignTokens.s8),
                _OnGradientSkeleton(width: 96, height: 26, radius: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnGradientSkeleton extends StatelessWidget {
  const _OnGradientSkeleton({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
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
