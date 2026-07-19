import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Skeleton shown while the map pins load.
class MapLoadingState extends StatelessWidget {
  const MapLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: ClientColors.surfaceMutedFor(context)),
        ),
        const PositionedDirectional(
          start: 16,
          end: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: ClientSkeleton(
              height: 258,
              borderRadius: ClientRadius.sheet,
            ),
          ),
        ),
      ],
    );
  }
}

/// Error state shown when the map pins fail to load.
class MapErrorState extends StatelessWidget {
  const MapErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 52,
              color: ClientColors.textTertiaryFor(context),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.booking_mapCouldNotBeLoaded,
              style: ClientTypography.headingSmall(context),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: 18),
            ClientButton(
              label: context.l10n.common_tryAgain,
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
