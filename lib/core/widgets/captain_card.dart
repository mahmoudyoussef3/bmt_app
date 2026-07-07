import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/badge.dart';

class CaptainCard extends StatelessWidget {
  const CaptainCard({
    super.key,
    required this.name,
    required this.status,
    required this.association,
    this.avatarText,
    this.subtitle,
    this.onPrimaryAction,
    this.primaryActionLabel,
  });

  final String name;
  final String status;
  final String association;
  final String? avatarText;
  final String? subtitle;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withAlpha(24),
            child: Text(
              (avatarText ?? name).trim().isEmpty
                  ? '?'
                  : (avatarText ?? name)[0].toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    AppBadge(text: status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  association,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(170),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onPrimaryAction != null && primaryActionLabel != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onPrimaryAction,
              child: Text(primaryActionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
