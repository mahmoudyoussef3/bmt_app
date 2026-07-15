import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_filters_button.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The routes discovery/results header: title, live match count, search
/// field, and the single entry point into the premium filter sheet.
class RoutesDiscoveryHeader extends StatelessWidget {
  const RoutesDiscoveryHeader({
    super.key,
    required this.controller,
    required this.totalRoutes,
    required this.visibleRoutes,
    required this.activeFilters,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOpenFilters,
  });

  final TextEditingController controller;
  final int totalRoutes;
  final int visibleRoutes;
  final int activeFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.booking_findYourBestCommute,
          style: ClientTypography.headingLarge(context),
        ),
        const SizedBox(height: ClientSpacing.xxs),
        Text(
          totalRoutes == 0
              ? context.l10n.booking_searchRoutesWhenAvailable
              : context.l10n.booking_routesMatchSearch(
                  visibleRoutes,
                  totalRoutes,
                ),
          style: ClientTypography.bodyMedium(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: ClientSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.l10n.booking_searchDepartureDestinationHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.l10n.booking_clearSearch,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: onClearSearch,
                        ),
                ),
              ),
            ),
            const SizedBox(width: ClientSpacing.sm),
            RouteFiltersButton(
              activeCount: activeFilters,
              onTap: onOpenFilters,
            ),
          ],
        ),
      ],
    );
  }
}
