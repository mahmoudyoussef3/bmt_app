import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';

class TripHistorySkeleton extends StatelessWidget {
  const TripHistorySkeleton({super.key});

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
            padding: const EdgeInsets.all(CaptainDesignTokens.s24),
            children: const [
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
        ),
      ],
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
