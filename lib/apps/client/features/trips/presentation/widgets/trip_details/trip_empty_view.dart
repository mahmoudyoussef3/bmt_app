import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_brand_app_bar.dart';

/// Shown when a trip ID doesn't resolve to a trip — offers a way forward
/// instead of a dead-end message (spec FR-012).
class TripEmptyView extends StatelessWidget {
  const TripEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      appBar: const TripBrandAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: ClientColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: ClientColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Trip not found',
                style: ClientTypography.headingMedium(context),
              ),
              const SizedBox(height: 8),
              Text(
                'This trip may have been removed or the link is no longer '
                'valid. Browse routes to plan your next ride.',
                textAlign: TextAlign.center,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: 24),
              ClientButton(
                label: 'Browse routes',
                onPressed: () =>
                    Navigator.of(context).pushNamed('/booking/search'),
                expand: false,
              ),
              const SizedBox(height: 10),
              ClientButton.text(
                label: 'Go back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
