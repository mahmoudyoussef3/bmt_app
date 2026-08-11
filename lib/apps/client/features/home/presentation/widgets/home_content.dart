import 'dart:math' as math;

import 'package:bmt_app/apps/client/features/support/presentation/routes/support_routes.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/routes/packages_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import 'package:bmt_app/apps/client/features/trips/presentation/routes/trips_routes.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// Loaded home layout: pinned status-bar strip, hero canvas with the
/// quick-action tiles overlapping its lower edge, then the content sections.
///
/// Everything below the hero is a sliver, so the full departure board scrolls
/// lazily instead of building every card up front.
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
    onOpenRoute(BookingRoutes.search, <String, String>{
      'destination': ?destination,
    });
  }

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
              sliver: BlocBuilder<OfficesDirectoryCubit, OfficesDirectoryState>(
                builder: (context, state) => HomeSections(
                  data: data,
                  offices: switch (state) {
                    OfficesDirectoryLoaded(:final offices) => offices,
                    
                    _ => const [],
                  },
                  officesLoading: state is OfficesDirectoryLoading,
                  onOpenRoute: onOpenRoute,
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
                    onRoutes: () => onOpenRoute(BookingRoutes.popularRoutes),
                    onTrips: () => onOpenRoute(TripsRoutes.myTrips),
                    onSubscription: () =>
                        onOpenRoute(PackagesRoutes.mySubscription),
                    onSupport: () => onOpenRoute(SupportRoutes.center),
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
