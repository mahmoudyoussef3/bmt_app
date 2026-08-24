import 'dart:math' as math;

import 'package:bmt_app/apps/client/features/offices/presentation/routes/offices_routes.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/routes/packages_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_cubit.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_entrance.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_hero_header.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_sections.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/offices_directory_cubit.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/offices_directory_state.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_directory_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_directory_state.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// Loaded home layout: pinned status-bar strip, hero canvas whose arch is
/// crossed by the search card, then the quick-action tiles and the content
/// sections on the page background below it.
///
/// Everything below the hero is a sliver, so the full departure board scrolls
/// lazily instead of building every card up front.
class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.data,
    required this.onOpenRoute,
    required this.onOpenNotifications,
    required this.onSwitchTab,
  });

  final HomeData data;
  final void Function(String route, [Object? arguments]) onOpenRoute;
  final VoidCallback onOpenNotifications;
  final void Function(String tab) onSwitchTab;

  /// The hero card's one navigation. A complete pair goes straight to the
  /// matching routes; anything less opens the full search screen carrying
  /// what the rider already chose, where date, time and popular routes are
  /// also on offer.
  void _openSearch(BookingSearchQuery query) => onOpenRoute(
    query.isComplete ? BookingRoutes.routeSelection : BookingRoutes.search,
    query.toArguments(),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 720;
    final horizontalPadding = isTablet ? ClientSpacing.xl : ClientSpacing.md;
    final maxWidth = AppLayout.maxContentWidth(width);

    final sideInset = math.max(horizontalPadding, (width - maxWidth) / 2);

    return ColoredBox(
      color: ClientColors.backgroundFor(context),
      child: RefreshIndicator(
        color: ClientColors.primaryFor(context),
        edgeOffset: MediaQuery.paddingOf(context).top,
        onRefresh: () async {
          await Future.wait([
            context.read<HomeCubit>().load(),
            context.read<OfficesDirectoryCubit>().refresh(),
          ]);
        },
        child: CustomScrollView(
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 0,
              automaticallyImplyLeading: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: ClientColors.heroTopFor(context),
              systemOverlayStyle: SystemUiOverlayStyle.light,
            ),
            SliverToBoxAdapter(
              child: _buildHeroWithActions(
                context,
                isTablet,
                horizontalPadding,
                maxWidth,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                sideInset,
                ClientSpacing.lg,
                sideInset,
                ClientSpacing.section,
              ),
              sliver: BlocBuilder<RoutesDirectoryCubit, RoutesDirectoryState>(
                builder: (context, routesState) =>
                    BlocBuilder<OfficesDirectoryCubit, OfficesDirectoryState>(
                      builder: (context, officesState) => HomeSections(
                        data: data,
                        offices: switch (officesState) {
                          OfficesDirectoryLoaded(:final offices) => offices,
                          _ => const [],
                        },
                        officesLoading: officesState is OfficesDirectoryLoading,
                        featuredRoutes: switch (routesState) {
                          RoutesDirectoryLoaded(:final routes) => routes,
                          _ => const [],
                        },
                        featuredRoutesLoading:
                            routesState is RoutesDirectoryLoading,
                        onOpenRoute: onOpenRoute,
                        onSwitchTab: onSwitchTab,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The hero and the tiles beneath it. The tiles clear the arch instead of
  /// sitting on it: the search card is the only thing that crosses the curve,
  /// so the header reads as one shape rather than a stack of overlaps.
  Widget _buildHeroWithActions(
    BuildContext context,
    bool isTablet,
    double horizontalPadding,
    double maxWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeHeroHeader(
          topInset: 0,
          bottomSpace: ClientSpacing.lg,
          horizontalPadding: horizontalPadding,
          maxContentWidth: maxWidth,
          onOpenNotifications: onOpenNotifications,
          onSearch: _openSearch,
        ),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: HomeEntrance(
                order: 1,
                child: HomeQuickActions(
                  onTrips: () => onSwitchTab('trips'),
                  onSubscription: () =>
                      onOpenRoute(PackagesRoutes.mySubscription),
                  onOffices: () => onOpenRoute(OfficesRoutes.directory),
                  onRoutes: () => onSwitchTab('routes'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
