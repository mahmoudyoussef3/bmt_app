import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The driver's initials avatar inside [TripDriverCard].
class DriverAvatar extends StatelessWidget {
  const DriverAvatar({super.key, required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: ClientColors.primaryLight,
      child: Text(
        initials,
        style: ClientTypography.headingSmall(
          context,
        ).copyWith(color: ClientColors.primary),
      ),
    );
  }
}
