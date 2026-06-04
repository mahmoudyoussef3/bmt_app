import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/features/component/presentation/screens/notifications_screen.dart';
import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_routes.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_query.dart';
import 'package:bmt_app/features/component/presentation/trips/trips_routes.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/home_mock_data.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/popular_routes_preview.dart';
import 'package:bmt_app/features/component/presentation/widgets/ui/home_hero_trip_panel.dart';
import 'package:bmt_app/features/component/presentation/widgets/ui/home_packages_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenRoute});

  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BookingSearchQuery get _searchQuery => const BookingSearchQuery(
    pickup: 'Banha Station',
    destination: 'Smart Village',
    date: 'Today, Jun 3',
    time: '8:40 AM',
  );

  void _openSearch() {
    widget.onOpenRoute(BookingRoutes.search, _searchQuery.toArguments());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final maxW = AppLayout.maxContentWidth(width);
    final currentTrip = kHomeCurrentTrip;
    final hasTrip = currentTrip != null;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppLayout.spaceLg,
                  AppLayout.spaceLg,
                  AppLayout.spaceLg,
                  AppLayout.spaceSm,
                ),
                child: _HomeHero(
                  scheme: scheme,
                  hasTrip: hasTrip,
                  currentTrip: currentTrip,
                  onBookTrip: _openSearch,
                  onViewTrip: () => widget.onOpenRoute(
                    TripsRoutes.tripDetails,
                    {'tripId': 'T1'},
                  ),
                  onTrackTrip: () => widget.onOpenRoute('/tracking'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.spaceLg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  PopularRoutesPreview(onOpenRoute: widget.onOpenRoute),
                  const SizedBox(height: AppLayout.spaceXxl),
                  HomePackagesSection(
                    onOpenSubscription: () =>
                        widget.onOpenRoute('/subscription'),
                  ),
                  const SizedBox(height: AppLayout.spaceXxl),
                  _SupportLink(
                    scheme: scheme,
                    onTap: () => widget.onOpenRoute('/support'),
                  ),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.scheme,
    required this.hasTrip,
    required this.currentTrip,
    required this.onBookTrip,
    required this.onViewTrip,
    required this.onTrackTrip,
  });

  final ColorScheme scheme;
  final bool hasTrip;
  final HomeCurrentTripData? currentTrip;
  final VoidCallback onBookTrip;
  final VoidCallback onViewTrip;
  final VoidCallback onTrackTrip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLayout.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withAlpha(hasTrip ? 62 : 48),
            scheme.surfaceContainerHighest.withAlpha(130),
          ],
        ),
        border: Border.all(color: scheme.outline.withAlpha(70)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(20),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning, Ahmed',
                        style: AppTypography.caption(scheme).copyWith(
                          color: scheme.onSurface.withAlpha(190),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: AppLayout.spaceXs),
                      Text(
                        hasTrip ? 'Your trip today' : 'Ready for your commute?',
                        style: AppTypography.display(
                          scheme,
                        ).copyWith(fontSize: 24, height: 1.15),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: scheme.primary,
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.cardDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.spaceLg),
            HomeHeroTripPanel(
              scheme: scheme,
              trip: currentTrip,
              onBookTrip: onBookTrip,
              onViewTrip: onViewTrip,
              onTrackTrip: onTrackTrip,
            ),
          ],
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
              'Need help? Contact support',
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
