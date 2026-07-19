import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/map_location_selector.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// Bottom panel on the map screen: pickup + destination selectors and confirm.
class MapSelectionPanel extends StatelessWidget {
  const MapSelectionPanel({
    super.key,
    required this.pickup,
    required this.destination,
    required this.pickupEnabled,
    required this.destinationEnabled,
    required this.onPickup,
    required this.onDestination,
    required this.onConfirm,
  });

  final MapPinOption? pickup;
  final MapPinOption? destination;
  final bool pickupEnabled;
  final bool destinationEnabled;
  final VoidCallback onPickup;
  final VoidCallback onDestination;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(ClientSpacing.md),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.sheet),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: ClientElevation.lg(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.booking_selectOnMapSubtitle,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: 12),
          MapLocationSelector(
            icon: Icons.trip_origin_rounded,
            color: ClientColors.journeyCyan,
            label: l10n.booking_pickupPoint,
            value: pickup?.label ?? l10n.booking_notSet,
            subtitle: pickupEnabled
                ? pickup?.subtitle ?? l10n.booking_tapToChoosePickupStation
                : l10n.booking_noMappedPickupStations,
            enabled: pickupEnabled,
            onTap: onPickup,
          ),
          const SizedBox(height: 8),
          MapLocationSelector(
            icon: Icons.location_on_rounded,
            color: Theme.of(context).colorScheme.error,
            label: l10n.booking_destinationPoint,
            value: destination?.label ?? l10n.booking_notSet,
            subtitle: destinationEnabled
                ? destination?.subtitle ?? l10n.booking_tapToChooseDestination
                : l10n.booking_noMappedDestinations,
            enabled: destinationEnabled,
            onTap: onDestination,
          ),
          const SizedBox(height: 14),
          ClientButton(
            label: l10n.booking_confirmRoute,
            icon: const DirectionalIcon(Icons.arrow_forward_rounded),
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}
