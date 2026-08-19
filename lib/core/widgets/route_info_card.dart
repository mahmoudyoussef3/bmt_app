import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

class RouteInfoCard extends StatelessWidget {
  const RouteInfoCard({
    super.key,
    required this.title,
    required this.origin,
    required this.destination,
    required this.status,
    this.duration,
    this.distance,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String origin;
  final String destination;
  final String status;
  final String? duration;
  final String? distance;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusChip(label: status),
            ],
          ),
          const SizedBox(height: 6),
          RouteDirectionText(
            origin: origin,
            destination: destination,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
              ),
            ),
          ],
          if (duration != null || distance != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (duration != null) _MetaChip(label: duration!),
                if (distance != null) _MetaChip(label: distance!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(140),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
