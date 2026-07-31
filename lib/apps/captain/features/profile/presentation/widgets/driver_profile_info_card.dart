import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';

import '../../domain/entities/driver_profile.dart';

/// The captain's own account details.
///
/// The office is deliberately absent: it is stated on the identity hero, where
/// it belongs, and repeating it here would have the screen answer the same
/// question twice.
///
/// The phone and licence numbers are marked as identifiers: the app runs RTL,
/// and a bare Arabic paragraph reorders latin digits into a number the captain
/// doesn't have.
class DriverProfileInfoCard extends StatelessWidget {
  const DriverProfileInfoCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CaptainSectionLabel('معلومات الحساب'),
        CaptainListGroup(
          children: [
            CaptainListRow(
              icon: Icons.phone_rounded,
              label: 'رقم الهاتف',
              value: profile.phone.isNotEmpty ? profile.phone : '—',
              valueIsIdentifier: profile.phone.isNotEmpty,
            ),
            if (profile.employeeCode != null)
              CaptainListRow(
                // Distinct glyphs on purpose: the code and the licence number
                // used to sit under `badge_outlined` and `badge_rounded`, two
                // near-identical shapes stacked in the same icon column, so the
                // column stopped telling the rows apart at a glance.
                icon: Icons.tag_rounded,
                label: 'كود الكابتن',
                value: profile.employeeCode!,
                valueIsIdentifier: true,
              ),
            if (profile.licenseNumber != null)
              CaptainListRow(
                icon: Icons.credit_card_rounded,
                label: 'رقم الرخصة',
                value: profile.licenseNumber!,
                valueIsIdentifier: true,
              ),
          ],
        ),
      ],
    );
  }
}
