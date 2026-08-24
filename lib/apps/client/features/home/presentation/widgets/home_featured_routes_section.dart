import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_entrance.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_featured_route_card.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_section_header.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_summary.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// A short shelf of corridors from the routes catalog — Home's shortcut into
/// route discovery, capped so it never turns into the full catalog. Empty
/// hides the section: a rider is never shown an empty shelf.
class HomeFeaturedRoutesSection extends StatelessWidget {
  const HomeFeaturedRoutesSection({
    super.key,
    required this.routes,
    required this.isLoading,
    required this.order,
    required this.onOpenRoute,
    required this.onViewAll,
  });

  final List<RouteSummary> routes;
  final bool isLoading;
  final int order;
  final ValueChanged<RouteSummary> onOpenRoute;
  final VoidCallback onViewAll;

  static const int previewCount = 3;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && routes.isEmpty) return const SliverToBoxAdapter();

    final l10n = context.l10n;
    final visible = routes.take(previewCount).toList();

    return SliverToBoxAdapter(
      child: HomeEntrance(
        order: order,
        child: Padding(
          padding: const EdgeInsets.only(bottom: ClientSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSectionHeader(
                title: l10n.home_featuredRoutesTitle,
                subtitle: l10n.home_featuredRoutesSubtitle,
                actionLabel: l10n.home_viewAll,
                onAction: onViewAll,
              ),
              const SizedBox(height: ClientSpacing.md),
              if (isLoading)
                const _FeaturedRoutesSkeleton()
              else
                for (final route in visible) ...[
                  HomeFeaturedRouteCard(
                    route: route,
                    onTap: () => onOpenRoute(route),
                  ),
                  if (route != visible.last)
                    const SizedBox(height: ClientSpacing.sm),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedRoutesSkeleton extends StatelessWidget {
  const _FeaturedRoutesSkeleton();

  static const double _cardHeight = 150;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < HomeFeaturedRoutesSection.previewCount; i++) ...[
          ClientSkeleton(height: _cardHeight, borderRadius: ClientRadius.lg),
          if (i < HomeFeaturedRoutesSection.previewCount - 1)
            const SizedBox(height: ClientSpacing.sm),
        ],
      ],
    );
  }
}
