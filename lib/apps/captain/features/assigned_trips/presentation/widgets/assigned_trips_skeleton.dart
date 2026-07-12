import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';

class AssignedTripsSkeleton extends StatelessWidget {
  const AssignedTripsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(CaptainDesignTokens.s24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CaptainSkeleton(height: 32, width: 140),
              CaptainSkeleton(
                height: 40,
                width: 40,
                borderRadius: CaptainDesignTokens.br32,
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s24),
          const CaptainSkeleton(height: 18, width: double.infinity),
          const SizedBox(height: CaptainDesignTokens.s12),
          const CaptainSkeleton(height: 16, width: double.infinity),
          const SizedBox(height: CaptainDesignTokens.s16),
          Row(
            children: [
              const Expanded(
                child: CaptainSkeleton(height: 36, width: double.infinity),
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              const Expanded(
                child: CaptainSkeleton(height: 36, width: double.infinity),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s32),
          const CaptainSkeleton(height: 24, width: 120),
          const SizedBox(height: CaptainDesignTokens.s16),
          for (var i = 0; i < 3; i++) ...[
            CaptainSkeleton(
              height: 220,
              borderRadius: CaptainDesignTokens.br24,
              width: double.infinity,
            ),
            const SizedBox(height: CaptainDesignTokens.s24),
          ],
        ],
      ),
    );
  }
}
