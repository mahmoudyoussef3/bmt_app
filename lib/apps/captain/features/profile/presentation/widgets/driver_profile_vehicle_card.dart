import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_detail_row.dart';

import '../../domain/entities/driver_profile.dart';
import 'driver_profile_section_card.dart';

/// The vehicle assigned to this captain. Only rendered when one exists.
class DriverProfileVehicleCard extends StatelessWidget {
  const DriverProfileVehicleCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return DriverProfileSectionCard(
      title: 'المركبة المخصصة',
      icon: Icons.directions_bus_rounded,
      child: Column(
        children: [
          CaptainDetailRow(
            icon: Icons.confirmation_number_rounded,
            label: 'كود المركبة',
            value: profile.vehicleCode ?? '—',
          ),
          CaptainDetailRow(
            icon: Icons.credit_card_rounded,
            label: 'لوحة الترخيص',
            value: profile.plateNumber ?? '—',
          ),
          if (profile.vehicleModel != null)
            CaptainDetailRow(
              icon: Icons.directions_car_rounded,
              label: 'الموديل',
              value: profile.vehicleModel!,
            ),
          if (profile.vehicleCapacity != null)
            CaptainDetailRow(
              icon: Icons.event_seat_rounded,
              label: 'السعة',
              value: '${profile.vehicleCapacity} راكب',
            ),
          const SizedBox(height: CaptainDesignTokens.s12),
          const _ReadyBanner(),
        ],
      ),
    );
  }
}

class _ReadyBanner extends StatelessWidget {
  const _ReadyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s12,
        vertical: CaptainDesignTokens.s8,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.primary.withValues(alpha: 0.1),
        borderRadius: CaptainDesignTokens.br12,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 16,
            color: CaptainColors.primary,
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Text(
            'مركبة جاهزة للتشغيل',
            style: CaptainTypography.labelMedium(context).copyWith(
              color: CaptainColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
