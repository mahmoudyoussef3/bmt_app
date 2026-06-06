import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

/// Multi-passenger presentation placeholder (UI only, no booking logic).
class SeatPassengerPreviewCard extends StatelessWidget {
  const SeatPassengerPreviewCard({
    super.key,
    required this.selectedSeat,
    this.showMultiPreview = true,
  });

  final String? selectedSeat;
  final bool showMultiPreview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (selectedSeat == null) {
      return const SizedBox.shrink();
    }

    return AppSurface(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Passengers',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              AppBadge(text: '1 seat'),
            ],
          ),
          const SizedBox(height: 12),
          _PassengerRow(
            index: 1,
            seatLabel: 'A$selectedSeat',
            highlighted: true,
          ),
          if (showMultiPreview) ...[
            const SizedBox(height: 8),
            _PassengerRow(
              index: 2,
              seatLabel: 'A4',
              highlighted: false,
              placeholder: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Select another seat to add a passenger (UI preview)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: scheme.onSurface.withAlpha(140),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PassengerRow extends StatelessWidget {
  const _PassengerRow({
    required this.index,
    required this.seatLabel,
    required this.highlighted,
    this.placeholder = false,
  });

  final int index;
  final String seatLabel;
  final bool highlighted;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primary.withAlpha(28)
            : scheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? scheme.primary.withAlpha(100)
              : scheme.outline.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primary.withAlpha(placeholder ? 30 : 60),
            child: Text(
              '$index',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: placeholder
                    ? scheme.onSurface.withAlpha(100)
                    : scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passenger $index',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: placeholder ? scheme.onSurface.withAlpha(120) : null,
                  ),
                ),
                Text(
                  placeholder ? 'Awaiting seat selection' : 'Seat $seatLabel',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (!placeholder)
            Icon(Icons.check_circle_rounded, color: scheme.secondary, size: 20),
        ],
      ),
    );
  }
}
