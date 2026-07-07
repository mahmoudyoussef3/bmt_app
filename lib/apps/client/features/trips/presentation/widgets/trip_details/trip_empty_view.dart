import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_static_app_bar.dart';

/// Shown when a trip ID doesn't resolve to a trip — offers a way back
/// instead of a dead-end message (spec FR-012).
class TripEmptyView extends StatelessWidget {
  const TripEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      appBar: const TripStaticAppBar(title: 'Trip Details'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trip not found',
                style: ClientTypography.headingSmall(context),
              ),
              const SizedBox(height: 8),
              Text(
                'This trip may have been removed or the link is no longer valid.',
                textAlign: TextAlign.center,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: 16),
              ClientButton.secondary(
                label: 'Go back',
                onPressed: () => Navigator.of(context).maybePop(),
                expand: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
