import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// Loading placeholder mirroring the discovery header + result-card grid,
/// so the results screen never shows a blank or generic spinner.
class RouteResultsSkeleton extends StatelessWidget {
  const RouteResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const ClientSkeleton(height: 30, width: 220),
        const SizedBox(height: 10),
        const ClientSkeleton(height: 18, width: 280),
        const SizedBox(height: ClientSpacing.md),
        Row(
          children: [
            const Expanded(child: ClientSkeleton(height: 54, borderRadius: 12)),
            const SizedBox(width: ClientSpacing.sm),
            ClientSkeleton(
              height: 54,
              width: 96,
              borderRadius: ClientRadius.md,
            ),
          ],
        ),
        const SizedBox(height: ClientSpacing.lg),
        for (var i = 0; i < 3; i++) ...[
          ClientSkeleton(height: 292, borderRadius: ClientRadius.lg),
          if (i < 2) const SizedBox(height: ClientSpacing.md),
        ],
      ],
    );
  }
}
