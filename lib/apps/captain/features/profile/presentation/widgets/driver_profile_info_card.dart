import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';

import '../../domain/entities/driver_profile.dart';
import 'driver_profile_rating_pill.dart';

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
            // The rating is how the captain is seen from the other side of the
            // app, and it is the one line here they did not enter themselves —
            // it belongs on the screen that is about them.
            if (profile.hasRating)
              CaptainListRow(
                icon: Icons.star_rounded,
                label: 'التقييم',
                trailing: DriverProfileRatingPill(
                  rating: profile.averageRating,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
