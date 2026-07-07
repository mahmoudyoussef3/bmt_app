import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One-tap destination shortcuts under the hero search bar.
///
/// Suggestions come from live route data (Supabase) — tapping a chip opens
/// the booking search with the destination prefilled.
class HomeDestinationChips extends StatelessWidget {
  const HomeDestinationChips({
    super.key,
    required this.destinations,
    required this.onSelect,
    this.maxChips = 5,
  });

  final List<String> destinations;
  final ValueChanged<String> onSelect;
  final int maxChips;

  @override
  Widget build(BuildContext context) {
    final visible = destinations
        .where((d) => d.trim().isNotEmpty)
        .take(maxChips)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final (index, destination) in visible.indexed) ...[
            if (index > 0) const SizedBox(width: 8),
            _DestinationChip(
              label: destination,
              onTap: () => onSelect(destination),
            ),
          ],
        ],
      ),
    );
  }
}

class _DestinationChip extends StatelessWidget {
  const _DestinationChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(30),
      borderRadius: BorderRadius.circular(ClientRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClientRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClientRadius.pill),
            border: Border.all(color: Colors.white.withAlpha(45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.place_outlined,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelMedium(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
