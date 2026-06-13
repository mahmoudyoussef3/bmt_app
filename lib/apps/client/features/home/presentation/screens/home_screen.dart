import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_cubit.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_state.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_hero_trip_panel.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_packages_section.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/popular_routes_preview.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/core/widgets/spinner.dart';
import 'package:bmt_app/core/widgets/app_dialogs.dart';
import 'package:bmt_app/core/localization/failure_l10n_ext.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

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
  Map<String, String> get _searchArguments => const {
    'pickup': 'Banha Station',
    'destination': 'Smart Village',
    'date': 'Today, Jun 3',
    'time': '8:40 AM',
  };

  void _openSearch() {
    widget.onOpenRoute(ClientRoutes.bookingSearch, _searchArguments);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is HomeError) {
          AppDialogs.showErrorDialog(
            context,
            title: 'Unable to Load Data',
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
          HomeError(:final failure) => EmptyState(
            title: 'Home is unavailable',
            subtitle: failure.localizedMessage(context),
          ),
          HomeLoading() => const Center(child: Spinner()),
        };
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final maxW = AppLayout.maxContentWidth(width);
    final currentTrip = data.currentTrip;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Top greeting header and the primary booking/trip panel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppLayout.spaceLg,
                  AppLayout.spaceXl,
                  AppLayout.spaceLg,
                  AppLayout
                      .spaceXl, // Spacious bottom padding before next section
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HomeHeader(
                      scheme: scheme,
                      onOpenNotifications: onOpenNotifications,
                    ),
                    const SizedBox(height: AppLayout.spaceLg),
                    HomeHeroTripPanel(
                      scheme: scheme,
                      trip: currentTrip,
                      onBookTrip: onOpenSearch,
                      onViewTrip: () => onOpenRoute(ClientRoutes.tripDetails, {
                        'tripId': 'T1',
                      }),
                      onTrackTrip: () => onOpenRoute(ClientRoutes.tracking),
                    ),
                  ],
                ),
              ),
            ),

            // Popular routes & Packages & Support links
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.spaceLg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  PopularRoutesPreview(
                    routes: data.popularRoutes,
                    onOpenRoute: onOpenRoute,
                  ),
                  const SizedBox(height: AppLayout.spaceXl),
                  HomePackagesSection(
                    plans: data.packagePlans,
                    onOpenSubscription: () =>
                        onOpenRoute(ClientRoutes.subscription),
                  ),
                  const SizedBox(height: AppLayout.spaceXl),
                  _SupportLink(
                    scheme: scheme,
                    onTap: () => onOpenRoute(ClientRoutes.support),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.scheme, required this.onOpenNotifications});

  final ColorScheme scheme;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.home_goodMorning('Ahmed'),
                style: AppTypography.display(scheme).copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.home_readyForCommute,
                style: AppTypography.caption(scheme).copyWith(
                  color: scheme.onSurface.withAlpha(150),
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onOpenNotifications,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outline.withAlpha(70)),
              boxShadow: [
                BoxShadow(
                  color: scheme.onSurface.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: scheme.onSurface,
                  size: 24,
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
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
              AppLocalizations.of(context)!.home_contactSupport,
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
