import 'package:flutter/material.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';

import '../../domain/entities/driver_profile.dart';

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
        CaptainListGroup(
          children: [
            CaptainListRow(
              icon: Icons.confirmation_number_outlined,
              label: 'لوحة الترخيص',
              value: profile.plateNumber == null || profile.plateNumber!.isEmpty
                  ? '—'
                  : profile.plateNumber!,
              valueIsIdentifier: true,
            ),
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
