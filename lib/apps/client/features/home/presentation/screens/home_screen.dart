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
import 'package:bmt_app/core/widgets/app_dialogs.dart';

import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

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
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxW = AppLayout.maxContentWidth(width);
    final isTablet = width >= 720;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().load(),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? AppLayout.spaceXl : AppLayout.spaceLg,
                    AppLayout.spaceXl + 24, // Top padding
                    isTablet ? AppLayout.spaceXl : AppLayout.spaceLg,
                    40,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _CleanHeader(
                        userName: widget.data.userName,
                        onOpenNotifications: widget.onOpenNotifications,
                      ),
                      const SizedBox(height: 32),
                      _CleanSearchBar(onTap: widget.onOpenSearch),
                      const SizedBox(height: 40),
                      
                      if (widget.data.currentTrip != null) ...[
                        _ActiveTripCard(
                          trip: widget.data.currentTrip!,
                          onTap: () => widget.onOpenRoute(ClientRoutes.tracking, {
                            'bookingId': widget.data.currentTrip!.id,
                          }),
                        ),
                        const SizedBox(height: 40),
                      ],

                      PopularRoutesPreview(
                        routes: widget.data.popularRoutes,
                        previewCount: isTablet ? 4 : 3,
                        onOpenRoute: widget.onOpenRoute,
                      ),
                      const SizedBox(height: 40),
                      
                      if (widget.data.activePackage == null) ...[
                        _CleanSubscriptionPromo(
                          onTap: () => widget.onOpenRoute(
                            ClientRoutes.subscription,
                            {'hasActiveSubscription': false},
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      HomePackagesSection(
                        plans: widget.data.packagePlans,
                        activePackage: widget.data.activePackage,
                        previewCount: 4,
                        onOpenSubscription: () =>
                            widget.onOpenRoute(ClientRoutes.subscription, {
                              'hasActiveSubscription':
                                  widget.data.activePackage != null,
                            }),
                      ),
                      const SizedBox(height: 48),
                      
                      _SupportLink(
                        scheme: scheme,
                        onTap: () => widget.onOpenRoute(ClientRoutes.support),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CleanHeader extends StatelessWidget {
  const _CleanHeader({required this.userName, required this.onOpenNotifications});

  final String? userName;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = _firstName(userName);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface.withAlpha(160),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                firstName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Material(
          color: isDark ? scheme.surfaceContainerHighest : scheme.surfaceContainer,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onOpenNotifications,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.notifications_outlined, color: scheme.onSurface, size: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  static String _firstName(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty || cleaned.toLowerCase() == 'user') {
      return 'Guest';
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

class _CleanSearchBar extends StatelessWidget {
  const _CleanSearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerHighest : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(ClientRadius.md),
          border: Border.all(
            color: isDark ? scheme.outline.withAlpha(40) : scheme.outline.withAlpha(60),
          ),
          boxShadow: ClientElevation.sm(context),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: scheme.onSurface.withAlpha(150), size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where to?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Search routes, cities, or stations',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withAlpha(140),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.trip, required this.onTap});

  final HomeCurrentTripData trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final isActive = trip.statusLabel.toLowerCase().contains('active') ||
                     trip.statusLabel.toLowerCase().contains('progress');
                     
    final accentColor = isActive ? const Color(0xFF10B981) : scheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: accentColor.withAlpha(40),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        trip.statusLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Icon(Icons.directions_bus_rounded, color: Colors.white.withAlpha(200), size: 24),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  trip.routeLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.white.withAlpha(200), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      trip.schedule,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha(220),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isActive ? 'Track Live Location' : 'View Trip Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CleanSubscriptionPromo extends StatelessWidget {
  const _CleanSubscriptionPromo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? scheme.outline.withAlpha(40) : scheme.outline.withAlpha(60),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Ride Packages',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unlock frequent savings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Save up to 30% on your daily commute.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withAlpha(160),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: scheme.primary.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_activity_rounded, color: scheme.primary, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportLink extends StatelessWidget {
  const _SupportLink({required this.scheme, required this.onTap});

  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.help_outline_rounded, size: 20, color: scheme.onSurface.withAlpha(140)),
        label: Text(
          'Help & Support',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.onSurface.withAlpha(160),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    final maxW = AppLayout.maxContentWidth(width);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.spaceLg),
          children: const [
            SizedBox(height: 40),
            ClientSkeleton(height: 50, borderRadius: 12),
            SizedBox(height: 32),
            ClientSkeleton(height: 80, borderRadius: 16),
            SizedBox(height: 40),
            ClientSkeleton(height: 220, borderRadius: 20),
            SizedBox(height: 40),
            ClientSkeleton(height: 200, borderRadius: 20),
          ],
        ),
      ),
    );
  }
}
