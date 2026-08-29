import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';

/// The loaded page in grey: a header line, the identity block, the stats
/// strip, then a labelled group per section.
///
/// It used to open with a 156px block of solid brand blue — the gradient app
/// bar this app dropped in the 2026-08-25 pass. Nothing on the loaded screen
/// paints that any more, so the load was flashing a band that then vanished.
class DriverProfileSkeleton extends StatelessWidget {
  const DriverProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s20,
              CaptainDesignTokens.s20,
              CaptainDesignTokens.s20,
              CaptainDesignTokens.s16,
            ),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CaptainSkeleton(height: 18, width: 84),
                    SizedBox(height: CaptainDesignTokens.s8),
                    CaptainSkeleton(height: 12, width: 130),
                  ],
                ),
                const Spacer(),
                const CaptainSkeleton(
                  height: 44,
                  width: 44,
                  borderRadius: CaptainDesignTokens.br14,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s20,
              0,
              CaptainDesignTokens.s20,
              CaptainBottomNav.reservedSpace(context),
            ),
            children: [
              const CaptainSkeleton(
                height: 96,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br20,
              ),
              const SizedBox(height: CaptainDesignTokens.s12),
              const Row(
                children: [
                  _StatTile(),
                  SizedBox(width: 10),
                  _StatTile(),
                  SizedBox(width: 10),
                  _StatTile(),
                ],
              ),
              const SizedBox(height: CaptainDesignTokens.s24),
              const _Group(height: 224),
              const SizedBox(height: CaptainDesignTokens.s24),
              const _Group(height: 150),
              const SizedBox(height: CaptainDesignTokens.s24),
              const _Group(height: 150),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile();

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: CaptainSkeleton(
        height: 70,
        width: double.infinity,
        borderRadius: CaptainDesignTokens.br16,
      ),
    );
  }
}

/// A section label outside its group, the shape every block below the strip
/// takes once the profile arrives.
class _Group extends StatelessWidget {
  const _Group({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            CaptainDesignTokens.s4,
            0,
            CaptainDesignTokens.s4,
            CaptainDesignTokens.s12,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: CaptainSkeleton(height: 12, width: 96),
          ),
        ),
        CaptainSkeleton(
          height: height,
          width: double.infinity,
          borderRadius: CaptainDesignTokens.br16,
        ),
      ],
    );
  }
}
