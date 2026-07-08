import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';

/// The one shared empty/error state for every EasyWay map surface: no valid
/// coordinates, GPS unavailable, or route data missing. Never a blank map,
/// never a raw technical error — a friendly explanation plus an optional
/// retry action.
class MapEmptyPanel extends StatelessWidget {
  const MapEmptyPanel({
    super.key,
    this.icon = Icons.location_off_outlined,
    this.title = 'Map coordinates unavailable',
    this.message = 'The details are still available below.',
    this.onRetry,
    this.retryLabel = 'Refresh',
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(70),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: MapStyle.surface(context),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                  boxShadow: MapStyle.shadow(context),
                ),
                child: Icon(icon, color: MapStyle.onSurfaceMuted(context)),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextThemes.caption(Theme.of(context).colorScheme),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MapStyle.onSurfaceMuted(context),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 14),
                OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
