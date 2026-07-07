import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// The routes discovery/results empty state — explains why nothing is
/// showing and offers a next action, never a blank list (spec FR-012).
class RouteResultsEmptyState extends StatelessWidget {
  const RouteResultsEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ClientColors.primaryFor(context).withAlpha(20),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.route_outlined,
                color: ClientColors.primaryFor(context),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: ClientTypography.headingMedium(context),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: ClientTypography.bodyMedium(context).copyWith(
                color: ClientColors.textSecondaryFor(context),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            ClientButton(
              label: actionLabel,
              onPressed: onAction,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}
