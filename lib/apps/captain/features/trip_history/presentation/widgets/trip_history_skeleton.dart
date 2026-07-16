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
          SizedBox(height: CaptainDesignTokens.s24),
          _CardPlaceholder(),
          _CardPlaceholder(),
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
      padding: EdgeInsetsDirectional.only(bottom: CaptainDesignTokens.s8),
      child: CaptainSkeleton(height: 120, width: double.infinity),
    );
  }
}
