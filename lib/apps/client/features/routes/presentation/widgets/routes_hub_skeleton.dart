import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// Loading placeholder mirroring the Routes tab's real layout: hero, search
/// card, and three "how it works" steps — never a blank or generic spinner.
class RoutesHubSkeleton extends StatelessWidget {
  const RoutesHubSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppLayout.pagePaddingWithTop,
      children: [
        ClientSkeleton(height: 176, borderRadius: ClientRadius.xl),
        const SizedBox(height: ClientSpacing.lg),
        ClientSkeleton(height: 148, borderRadius: ClientRadius.lg),
        const SizedBox(height: ClientSpacing.xl),
        const ClientSkeleton(height: 18, width: 140, borderRadius: 6),
        const SizedBox(height: ClientSpacing.md),
        for (var i = 0; i < 3; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClientSkeleton(height: 28, width: 28, borderRadius: 14),
              const SizedBox(width: ClientSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ClientSkeleton(
                      height: 16,
                      width: 160,
                      borderRadius: 6,
                    ),
                    const SizedBox(height: 6),
                    ClientSkeleton(
                      height: 12,
                      width: 220 - (i * 20),
                      borderRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (i < 2) const SizedBox(height: ClientSpacing.lg),
        ],
      ],
    );
  }
}
