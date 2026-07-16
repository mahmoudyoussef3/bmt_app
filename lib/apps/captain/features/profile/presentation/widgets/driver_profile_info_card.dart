import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/widgets/captain_detail_row.dart';

import '../../domain/entities/driver_profile.dart';
import 'driver_profile_section_card.dart';

/// The captain's own account details.
class DriverProfileInfoCard extends StatelessWidget {
  const DriverProfileInfoCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return DriverProfileSectionCard(
      title: 'معلومات الحساب',
      icon: Icons.person_rounded,
      child: Column(
        children: [
          CaptainDetailRow(
            icon: Icons.phone_rounded,
            label: 'رقم الهاتف',
            value: profile.phone.isNotEmpty ? profile.phone : '—',
          ),
          if (profile.licenseNumber != null)
            CaptainDetailRow(
              icon: Icons.badge_rounded,
              label: 'رقم الرخصة',
              value: profile.licenseNumber!,
            ),
        ],
      ),
    );
  }
}
