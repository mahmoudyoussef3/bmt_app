import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Loading placeholder for the vehicle details screen.
class VehicleLoadingView extends StatelessWidget {
  const VehicleLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ClientAppBar(title: context.l10n.booking_vehicleDetails),
      body: const Center(
        child: CircularProgressIndicator(color: ClientColors.primary),
      ),
    );
  }
}

/// Error state for the vehicle details screen.
class VehicleErrorView extends StatelessWidget {
  const VehicleErrorView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ClientAppBar(title: context.l10n.booking_vehicleDetails),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ClientColors.borderFor(context)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: ClientColors.journeyRed,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.booking_unableToLoadVehicleDetails,
                  textAlign: TextAlign.center,
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: ClientColors.textPrimaryFor(context)),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: ClientTypography.bodyMedium(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state shown when no vehicle matches.
class VehicleEmptyView extends StatelessWidget {
  const VehicleEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ClientAppBar(title: context.l10n.booking_vehicleDetails),
      body: Center(
        child: Text(
          context.l10n.booking_vehicleNotFound,
          style: ClientTypography.bodyMedium(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ),
    );
  }
}

