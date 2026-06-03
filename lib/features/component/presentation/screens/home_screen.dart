import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/home_mock_data.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/nearby_trip_card.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/package_plan_card.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/popular_route_card.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/promo_banner.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_routes.dart';
import 'package:bmt_app/features/component/presentation/trips/trips_routes.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_query.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/search_trip_card.dart';

class HomeScreen extends StatefulWidget {
  final void Function(String route, [Object? arguments]) onOpenRoute;

  const HomeScreen({super.key, required this.onOpenRoute});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _pickup = '';
  String _destination = '';
  String _date = 'Today, Jun 3';
  String _time = '';

  Future<void> _pickLocation({
    required String title,
    required List<String> options,
    required void Function(String) onSelected,
    String? current,
  }) async {
    final value = await showHomePickerSheet(
      context: context,
      title: title,
      options: options,
      selected: current?.isEmpty == true ? null : current,
    );
    if (value != null) {
      setState(() => onSelected(value));
    }
  }

  void _pickDate() async {
    final value = await showHomePickerSheet(
      context: context,
      title: 'Select date',
      options: const ['Today, Jun 3', 'Tomorrow, Jun 4', 'Fri, Jun 5'],
      selected: _date,
    );
    if (value != null) setState(() => _date = value);
  }

  void _pickTime() async {
    final value = await showHomePickerSheet(
      context: context,
      title: 'Select time',
      options: kTimeSuggestions,
      selected: _time.isEmpty ? null : _time,
    );
    if (value != null) setState(() => _time = value);
  }

  BookingSearchQuery get _searchQuery => BookingSearchQuery(
    pickup: _pickup,
    destination: _destination,
    date: _date,
    time: _time,
  );

  void _onSearchTrips() {
    final query = _searchQuery;
    if (!query.isComplete) {
      widget.onOpenRoute(BookingRoutes.search, query.toArguments());
      return;
    }
    widget.onOpenRoute(BookingRoutes.routeSelection, query.toArguments());
  }

  void _openBookingSearch() {
    widget.onOpenRoute(BookingRoutes.search, _searchQuery.toArguments());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _HomeGreetingHeader(scheme: scheme)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SearchTripCard(
                pickup: _pickup,
                destination: _destination,
                date: _date,
                time: _time,
                onPickupTap: () => _pickLocation(
                  title: 'Pickup location',
                  options: kPickupSuggestions,
                  current: _pickup,
                  onSelected: (v) => _pickup = v,
                ),
                onDestinationTap: () => _pickLocation(
                  title: 'Destination',
                  options: kDestinationSuggestions,
                  current: _destination,
                  onSelected: (v) => _destination = v,
                ),
                onDateTap: _pickDate,
                onTimeTap: _pickTime,
                onSearch: _onSearchTrips,
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Popular Routes',
                subtitle: 'Frequent commutes from your area',
                action: TextButton(
                  onPressed: () =>
                      widget.onOpenRoute(BookingRoutes.popularRoutes),
                  child: const Text('See all'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kPopularRoutes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return PopularRouteCard(
                      route: kPopularRoutes[index],
                      onTap: () {
                        final route = kPopularRoutes[index];
                        final query = _searchQuery.copyWith(
                          pickup: route.pickup,
                          destination: route.destination,
                        );
                        setState(() {
                          _pickup = route.pickup;
                          _destination = route.destination;
                        });
                        widget.onOpenRoute(
                          BookingRoutes.routeSelection,
                          query.toArguments(),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Nearby Trips',
                subtitle: 'Active routes departing soon',
              ),
              const SizedBox(height: 12),
              ...kNearbyTrips.map(
                (trip) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NearbyTripCard(
                    trip: trip,
                    onTap: () => widget.onOpenRoute(
                      BookingRoutes.vehicleListing,
                      _searchQuery.toArguments(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _openBookingSearch,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open full search'),
                ),
              ),
              const SizedBox(height: 24),
              PromoBanner(onTap: () => widget.onOpenRoute('/subscription')),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Package Booking',
                subtitle: 'Save more with commute bundles',
                action: TextButton(
                  onPressed: () => widget.onOpenRoute('/subscription'),
                  child: const Text('Compare'),
                ),
              ),
              const SizedBox(height: 12),
              ...kPackagePlans.asMap().entries.map((entry) {
                final index = entry.key;
                final plan = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PackagePlanCard(
                    plan: plan,
                    highlighted: index == kPackagePlans.length - 1,
                    onTap: () => widget.onOpenRoute('/subscription'),
                  ),
                );
              }),
              const SizedBox(height: 20),
              SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      title: 'Search Trip',
                      icon: Icons.search_rounded,
                      color: scheme.primary,
                      onTap: _openBookingSearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAction(
                      title: 'Track Vehicle',
                      icon: Icons.map_rounded,
                      color: scheme.tertiary,
                      onTap: () => widget.onOpenRoute('/tracking'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAction(
                      title: 'My Trips',
                      icon: Icons.luggage_rounded,
                      color: scheme.secondary,
                      onTap: () => widget.onOpenRoute(TripsRoutes.myTrips),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAction(
                      title: 'Support',
                      icon: Icons.support_agent_rounded,
                      color: scheme.error,
                      onTap: () => widget.onOpenRoute('/support'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      title: 'Chat Hub',
                      icon: Icons.chat_bubble_outline_rounded,
                      color: Colors.teal,
                      onTap: () => widget.onOpenRoute('/communication'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAction(
                      title: 'Payments',
                      icon: Icons.payment_rounded,
                      color: Colors.amber,
                      onTap: () => widget.onOpenRoute('/payment-demo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HomeGreetingHeader extends StatelessWidget {
  const _HomeGreetingHeader({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withAlpha(82),
              scheme.secondary.withAlpha(28),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: scheme.outline.withAlpha(110)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Book your trip',
                    style: AppTextThemes.headlineStrong(
                      scheme,
                    ).copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search, compare routes, and reserve your seat',
                    style: AppTextThemes.caption(
                      scheme,
                    ).copyWith(color: scheme.onSurface.withAlpha(180)),
                  ),
                ],
              ),
            ),
            const AppAvatar(initials: 'AH', radius: 26),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
