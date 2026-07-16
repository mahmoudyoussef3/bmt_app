import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';

import 'driver_profile_metrics.dart';

/// Mirrors the loaded profile layout: identity header, then verification,
/// vehicle and info cards — the same shimmer treatment the home and history
/// screens already use, instead of a bare spinner over an otherwise-blank
/// screen.
///
/// The header's gradient and title are chrome, not data, so they paint at full
/// fidelity straight away and only the captain's own details shimmer. That
/// keeps the load→loaded transition to a cross-fade of the details rather than
/// a jump from a grey block to a coloured one.
class DriverProfileSkeleton extends StatelessWidget {
  const DriverProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderSkeleton(),
        Expanded(
          child: ListView(
            padding: EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s24,
              CaptainDesignTokens.s24,
              CaptainDesignTokens.s24,
              CaptainBottomNav.reservedSpace(context),
            ),
            children: [
              CaptainSkeleton(
                height: 180,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br24,
              ),
              const SizedBox(height: CaptainDesignTokens.s16),
              CaptainSkeleton(
                height: 200,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br24,
              ),
              const SizedBox(height: CaptainDesignTokens.s16),
              CaptainSkeleton(
                height: 120,
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

class _HeaderSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: DriverProfileMetrics.headerHeight,
      decoration: BoxDecoration(
        gradient: CaptainColors.primaryGradient(context),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: kToolbarHeight,
              child: Center(
                child: Text(
                  'ملفي',
                  style: CaptainTypography.titleMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: CaptainColors.onPrimary,
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Tinted to sit on the gradient — the shared shimmer is tuned for
            // the app's neutral surfaces and disappears against the brand.
            const _OnGradientSkeleton(width: 76, height: 76, radius: 38),
            const SizedBox(height: CaptainDesignTokens.s12),
            const _OnGradientSkeleton(width: 140, height: 18, radius: 9),
            const SizedBox(height: CaptainDesignTokens.s8),
            const _OnGradientSkeleton(width: 96, height: 24, radius: 12),
            const SizedBox(height: CaptainDesignTokens.s20),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: CaptainDesignTokens.s24,
              ),
              child: _OnGradientSkeleton(
                width: double.infinity,
                height: 64,
                radius: 16,
              ),
            ),
            const SizedBox(height: CaptainDesignTokens.s16),
          ],
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
