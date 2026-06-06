import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class RouteSelectionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const RouteSelectionTile({
    super.key,
    required this.label,
    this.icon = Icons.location_on_rounded,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
