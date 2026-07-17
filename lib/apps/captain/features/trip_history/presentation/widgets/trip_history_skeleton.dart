import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';

/// The history tab's first-load placeholder.
class TripHistorySkeleton extends StatelessWidget {
  const TripHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(CaptainDesignTokens.s24),
        children: const [
          CaptainSkeleton(height: 28, width: 140),
          SizedBox(height: CaptainDesignTokens.s16),
          // The summary strip, then the filter bar, then the cards — the tab
          // settles into this order, so the placeholder holds it rather than
          // letting the whole page jump when the trips land.
          CaptainSkeleton(height: 92, width: double.infinity),
          SizedBox(height: CaptainDesignTokens.s16),
          CaptainSkeleton(height: 44, width: double.infinity),
          SizedBox(height: CaptainDesignTokens.s12),
          CaptainSkeleton(height: 34, width: double.infinity),
          SizedBox(height: CaptainDesignTokens.s24),
          _CardPlaceholder(),
          _CardPlaceholder(),
          _CardPlaceholder(),
        ],
      ),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.only(bottom: CaptainDesignTokens.s16),
      child: CaptainSkeleton(
        height: 172,
        width: double.infinity,
        borderRadius: CaptainDesignTokens.br24,
      ),
    );
  }
}
