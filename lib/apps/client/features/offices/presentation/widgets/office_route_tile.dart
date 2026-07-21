import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import '../../domain/entities/office_route.dart';

/// One corridor this office runs. Tapping it drops the rider into the
/// existing booking search, pre-filtered to exactly this route.
class OfficeRouteTile extends StatelessWidget {
  const OfficeRouteTile({super.key, required this.route, required this.onTap});

  final OfficeRoute route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClientCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.route_rounded, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                if (route.startCity.isNotEmpty || route.endCity.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${route.startCity} → ${route.endCity}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: ClientTypography.labelSmall(context).copyWith(
                      color: ClientColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          DirectionalIcon(
            Icons.arrow_forward_rounded,
            color: scheme.primary,
            size: 18,
          ),
        ],
      ),
    );
  }
}
