import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_cubit.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_state.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_packages_section.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/popular_routes_preview.dart';
import 'package:bmt_app/core/localization/failure_l10n_ext.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/app_dialogs.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenRoute,
    required this.onOpenNotifications,
  });

  final void Function(String route, [Object? arguments]) onOpenRoute;
  final VoidCallback onOpenNotifications;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _openSearch() {
    widget.onOpenRoute(ClientRoutes.bookingSearch, const <String, String>{});
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is HomeError) {
          AppDialogs.showErrorDialog(
            context,
            title: 'Unable to load home',
            message: state.failure.localizedMessage(context),
            onRetry: () => context.read<HomeCubit>().load(),
          );
        }
      },
      builder: (context, state) {
        return switch (state) {
          HomeLoaded(:final data) => _HomeContent(
            data: data,
            onOpenRoute: widget.onOpenRoute,
            onOpenNotifications: widget.onOpenNotifications,
            onOpenSearch: _openSearch,
          ),
          HomeError(:final failure) => ClientErrorCard.fullScreen(
            message: failure.localizedMessage(context),
            onRetry: () => context.read<HomeCubit>().load(),
          ),
          HomeLoading() => const _HomeLoadingSkeleton(),
        };
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.data,
    required this.onOpenRoute,
    required this.onOpenNotifications,
    required this.onOpenSearch,
  });

  final HomeData data;
  final void Function(String route, [Object? arguments]) onOpenRoute;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSearch;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openRoute(PopularRouteData route) {
    widget.onOpenRoute(ClientRoutes.bookingRouteSelection, {
      'routeId': route.id,
      'pickup': route.pickup,
      'destination': route.destination,
      'time': '',
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final maxW = AppLayout.maxContentWidth(width);
    final isTablet = width >= 720;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? AppLayout.spaceXl : AppLayout.spaceLg,
                AppLayout.spaceXl,
                isTablet ? AppLayout.spaceXl : AppLayout.spaceLg,
                24,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _WelcomeSection(
                    data: widget.data,
                    onOpenNotifications: widget.onOpenNotifications,
                  ),
                  const SizedBox(height: 18),
                  _RouteSearchSection(
                    controller: _searchController,
                    routes: widget.data.popularRoutes,
                    onBrowseAll: widget.onOpenSearch,
                    onSelectRoute: _openRoute,
                  ),
                  const SizedBox(height: 26),
                  PopularRoutesPreview(
                    routes: widget.data.popularRoutes,
                    previewCount: isTablet ? 4 : 3,
                    onOpenRoute: widget.onOpenRoute,
                  ),
                  const SizedBox(height: 26),
                  if (widget.data.activePackage == null)
                    _SubscriptionPromo(
                      scheme: scheme,
                      onTap: () =>
                          widget.onOpenRoute(ClientRoutes.subscription),
                    ),
                  if (widget.data.activePackage == null)
                    const SizedBox(height: 26),
                  HomePackagesSection(
                    plans: widget.data.packagePlans,
                    activePackage: widget.data.activePackage,
                    previewCount: 4,
                    onOpenSubscription: () =>
                        widget.onOpenRoute(ClientRoutes.subscription),
                  ),
                  const SizedBox(height: 26),
                  _SupportLink(
                    scheme: scheme,
                    onTap: () => widget.onOpenRoute(ClientRoutes.support),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({
    required this.data,
    required this.onOpenNotifications,
  });

  final HomeData data;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firstName = _firstName(data.userName);
    final routeCount = data.popularRoutes.length;
    final tripCount = data.popularRoutes.fold<int>(
      0,
      (sum, route) => sum + route.tripsAvailable,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi $firstName',
                style: ClientTypography.headingLarge(context).copyWith(
                  color: ClientColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Book reliable rides in minutes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                routeCount == 0
                    ? 'Search live routes, compare prices, and reserve your seat when routes are available.'
                    : '$routeCount active routes and $tripCount upcoming trips are ready to explore.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withAlpha(155),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _NotificationButton(onTap: onOpenNotifications),
      ],
    );
  }

  static String _firstName(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty || cleaned.toLowerCase() == 'user') {
      return 'there';
    }
    return cleaned.split(RegExp(r'\s+')).first;
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outline.withAlpha(70)),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _RouteSearchSection extends StatefulWidget {
  const _RouteSearchSection({
    required this.controller,
    required this.routes,
    required this.onBrowseAll,
    required this.onSelectRoute,
  });

  final TextEditingController controller;
  final List<PopularRouteData> routes;
  final VoidCallback onBrowseAll;
  final ValueChanged<PopularRouteData> onSelectRoute;

  @override
  State<_RouteSearchSection> createState() => _RouteSearchSectionState();
}

class _RouteSearchSectionState extends State<_RouteSearchSection> {
  String _query = '';

  List<PopularRouteData> get _matches {
    final query = _query.trim().toLowerCase();
    final source = widget.routes;
    if (query.isEmpty) return source.take(3).toList();
    return source
        .where((route) {
          return route.routeName.toLowerCase().contains(query) ||
              route.pickup.toLowerCase().contains(query) ||
              route.destination.toLowerCase().contains(query);
        })
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matches = _matches;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withAlpha(70)),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Where are you heading?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by route, departure, or destination',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        widget.controller.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withAlpha(55),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.outline.withAlpha(60)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.outline.withAlpha(60)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.routes.isEmpty)
            _SearchEmptyState(onBrowseAll: widget.onBrowseAll)
          else if (matches.isEmpty)
            _NoSearchMatches(onBrowseAll: widget.onBrowseAll)
          else
            ...matches.map(
              (route) => _RouteSuggestionTile(
                route: route,
                onTap: () => widget.onSelectRoute(route),
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteSuggestionTile extends StatelessWidget {
  const _RouteSuggestionTile({required this.route, required this.onTap});

  final PopularRouteData route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.routeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${route.pickup} to ${route.destination}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    route.startingPrice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Destination',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withAlpha(125),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.onBrowseAll});

  final VoidCallback onBrowseAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _InlineHomeEmptyState(
      icon: Icons.route_outlined,
      title: 'No routes available yet',
      subtitle: 'Routes published from the dashboard will appear here.',
      actionLabel: 'Open search',
      color: scheme.primary,
      onTap: onBrowseAll,
    );
  }
}

class _NoSearchMatches extends StatelessWidget {
  const _NoSearchMatches({required this.onBrowseAll});

  final VoidCallback onBrowseAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _InlineHomeEmptyState(
      icon: Icons.manage_search_rounded,
      title: 'No matching routes',
      subtitle: 'Try a route name, departure city, or destination city.',
      actionLabel: 'Browse routes',
      color: scheme.secondary,
      onTap: onBrowseAll,
    );
  }
}

class _SubscriptionPromo extends StatelessWidget {
  const _SubscriptionPromo({required this.scheme, required this.onTap});

  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.primary.withAlpha(62), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withAlpha(18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                top: -34,
                end: -26,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withAlpha(18),
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: -40,
                start: -34,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.secondary.withAlpha(12),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: scheme.primary.withAlpha(22),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Commute smarter with ride packages',
                              style: textTheme.titleMedium?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w900,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Lower repeat-trip costs and keep your booking routine fast.',
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withAlpha(154),
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _PromoBenefit(
                    icon: Icons.savings_outlined,
                    label: 'Save on frequent rides',
                  ),
                  const SizedBox(height: 10),
                  const _PromoBenefit(
                    icon: Icons.event_available_rounded,
                    label: 'Pick a plan that matches your schedule',
                  ),
                  const SizedBox(height: 10),
                  const _PromoBenefit(
                    icon: Icons.flash_on_rounded,
                    label: 'Book faster with fewer repeat steps',
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Weekly to three-month plans',
                          style: textTheme.labelLarge?.copyWith(
                            color: scheme.onSurface.withAlpha(170),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('View plans'),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoBenefit extends StatelessWidget {
  const _PromoBenefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withAlpha(178),
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportLink extends StatelessWidget {
  const _SupportLink({required this.scheme, required this.onTap});

  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppLayout.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.spaceSm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.support_agent_outlined,
              size: 18,
              color: scheme.onSurface.withAlpha(150),
            ),
            const SizedBox(width: AppLayout.spaceSm),
            Text(
              'Contact support',
              style: AppTypography.caption(
                scheme,
              ).copyWith(color: scheme.onSurface.withAlpha(150)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineHomeEmptyState extends StatelessWidget {
  const _InlineHomeEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withAlpha(55)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxW = AppLayout.maxContentWidth(width);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.spaceLg),
          children: [
            const ClientSkeleton(height: 32, width: 180, borderRadius: 8),
            const SizedBox(height: 10),
            const ClientSkeleton(height: 18, width: 260, borderRadius: 8),
            const SizedBox(height: 22),
            const ClientSkeleton(height: 210, borderRadius: 18),
            const SizedBox(height: 26),
            const ClientSkeleton(height: 24, width: 150, borderRadius: 8),
            const SizedBox(height: 12),
            const ClientSkeleton(height: 204, borderRadius: 18),
            const SizedBox(height: 18),
            const ClientSkeleton(height: 178, borderRadius: 18),
          ],
        ),
      ),
    );
  }
}
