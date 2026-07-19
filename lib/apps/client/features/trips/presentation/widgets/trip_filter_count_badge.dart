import 'package:flutter/material.dart';

/// The count bubble inside a filter pill.
class TripFilterCountBadge extends StatelessWidget {
  const TripFilterCountBadge({
    super.key,
    required this.count,
    required this.active,
  });

  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active ? scheme.primary : scheme.onSurfaceVariant.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          height: 1.1,
        ),
      ),
    );
  }
}
