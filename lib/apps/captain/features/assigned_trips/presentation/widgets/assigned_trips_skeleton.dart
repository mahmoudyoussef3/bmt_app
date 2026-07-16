import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';

/// Mirrors the loaded home layout: header, focus card, stats strip, trip list.
class AssignedTripsSkeleton extends StatelessWidget {
  const AssignedTripsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 156 + MediaQuery.viewPaddingOf(context).top,
          color: CaptainColors.primary,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s20,
              CaptainDesignTokens.s20,
              CaptainDesignTokens.s20,
              CaptainBottomNav.reservedSpace(context),
            ),
            children: [
              const CaptainSkeleton(
                height: 190,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br24,
              ),
              const SizedBox(height: CaptainDesignTokens.s16),
              const CaptainSkeleton(
                height: 110,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br16,
              ),
              const SizedBox(height: CaptainDesignTokens.s24),
              const CaptainSkeleton(height: 20, width: 140),
              const SizedBox(height: CaptainDesignTokens.s12),
              for (var i = 0; i < 3; i++) ...[
                const CaptainSkeleton(
                  height: 170,
                  width: double.infinity,
                  borderRadius: CaptainDesignTokens.br24,
                ),
                const SizedBox(height: CaptainDesignTokens.s12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
