import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_cubit.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_state.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_packages_section.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/popular_routes_preview.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/routes/trips_routes.dart';
import 'package:bmt_app/core/localization/failure_l10n_ext.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/widgets/app_dialogs.dart';

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
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 720;
    final horizontalPadding = isTablet ? ClientSpacing.xl : ClientSpacing.md;
    final maxWidth = AppLayout.maxContentWidth(width);

    return ColoredBox(
      color: ClientColors.backgroundFor(context),
      child: RefreshIndicator(
        color: ClientColors.primaryFor(context),
        onRefresh: () => context.read<HomeCubit>().load(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HomeHeader(
                          userName: data.userName,
                          onOpenNotifications: onOpenNotifications,
                        ),
                        const SizedBox(height: ClientSpacing.lg),
                        _JourneyPlannerCard(onTap: onOpenSearch),
                        const SizedBox(height: ClientSpacing.md),
                        _QuickActions(
                          onRoutes: () => onOpenRoute(
                            ClientRoutes.bookingPopularRoutes,
                          ),
                          onTrips: () => onOpenRoute(TripsRoutes.myTrips),
                          onPackages: () => onOpenRoute(
                            ClientRoutes.subscription,
                            {
                              'hasActiveSubscription':
                                  data.activePackage != null,
                            },
                          ),
                          onSupport: () =>
                              onOpenRoute(ClientRoutes.support),
                        ),
                        if (data.currentTrip != null) ...[
                          const SizedBox(height: ClientSpacing.xxl),
                          _SectionIntro(
                            eyebrow: 'YOUR JOURNEY',
                            title: 'Ready when you are',
                            subtitle:
                                'Everything you need for your next trip.',
                          ),
                          const SizedBox(height: ClientSpacing.md),
                          _CurrentJourneyCard(
                            trip: data.currentTrip!,
                            onTap: () => onOpenRoute(ClientRoutes.tracking, {
                              'bookingId': data.currentTrip!.id,
                            }),
                          ),
                        ],
                        if (data.nearbyTrips.isNotEmpty) ...[
                          const SizedBox(height: ClientSpacing.xxl),
                          _DepartingSoonSection(
                            trips: data.nearbyTrips,
                            onSelect: (trip) => onOpenRoute(
                              ClientRoutes.bookingRouteSelection,
                              {
                                'pickup': trip.pickup,
                                'destination': trip.destination,
                                'date': DateTime.now()
                                    .toIso8601String()
                                    .split('T')
                                    .first,
                                'time': trip.departureTime,
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: ClientSpacing.xxl),
                        PopularRoutesPreview(
                          routes: data.popularRoutes,
                          previewCount: isTablet ? 4 : 3,
                          onOpenRoute: onOpenRoute,
                        ),
                        if (data.activePackage == null) ...[
                          const SizedBox(height: ClientSpacing.xxl),
                          _PackageInvitation(
                            onTap: () => onOpenRoute(
                              ClientRoutes.subscription,
                              {'hasActiveSubscription': false},
                            ),
                          ),
                        ],
                        const SizedBox(height: ClientSpacing.xxl),
                        HomePackagesSection(
                          plans: data.packagePlans,
                          activePackage: data.activePackage,
                          previewCount: isTablet ? 4 : 3,
                          onOpenSubscription: () => onOpenRoute(
                            ClientRoutes.subscription,
                            {
                              'hasActiveSubscription':
                                  data.activePackage != null,
                            },
                          ),
                        ),
                        const SizedBox(height: ClientSpacing.xxl),
                        _TravelSupportCard(
                          onTap: () => onOpenRoute(ClientRoutes.support),
                        ),
                      ],
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
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.userName,
    required this.onOpenNotifications,
  });

  final String? userName;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final firstName = _firstName(userName);

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: ClientColors.primaryGradientFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.md),
            boxShadow: ClientElevation.sm(context),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()},',
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: 2),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingMedium(
                  context,
                ).copyWith(letterSpacing: -0.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _HeaderAction(
          tooltip: 'Notifications',
          icon: Icons.notifications_none_rounded,
          onTap: onOpenNotifications,
        ),
      ],
    );
  }

  static String _firstName(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty || cleaned.toLowerCase() == 'user') {
      return 'Welcome aboard';
    }
    return cleaned.split(RegExp(r'\s+')).first;
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ClientRadius.md),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ClientRadius.md),
              border: Border.all(color: ClientColors.borderFor(context)),
            ),
            child: Icon(
              icon,
              color: ClientColors.textPrimaryFor(context),
              size: 23,
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyPlannerCard extends StatelessWidget {
  const _JourneyPlannerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ClientColors.primaryGradientFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.sheet),
        boxShadow: ClientElevation.lg(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const PositionedDirectional(
            top: -52,
            end: -42,
            child: _DecorativeOrb(size: 150, opacity: 0.10),
          ),
          const PositionedDirectional(
            bottom: -46,
            start: -38,
            child: _DecorativeOrb(size: 118, opacity: 0.07),
          ),
          Padding(
            padding: const EdgeInsets.all(ClientSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(ClientRadius.pill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Colors.white,
                        size: 15,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'COMFORTABLE · RELIABLE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Where would you\nlike to go?',
                  style: ClientTypography.displayMedium(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.9,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find a route, choose your seat, and travel with ease.',
                  style: ClientTypography.bodyMedium(
                    context,
                  ).copyWith(color: Colors.white.withAlpha(215), height: 1.4),
                ),
                const SizedBox(height: 22),
                PressableScale(
                  onTap: onTap,
                  scale: 0.98,
                  child: Container(
                    minHeight: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: ClientColors.surfaceFor(context),
                      borderRadius: BorderRadius.circular(ClientRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(22),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ClientColors.primaryFor(
                              context,
                            ).withAlpha(18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: ClientColors.primaryFor(context),
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plan a journey',
                                style: ClientTypography.labelLarge(
                                  context,
                                ).copyWith(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'Pickup, destination, date and time',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ClientTypography.bodySmall(context)
                                    .copyWith(
                                      color: ClientColors.textSecondaryFor(
                                        context,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: ClientColors.primaryFor(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onRoutes,
    required this.onTrips,
    required this.onPackages,
    required this.onSupport,
  });

  final VoidCallback onRoutes;
  final VoidCallback onTrips;
  final VoidCallback onPackages;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.route_rounded,
        label: 'Routes',
        color: ClientColors.primaryFor(context),
        onTap: onRoutes,
      ),
      (
        icon: Icons.confirmation_number_outlined,
        label: 'My trips',
        color: ClientColors.journeyGreen,
        onTap: onTrips,
      ),
      (
        icon: Icons.card_membership_rounded,
        label: 'Packages',
        color: ClientColors.journeyPurple,
        onTap: onPackages,
      ),
      (
        icon: Icons.support_agent_rounded,
        label: 'Support',
        color: ClientColors.journeyAmber,
        onTap: onSupport,
      ),
    ];

    return Row(
      children: actions.indexed.map((entry) {
        return Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              end: entry.$1 == actions.length - 1 ? 0 : 8,
            ),
            child: _QuickActionTile(
              icon: entry.$2.icon,
              label: entry.$2.label,
              color: entry.$2.color,
              onTap: entry.$2.onTap,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(ClientRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClientRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClientRadius.md),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: ClientTypography.labelSmall(context).copyWith(
                  color: ClientColors.primaryFor(context),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 5),
              Text(title, style: ClientTypography.headingMedium(context)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _CurrentJourneyCard extends StatelessWidget {
  const _CurrentJourneyCard({required this.trip, required this.onTap});

  final HomeCurrentTripData trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = _isActive(trip.statusLabel);
    final statusColor = isActive
        ? ClientColors.journeyGreen
        : ClientColors.primaryFor(context);

    return Material(
      color: ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(ClientRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClientRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(ClientSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClientRadius.xl),
            border: Border.all(color: ClientColors.borderFor(context)),
            boxShadow: ClientElevation.md(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(18),
                      borderRadius: BorderRadius.circular(ClientRadius.md),
                    ),
                    child: Icon(
                      isActive
                          ? Icons.location_searching_rounded
                          : Icons.directions_bus_rounded,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive ? 'Trip in progress' : 'Upcoming trip',
                          style: ClientTypography.labelLarge(
                            context,
                          ).copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          trip.schedule,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(label: trip.statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 20),
              _JourneyEndpoints(
                pickup: trip.pickup,
                destination: trip.destination,
              ),
              if (trip.driverLine?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ClientColors.surfaceMutedFor(context),
                    borderRadius: BorderRadius.circular(ClientRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: ClientColors.textSecondaryFor(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip.driverLine!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(ClientRadius.md),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive
                          ? Icons.near_me_rounded
                          : Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isActive ? 'Track your bus' : 'View trip details',
                      style: ClientTypography.labelLarge(
                        context,
                      ).copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isActive(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('active') ||
        normalized.contains('progress') ||
        normalized.contains('boarding');
  }
}

class _JourneyEndpoints extends StatelessWidget {
  const _JourneyEndpoints({
    required this.pickup,
    required this.destination,
  });

  final String pickup;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _Endpoint(
            label: 'FROM',
            value: pickup,
            alignment: CrossAxisAlignment.start,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Icon(
                Icons.directions_bus_rounded,
                size: 20,
                color: ClientColors.primaryFor(context),
              ),
              const SizedBox(height: 5),
              Container(
                width: 58,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ClientColors.journeyGreen,
                      ClientColors.primaryFor(context),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _Endpoint(
            label: 'TO',
            value: destination,
            alignment: CrossAxisAlignment.end,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.label,
    required this.value,
    required this.alignment,
    this.textAlign = TextAlign.start,
  });

  final String label;
  final String value;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.textTertiaryFor(context),
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? 'Not set' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _DepartingSoonSection extends StatelessWidget {
  const _DepartingSoonSection({
    required this.trips,
    required this.onSelect,
  });

  final List<NearbyTripData> trips;
  final ValueChanged<NearbyTripData> onSelect;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= 720 ? 310.0 : (width - 48).clamp(270.0, 330.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionIntro(
          eyebrow: 'DEPARTING SOON',
          title: 'Trips near you',
          subtitle: 'Upcoming departures from live operations.',
        ),
        const SizedBox(height: ClientSpacing.md),
        SizedBox(
          height: 162,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: trips.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: ClientSpacing.sm),
            itemBuilder: (context, index) {
              final trip = trips[index];
              return _DepartureCard(
                width: cardWidth,
                trip: trip,
                onTap: () => onSelect(trip),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DepartureCard extends StatelessWidget {
  const _DepartureCard({
    required this.width,
    required this.trip,
    required this.onTap,
  });

  final double width;
  final NearbyTripData trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final seatColor = trip.seatsLeft <= 5
        ? ClientColors.journeyAmber
        : ClientColors.journeyGreen;

    return SizedBox(
      width: width,
      child: Material(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ClientRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(ClientSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ClientRadius.lg),
              border: Border.all(color: ClientColors.borderFor(context)),
              boxShadow: ClientElevation.sm(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ClientColors.primaryFor(context).withAlpha(18),
                        borderRadius: BorderRadius.circular(ClientRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: ClientColors.primaryFor(context),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            trip.departureTime,
                            style: ClientTypography.labelSmall(
                              context,
                            ).copyWith(
                              color: ClientColors.primaryFor(context),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (trip.isLive)
                      const _StatusPill(
                        label: 'Boarding',
                        color: ClientColors.journeyGreen,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.pickup,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClientTypography.headingSmall(context),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: ClientColors.textTertiaryFor(context),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        trip.destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: ClientTypography.headingSmall(context),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.event_seat_outlined,
                      size: 17,
                      color: seatColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${trip.seatsLeft.clamp(0, 999)} seats left',
                      style: ClientTypography.bodySmall(context).copyWith(
                        color: seatColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'View trip',
                      style: ClientTypography.labelSmall(context).copyWith(
                        color: ClientColors.primaryFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: ClientColors.primaryFor(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PackageInvitation extends StatelessWidget {
  const _PackageInvitation({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClientRadius.xl),
        child: Ink(
          padding: const EdgeInsets.all(ClientSpacing.lg),
          decoration: BoxDecoration(
            color: ClientColors.journeyPurple.withAlpha(
              Theme.of(context).brightness == Brightness.dark ? 32 : 14,
            ),
            borderRadius: BorderRadius.circular(ClientRadius.xl),
            border: Border.all(
              color: ClientColors.journeyPurple.withAlpha(55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ClientColors.journeyPurple,
                  borderRadius: BorderRadius.circular(ClientRadius.md),
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride more. Spend less.',
                      style: ClientTypography.headingSmall(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore flexible packages for your regular commute.',
                      style: ClientTypography.bodySmall(context).copyWith(
                        color: ClientColors.textSecondaryFor(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                color: ClientColors.journeyPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelSupportCard extends StatelessWidget {
  const _TravelSupportCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(ClientRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(ClientSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClientRadius.lg),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ClientColors.journeyGreen.withAlpha(18),
                  borderRadius: BorderRadius.circular(ClientRadius.md),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: ClientColors.journeyGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need help with your journey?',
                      style: ClientTypography.labelLarge(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Our support team is here when you need us.',
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ClientColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = AppLayout.maxContentWidth(width);

    return ColoredBox(
      color: ClientColors.backgroundFor(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: const EdgeInsets.all(ClientSpacing.md),
            children: const [
              SizedBox(height: 8),
              ClientSkeleton(height: 48, borderRadius: ClientRadius.md),
              SizedBox(height: 20),
              ClientSkeleton(height: 286, borderRadius: ClientRadius.sheet),
              SizedBox(height: 16),
              ClientSkeleton(height: 84, borderRadius: ClientRadius.md),
              SizedBox(height: 32),
              ClientSkeleton(height: 180, borderRadius: ClientRadius.xl),
              SizedBox(height: 32),
              ClientSkeleton(height: 210, borderRadius: ClientRadius.xl),
            ],
          ),
        ),
      ),
    );
  }
}
