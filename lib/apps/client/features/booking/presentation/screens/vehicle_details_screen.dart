import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_image_strip.dart';

/// Full vehicle profile for informed booking decisions (UI only).
class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key, this.vehicleId});

  final String? vehicleId;

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late final PageController _galleryController;
  int _galleryIndex = 0;
  String? _vehicleId;

  @override
  void initState() {
    super.initState();
    _galleryController = PageController();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vehicleId = _resolveVehicleId(context);
    if (_vehicleId == vehicleId) return;
    _vehicleId = vehicleId;
    context.read<BookingCubit>().loadVehicleDetails(_vehicleId);
  }

  String? _resolveVehicleId(BuildContext context) {
    if (widget.vehicleId != null) return widget.vehicleId;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      return args['vehicleId']?.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Vehicle Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is BookingError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Vehicle Details')),
            body: Center(child: Text(state.message)),
          );
        }

        final vehicle = state is VehicleDetailsLoaded ? state.vehicle : null;
        if (vehicle == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Vehicle Details')),
            body: const Center(child: Text('Vehicle not found')),
          );
        }

        final scheme = Theme.of(context).colorScheme;
        final query = bookingQueryFromContext(context);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      VehicleImageStrip(
                        labels: vehicle.imageLabels,
                        height: 260,
                        pageController: _galleryController,
                        onPageChanged: (i) => setState(() => _galleryIndex = i),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(80),
                              Colors.transparent,
                              Colors.black.withAlpha(120),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      VehicleImageDots(
                        count: vehicle.imageLabels.length,
                        index: _galleryIndex,
                      ),
                      const SizedBox(height: 16),
                      if (vehicle.isRecommended) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: AppBadge(text: 'Recommended for you'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        vehicle.name,
                        style: AppTextThemes.headlineStrong(scheme),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vehicle.model,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusChip(label: vehicle.vehicleType),
                          StatusChip(label: 'ID ${vehicle.id}'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _DetailSection(
                        title: 'Vehicle information',
                        icon: Icons.directions_bus_filled_rounded,
                        child: _InfoGrid(
                          items: [
                            _InfoItem(
                              label: 'Vehicle name',
                              value: vehicle.name,
                              icon: Icons.badge_outlined,
                            ),
                            _InfoItem(
                              label: 'Model',
                              value: vehicle.model,
                              icon: Icons.precision_manufacturing_outlined,
                            ),
                            _InfoItem(
                              label: 'Type',
                              value: vehicle.vehicleType,
                              icon: Icons.category_outlined,
                            ),
                            _InfoItem(
                              label: 'Images',
                              value: '${vehicle.imageLabels.length} photos',
                              icon: Icons.photo_library_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DetailSection(
                        title: 'Comfort',
                        icon: Icons.airline_seat_recline_extra_rounded,
                        child: Column(
                          children: [
                            _ComfortTile(
                              icon: Icons.ac_unit_rounded,
                              label: 'Air conditioning',
                              value: vehicle.hasAirConditioning
                                  ? 'Available'
                                  : 'Not available',
                              positive: vehicle.hasAirConditioning,
                            ),
                            _ComfortTile(
                              icon: Icons.chair_rounded,
                              label: 'Seat type',
                              value: vehicle.seatType,
                              positive: true,
                            ),
                            _ComfortTile(
                              icon: Icons.airline_seat_recline_normal_rounded,
                              label: 'Reclining seats',
                              value: vehicle.hasRecliningSeats ? 'Yes' : 'No',
                              positive: vehicle.hasRecliningSeats,
                            ),
                            _LegRoomTile(rating: vehicle.legRoomRating),
                            _ComfortTile(
                              icon: Icons.build_circle_outlined,
                              label: 'Vehicle condition',
                              value: vehicle.vehicleCondition,
                              positive: vehicle.vehicleCondition == 'Excellent',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DetailSection(
                        title: 'Driver',
                        icon: Icons.person_rounded,
                        child: AppSurface(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              AppAvatar(
                                initials: vehicle.driverInitials,
                                radius: 28,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicle.driverName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        ...List.generate(5, (i) {
                                          final filled =
                                              i < vehicle.driverRating.floor();
                                          return Icon(
                                            filled
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            size: 18,
                                            color: scheme.tertiary,
                                          );
                                        }),
                                        const SizedBox(width: 8),
                                        Text(
                                          vehicle.driverRating.toStringAsFixed(
                                            2,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${vehicle.completedTrips} completed trips · '
                                      '${vehicle.yearsExperience} years experience',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurface.withAlpha(
                                              170,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DetailSection(
                        title: 'Pricing & availability',
                        icon: Icons.payments_rounded,
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Trip fare',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      vehicle.price,
                                      style: AppTextThemes.priceEmphasis(
                                        scheme,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 48,
                                color: scheme.outline.withAlpha(100),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Available seats',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${vehicle.availableSeats} remaining',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (query.isComplete) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Route: ${query.summaryLine}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurface.withAlpha(160),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.price,
                          style: AppTextThemes.priceEmphasis(
                            scheme,
                          ).copyWith(fontSize: 20),
                        ),
                        Text(
                          '${vehicle.availableSeats} seats available',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'Book This Vehicle',
                      height: 52,
                      onPressed: () {
                        Navigator.pushNamed(context, '/seat-selection');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(title, style: AppTextThemes.subtitle(scheme)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: item,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComfortTile extends StatelessWidget {
  const _ComfortTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.positive,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (positive ? scheme.secondary : scheme.outline).withAlpha(
                36,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: positive
                  ? scheme.secondary
                  : scheme.onSurface.withAlpha(140),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Icon(
            positive ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: positive
                ? scheme.secondary
                : scheme.onSurface.withAlpha(120),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _LegRoomTile extends StatelessWidget {
  const _LegRoomTile({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = rating >= 4.5
        ? 'Excellent'
        : rating >= 3.5
        ? 'Very good'
        : rating >= 2.5
        ? 'Good'
        : 'Standard';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 12),
              Text(
                'Leg room rating',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              Text(
                '$label (${rating.toStringAsFixed(1)}/5)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rating / 5,
              minHeight: 8,
              backgroundColor: scheme.outline.withAlpha(80),
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
