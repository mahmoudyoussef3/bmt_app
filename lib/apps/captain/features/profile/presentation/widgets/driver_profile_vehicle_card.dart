import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_text_direction.dart';

import '../../domain/entities/driver_profile.dart';
import 'driver_profile_section_card.dart';

/// The vehicle assigned to this captain. Only rendered when one exists.
///
/// The plate leads, because it's the one field a captain actually looks this
/// screen up for — matching the bus in front of them to the one they're meant
/// to be driving. It gets a plate-shaped block instead of a label/value row so
/// it can be read at a glance from arm's length; the specs that follow are
/// reference detail and stay quiet.
class DriverProfileVehicleCard extends StatelessWidget {
  const DriverProfileVehicleCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final model = profile.vehicleModel;
    final capacity = profile.vehicleCapacity;

    return DriverProfileSectionCard(
      title: 'المركبة المخصصة',
      icon: Icons.directions_bus_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlateBlock(plate: profile.plateNumber),
          const SizedBox(height: CaptainDesignTokens.s16),
          Row(
            children: [
              _Spec(
                icon: Icons.confirmation_number_outlined,
                label: 'كود المركبة',
                value: profile.vehicleCode ?? '—',
                isIdentifier: true,
              ),
              if (model != null) ...[
                const SizedBox(width: CaptainDesignTokens.s12),
                _Spec(
                  icon: Icons.directions_car_outlined,
                  label: 'الموديل',
                  value: model,
                ),
              ],
              if (capacity != null) ...[
                const SizedBox(width: CaptainDesignTokens.s12),
                _Spec(
                  icon: Icons.event_seat_outlined,
                  label: 'السعة',
                  value: '$capacity راكب',
                ),
              ],
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s16),
          const _ReadyBanner(),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s16,
        vertical: CaptainDesignTokens.s12,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.primary.withValues(alpha: 0.06),
        borderRadius: CaptainDesignTokens.br12,
        border: Border.all(
          color: CaptainColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'لوحة الترخيص',
            style: CaptainTypography.labelSmall(
              context,
            ).copyWith(color: CaptainColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: CaptainDesignTokens.s4),
          Directionality(
            textDirection: CaptainTextDirection.ofIdentifier(value),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.headlineSmall(context).copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: CaptainColors.textPrimaryFor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One vehicle spec, stacked label-over-value so several fit across a phone
/// without any of them truncating to nothing.
class _Spec extends StatelessWidget {
  const _Spec({
    required this.icon,
    required this.label,
    required this.value,
    this.isIdentifier = false,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Set for values that are identifiers rather than prose, so they lay out in
  /// their own direction. See [CaptainTextDirection].
  final bool isIdentifier;

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CaptainTypography.bodyMedium(context).copyWith(
        fontWeight: FontWeight.w800,
        color: CaptainColors.textPrimaryFor(context),
      ),
    );

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: CaptainColors.textSecondaryFor(context),
              ),
              const SizedBox(width: CaptainDesignTokens.s4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.labelSmall(
                    context,
                  ).copyWith(color: CaptainColors.textSecondaryFor(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s4),
          if (isIdentifier)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Directionality(
                textDirection: CaptainTextDirection.ofIdentifier(value),
                child: valueText,
              ),
            )
          else
            valueText,
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
        color: CaptainColors.primaryBright.withValues(alpha: 0.1),
        borderRadius: CaptainDesignTokens.br12,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 16,
            color: CaptainColors.primaryBright,
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Expanded(
            child: Text(
              'مركبة جاهزة للتشغيل',
              style: CaptainTypography.labelMedium(context).copyWith(
                color: CaptainColors.primaryBright,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
