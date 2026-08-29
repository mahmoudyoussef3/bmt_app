import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';

import '../../domain/entities/driver_profile.dart';

class DriverProfileVehicleCard extends StatelessWidget {
  const DriverProfileVehicleCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final plate = profile.plateNumber;
    final model = profile.vehicleModel;
    final capacity = profile.vehicleCapacity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The group used to sit unlabelled at the top of the page, which left
        // a plate and a fleet code with nothing saying what they belonged to.
        CaptainSectionLabel(
          'المركبة',
          color: CaptainColors.primaryInkFor(context),
        ),
        CaptainListGroup(
          children: [
            CaptainListRow(
              icon: Icons.confirmation_number_outlined,
              iconColor: CaptainColors.primaryInkFor(context),
              label: 'لوحة الترخيص',
              value: plate == null || plate.isEmpty ? '—' : plate,
              valueIsIdentifier: true,
            ),
            CaptainListRow(
              icon: Icons.tag_rounded,
              iconColor: CaptainColors.primaryInkFor(context),
              label: 'كود المركبة',
              value: profile.vehicleCode ?? '—',
              valueIsIdentifier: true,
            ),
            if (model != null)
              CaptainListRow(
                icon: Icons.directions_bus_outlined,
                iconColor: CaptainColors.primaryInkFor(context),
                label: 'الموديل',
                value: model,
              ),
            if (capacity != null)
              CaptainListRow(
                icon: Icons.event_seat_outlined,
                iconColor: CaptainColors.primaryInkFor(context),
                label: 'السعة',
                value: '$capacity راكب',
              ),
          ],
        ),
      ],
    );
  }
}
