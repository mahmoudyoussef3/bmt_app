import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_text_direction.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';

import '../../domain/entities/driver_profile.dart';

/// The vehicle assigned to this captain. Only rendered when one exists.
///
/// The plate leads, because it's the one field a captain actually looks this
/// screen up for — matching the bus in front of them to the one they're meant
/// to be driving. It gets a plate-shaped block at the top of the group so it
/// can be read at a glance from arm's length; the specs that follow are
/// reference detail and stay as quiet list rows.
class DriverProfileVehicleCard extends StatelessWidget {
  const DriverProfileVehicleCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final model = profile.vehicleModel;
    final capacity = profile.vehicleCapacity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CaptainSectionLabel('المركبة المخصصة'),
        CaptainListGroup(
          children: [
            _PlateBlock(plate: profile.plateNumber),
            CaptainListRow(
              icon: Icons.confirmation_number_outlined,
              label: 'كود المركبة',
              value: profile.vehicleCode ?? '—',
              valueIsIdentifier: true,
            ),
            if (model != null)
              CaptainListRow(
                icon: Icons.directions_car_outlined,
                label: 'الموديل',
                value: model,
              ),
            if (capacity != null)
              CaptainListRow(
                icon: Icons.event_seat_outlined,
                label: 'السعة',
                value: '$capacity راكب',
              ),
          ],
        ),
      ],
    );
  }
}

/// The plate, rendered like a plate. Its direction comes from the plate itself:
/// this fleet runs Egyptian plates (`ط ن ج 4821`) but the column is nullable
/// free text and latin plates turn up in it, and either one reorders if it's
/// handed the wrong direction.
class _PlateBlock extends StatelessWidget {
  const _PlateBlock({required this.plate});

  final String? plate;

  @override
  Widget build(BuildContext context) {
    final value = plate == null || plate!.isEmpty ? '—' : plate!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CaptainDesignTokens.s20),
      color: CaptainColors.primary.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_bus_rounded,
                size: 15,
                color: CaptainColors.textSecondaryFor(context),
              ),
              const SizedBox(width: 6),
              Text(
                'لوحة الترخيص',
                style: CaptainTypography.labelSmall(
                  context,
                ).copyWith(color: CaptainColors.textSecondaryFor(context)),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s8),
          Directionality(
            textDirection: CaptainTextDirection.ofIdentifier(value),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.headlineMedium(context).copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: CaptainColors.textPrimaryFor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
