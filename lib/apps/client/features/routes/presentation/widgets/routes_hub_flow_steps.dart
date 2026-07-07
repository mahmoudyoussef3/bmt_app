import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/routes_hub_data.dart';

/// The "How it works" numbered timeline on the Routes tab.
class RoutesHubFlowSteps extends StatelessWidget {
  const RoutesHubFlowSteps({super.key, required this.steps});

  final List<RoutesHubFlowStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final step in steps)
          _FlowStep(
            step: step.step,
            title: step.title,
            subtitle: step.subtitle,
            isLast: step.step == steps.length,
          ),
      ],
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.step,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final int step;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: ClientColors.primaryFor(context),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: ClientTypography.labelMedium(context).copyWith(
                      color: ClientColors.textInverse,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: ClientColors.borderFor(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: ClientSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ClientTypography.headingSmall(
                      context,
                    ).copyWith(color: ClientColors.textPrimaryFor(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
