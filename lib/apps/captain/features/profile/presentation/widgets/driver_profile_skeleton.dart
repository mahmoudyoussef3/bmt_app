import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';

/// Mirrors the loaded profile layout: avatar hero, stats, vehicle, rating,
/// and info cards — the same shimmer treatment the home and history screens
/// already use, instead of a bare spinner over an otherwise-blank screen.
class DriverProfileSkeleton extends StatelessWidget {
  const DriverProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 220 + MediaQuery.viewPaddingOf(context).top,
          color: CaptainColors.backgroundFor(context),
          alignment: Alignment.center,
          child: const CaptainSkeleton(
            width: 96,
            height: 96,
            borderRadius: BorderRadius.all(Radius.circular(48)),
          ),
        ),
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
                height: 120,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br16,
              ),
              const SizedBox(height: CaptainDesignTokens.s16),
              CaptainSkeleton(
                height: 90,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br16,
              ),
              const SizedBox(height: CaptainDesignTokens.s16),
              CaptainSkeleton(
                height: 140,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
