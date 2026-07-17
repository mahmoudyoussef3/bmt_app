import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_detail_row.dart';

import '../../domain/entities/driver_profile.dart';
import 'driver_profile_section_card.dart';

/// The captain's own account details.
///
/// The phone and licence numbers are marked LTR: the app runs RTL, and a bare
/// Arabic paragraph reorders latin digits into a number the captain doesn't
/// have.
class DriverProfileInfoCard extends StatelessWidget {
  const DriverProfileInfoCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final rows =
        <({IconData icon, String label, String value, bool isIdentifier})>[
          (
            icon: Icons.phone_rounded,
            label: 'رقم الهاتف',
            value: profile.phone.isNotEmpty ? profile.phone : '—',
            isIdentifier: profile.phone.isNotEmpty,
          ),
          if (profile.employeeCode != null)
            (
              icon: Icons.badge_outlined,
              label: 'كود الكابتن',
              value: profile.employeeCode!,
              isIdentifier: true,
            ),
          if (profile.licenseNumber != null)
            (
              icon: Icons.badge_rounded,
              label: 'رقم الرخصة',
              value: profile.licenseNumber!,
              isIdentifier: true,
            ),
        ];

    return DriverProfileSectionCard(
      title: 'معلومات الحساب',
      icon: Icons.person_rounded,
      child: Column(
        children: [
          for (final (index, row) in rows.indexed)
            CaptainDetailRow(
              icon: row.icon,
              label: row.label,
              value: row.value,
              valueIsIdentifier: row.isIdentifier,
              bottomSpacing: index == rows.length - 1
                  ? 0
                  : CaptainDesignTokens.s12,
            ),
        ],
      ),
    );
  }
}
