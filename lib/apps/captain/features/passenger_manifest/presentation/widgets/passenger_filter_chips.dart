import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/passenger.dart';
import 'passenger_status_presentation.dart';

class PassengerFilterChips extends StatelessWidget {
  const PassengerFilterChips({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final PassengerBoardingStatus? current;
  final ValueChanged<PassengerBoardingStatus> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final status in kFilterablePassengerStatuses)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: _Chip(
                status: status,
                isActive: current == status,
                onSelect: () => onSelect(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.status,
    required this.isActive,
    required this.onSelect,
  });

  final PassengerBoardingStatus status;
  final bool isActive;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return FilterChip(
      label: Text(status.label),
      selected: isActive,
      onSelected: (_) => onSelect(),
      selectedColor: color.withAlpha(30),
      checkmarkColor: color,
      backgroundColor: CaptainColors.surfaceFor(context),
      labelStyle: CaptainTypography.labelMedium(context).copyWith(
        color: isActive ? color : CaptainColors.textSecondaryFor(context),
        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
      ),
      side: BorderSide(color: isActive ? color : Colors.transparent),
    );
  }
}
