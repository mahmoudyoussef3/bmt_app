import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_cubit.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_entrance.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_hero_header.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_sections.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/routes/trips_routes.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// Loaded home layout: pinned status-bar strip, hero canvas with the
/// quick-action tiles overlapping its lower edge, then the content sections.
class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.data,
    required this.onOpenRoute,
    required this.onOpenNotifications,
  });

  final HomeData data;
  final void Function(String route, [Object? arguments]) onOpenRoute;
  final VoidCallback onOpenNotifications;

  static const double _tileOverlap = HomeQuickActions.height / 2;

  void _openSearch([String? destination]) {
    onOpenRoute(ClientRoutes.bookingSearch, <String, String>{
      'destination': ?destination,
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 720;
    final horizontalPadding = isTablet ? ClientSpacing.xl : ClientSpacing.md;
    final maxWidth = AppLayout.maxContentWidth(width);

    return ColoredBox(
      color: ClientColors.backgroundFor(context),
      child: RefreshIndicator(
        color: ClientColors.primaryFor(context),
        edgeOffset: MediaQuery.paddingOf(context).top,
        onRefresh: () => context.read<HomeCubit>().load(),
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
            SliverToBoxAdapter(child: _buildHeroWithActions(context, isTablet, horizontalPadding, maxWidth)),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      ClientSpacing.lg,
                      horizontalPadding,
                      ClientSpacing.section,
                    ),
                    child: HomeSections(
                      data: data,
                      isTablet: isTablet,
                      onOpenRoute: onOpenRoute,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroWithActions(
    BuildContext context,
    bool isTablet,
    double horizontalPadding,
    double maxWidth,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: _tileOverlap),
          child: HomeHeroHeader(
            userName: data.userName,
            destinations: data.destinationSuggestions,
            topInset: 0,
            bottomSpace: _tileOverlap + ClientSpacing.lg,
            horizontalPadding: horizontalPadding,
            maxContentWidth: maxWidth,
            onOpenNotifications: onOpenNotifications,
            onSearch: _openSearch,
            onSelectDestination: _openSearch,
          ),
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: HomeEntrance(
                  order: 1,
                  child: HomeQuickActions(
                    onRoutes: () =>
                        onOpenRoute(ClientRoutes.bookingPopularRoutes),
                    onTrips: () => onOpenRoute(TripsRoutes.myTrips),
                    onPackages: () =>
                        onOpenRoute(ClientRoutes.subscription, {
                          'hasActiveSubscription': data.activePackage != null,
                        }),
                    onSupport: () => onOpenRoute(ClientRoutes.support),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
