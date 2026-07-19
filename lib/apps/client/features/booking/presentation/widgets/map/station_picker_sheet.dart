import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// Bottom sheet listing selectable stations for the map screen. Pops the
/// chosen [MapPinOption].
class StationPickerSheet extends StatelessWidget {
  const StationPickerSheet({
    super.key,
    required this.title,
    required this.pins,
    required this.selected,
  });

  final String title;
  final List<MapPinOption> pins;
  final MapPinOption? selected;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(title, style: ClientTypography.headingSmall(context)),
          ),
          Divider(height: 1, color: ClientColors.borderFor(context)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: pins.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) => _StationTile(
                pin: pins[index],
                isSelected: selected?.label == pins[index].label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationTile extends StatelessWidget {
  const _StationTile({required this.pin, required this.isSelected});

  final MapPinOption pin;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: ClientColors.primaryFor(context).withAlpha(18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClientRadius.md),
      ),
      leading: Icon(
        Icons.location_on_outlined,
        color: isSelected
            ? ClientColors.primaryFor(context)
            : ClientColors.textTertiaryFor(context),
      ),
      title: Text(
        pin.label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: pin.subtitle.isEmpty ? null : Text(pin.subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: ClientColors.primaryFor(context),
            )
          : const DirectionalIcon(Icons.chevron_right_rounded),
      onTap: () => Navigator.pop(context, pin),
    );
  }
}
