import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/routes/routes_feature_routes.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/routes_directory_cubit.dart';
import '../cubit/routes_directory_state.dart';
import '../../domain/entities/route_summary.dart';
import '../widgets/routes_directory_list.dart';
import '../widgets/routes_empty_view.dart';
import '../widgets/routes_search_field.dart';

/// The routes tab: every active route on the marketplace, searchable by
/// name, endpoint city, or operator. Tapping one opens its full details.
class RoutesDirectoryScreen extends StatelessWidget {
  const RoutesDirectoryScreen({super.key, required this.onOpenRoute});

  /// Pushes onto the root navigator — this tab does not own navigation
  /// itself, matching the shell's other tabs.
  final void Function(String route, [Object? arguments]) onOpenRoute;

  void _openRoute(RouteSummary route) {
    onOpenRoute(RoutesFeatureRoutes.details, {'routeId': route.id});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutesDirectoryCubit, RoutesDirectoryState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final loaded = state is RoutesDirectoryLoaded ? state : null;

        return Column(
          children: [
            _CatalogMasthead(
              title: l10n.nav_routes,
              lead: l10n.routes_catalogLead,
              count: loaded == null
                  ? null
                  : l10n.routes_countLabel(loaded.routes.length),
              
              searchBand: loaded != null && loaded.routes.isNotEmpty
                  ? _SearchBand(state: loaded)
                  : null,
            ),
            Expanded(
              child: switch (state) {
                RoutesDirectoryLoading() => const _CatalogSkeleton(),
                RoutesDirectoryError(:final message) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(ClientSpacing.md),
                    child: ClientErrorCard(
                      message: message,
                      retryLabel: l10n.common_retry,
                      onRetry: () =>
                          context.read<RoutesDirectoryCubit>().load(),
                    ),
                  ),
                ),
                RoutesDirectoryLoaded(:final routes) when routes.isEmpty =>
                  const RoutesEmptyView(),
                final RoutesDirectoryLoaded loadedState =>
                  loadedState.isFilteredEmpty
                      ? RoutesEmptyView(query: loadedState.query)
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<RoutesDirectoryCubit>().refresh(),
                          child: RoutesDirectoryList(
                            routes: loadedState.visibleRoutes,
                            onOpenRoute: _openRoute,
                          ),
                        ),
              },
            ),
          ],
        );
      },
    );
  }
}

class _SearchBand extends StatelessWidget {
  const _SearchBand({required this.state});

  final RoutesDirectoryLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searching = state.query.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientSpacing.lg,
        ClientSpacing.sm,
        ClientSpacing.lg,
        ClientSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoutesSearchField(query: state.query),
          if (searching) ...[
            const SizedBox(height: ClientSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.filter_alt_rounded,
                  size: 13,
                  color: Colors.white.withAlpha(210),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.routes_matchesLabel(state.visibleRoutes.length),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.labelMedium(context).copyWith(
                      color: Colors.white.withAlpha(230),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The catalog's letterhead: what this list is, how big it is, and the box
/// that narrows it. A tab-root masthead — no back button, and no manual top
/// inset since the shell already wraps this tab in a `SafeArea`.
class _CatalogMasthead extends StatelessWidget {
  const _CatalogMasthead({
    required this.title,
    required this.lead,
    required this.count,
    required this.searchBand,
  });

  final String title;
  final String lead;

  /// "12 routes" — absent until the catalog has loaded, because a count
  /// invented before the data arrives is a claim the screen cannot keep.
  final String? count;

  final Widget? searchBand;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.fromLTRB(
        ClientSpacing.md,
        ClientSpacing.md,
        ClientSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.xl),
        boxShadow: ClientElevation.md(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClientSpacing.lg,
              ClientSpacing.lg,
              ClientSpacing.lg,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.headingMedium(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: ClientSpacing.xs),
                  _CountPill(label: count!),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClientSpacing.lg,
              ClientSpacing.xs,
              ClientSpacing.lg,
              0,
            ),
            child: Text(
              lead,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: Colors.white.withAlpha(210)),
            ),
          ),
          ?searchBand,
          if (searchBand == null) const SizedBox(height: ClientSpacing.lg),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(46),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        ClientSpacing.md,
        ClientSpacing.md,
        ClientSpacing.md,
        ClientSpacing.xl,
      ),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: ClientSpacing.sm),
      itemBuilder: (_, _) => ClientSkeleton.routeCard(),
    );
  }
}
