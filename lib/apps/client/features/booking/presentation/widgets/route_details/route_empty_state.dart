import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Shown when a search returns no bookable route at all (as opposed to a
/// fetch failure, which uses [ClientErrorCard.fullScreen]).
class RouteEmptyState extends StatelessWidget {
  const RouteEmptyState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_outlined, color: scheme.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              context.l10n.booking_noBookableRouteFound,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.booking_tryDifferentDepartureDest,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 16),
            ClientButton(
              label: context.l10n.common_tryAgain,
              onPressed: onRetry,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}
