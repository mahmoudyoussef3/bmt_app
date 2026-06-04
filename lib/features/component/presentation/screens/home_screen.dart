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
                  AppLayout.spaceXl, // Spacious bottom padding before next section
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HomeHeader(scheme: scheme),
                    const SizedBox(height: AppLayout.spaceLg),
                    HomeHeroTripPanel(
                      scheme: scheme,
                      trip: currentTrip,
                      onBookTrip: _openSearch,
                      onViewTrip: () => widget.onOpenRoute(
                        TripsRoutes.tripDetails,
                        {'tripId': 'T1'},
                      ),
                      onTrackTrip: () => widget.onOpenRoute('/tracking'),
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
                  PopularRoutesPreview(onOpenRoute: widget.onOpenRoute),
                  const SizedBox(height: AppLayout.spaceXl),
                  HomePackagesSection(
                    onOpenSubscription: () =>
                        widget.onOpenRoute('/subscription'),
                  ),
                  const SizedBox(height: AppLayout.spaceXl),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.scheme});

  final ColorScheme scheme;

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
                'Good morning, Ahmed 👋',
                style: AppTypography.display(scheme).copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ready for your commute today?',
                style: AppTypography.caption(scheme).copyWith(
                  color: scheme.onSurface.withAlpha(150),
                  fontSize: 13.5,
                ),
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
