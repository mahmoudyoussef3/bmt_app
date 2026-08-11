import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';

class DriverProfileSkeleton extends StatelessWidget {
  const DriverProfileSkeleton({super.key});

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
              CaptainDesignTokens.s24,
              CaptainDesignTokens.s20,
              CaptainBottomNav.reservedSpace(context),
            ),
            children: const [
              CaptainSkeleton(
                height: 260,
                width: double.infinity,
                borderRadius: CaptainDesignTokens.br24,
              ),
              SizedBox(height: CaptainDesignTokens.s24),
              CaptainSkeleton(
                height: 180,
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
