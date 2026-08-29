import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';

import '../../domain/entities/driver_profile.dart';

class DriverProfileInfoCard extends StatelessWidget {
  const DriverProfileInfoCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CaptainSectionLabel(
          'معلومات الحساب',
          color: CaptainColors.primaryInkFor(context),
        ),
        CaptainListGroup(
          children: [
            CaptainListRow(
              icon: Icons.phone_rounded,
              iconColor: CaptainColors.primaryInkFor(context),
              label: 'رقم الهاتف',
              value: profile.phone.isNotEmpty ? profile.phone : '—',
              valueIsIdentifier: profile.phone.isNotEmpty,
            ),
            if (profile.employeeCode != null)
              CaptainListRow(
                icon: Icons.tag_rounded,
                iconColor: CaptainColors.primaryInkFor(context),
                label: 'كود الكابتن',
                value: profile.employeeCode!,
                valueIsIdentifier: true,
              ),
            if (profile.licenseNumber != null)
              CaptainListRow(
                icon: Icons.credit_card_rounded,
                iconColor: CaptainColors.primaryInkFor(context),
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
