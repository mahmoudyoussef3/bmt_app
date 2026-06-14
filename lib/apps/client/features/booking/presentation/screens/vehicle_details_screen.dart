import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_image_strip.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Full vehicle profile for informed booking decisions.
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) {
          if (state is BookingLoading) {
            return const _VehicleLoadingView();
          }

          if (state is BookingError) {
            return _VehicleErrorView(message: state.message);
          }

          final vehicle = state is VehicleDetailsLoaded ? state.vehicle : null;
          if (vehicle == null) {
            return const _VehicleEmptyView();
          }

          final query = bookingQueryFromContext(context);

          return Scaffold(
            extendBody: true,
            body: CustomScrollView(
              slivers: [
                _VehicleGalleryAppBar(
                  vehicle: vehicle,
                  galleryController: _galleryController,
                  galleryIndex: _galleryIndex,
                  onPageChanged: (index) => setState(() => _galleryIndex = index),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    //    _VehicleSummaryCard(vehicle: vehicle),
                      //  const SizedBox(height: 16),
                        _QuickStatsCard(vehicle: vehicle),
                        const SizedBox(height: 20),
                    
                        _DetailSection(
                          title: AppLocalizations.of(context)!.booking_comfortAndAmenities,
                          subtitle: AppLocalizations.of(context)!.booking_comfortDesc,
                          icon: Icons.airline_seat_recline_extra_rounded,
                          child: _ComfortCard(vehicle: vehicle),
                        ),
                        const SizedBox(height: 20),
                        _DetailSection(
                          title: AppLocalizations.of(context)!.booking_driver,
                          subtitle: AppLocalizations.of(context)!.booking_driverDesc,
                          icon: Icons.person_pin_circle_rounded,
                          child: _DriverCard(vehicle: vehicle),
                        ),
                        const SizedBox(height: 20),
                        _DetailSection(
                          title: AppLocalizations.of(context)!.booking_priceAndAvailability,
                          subtitle: AppLocalizations.of(context)!.booking_priceDesc,
                          icon: Icons.payments_rounded,
                          child: _PricingAvailabilityCard(vehicle: vehicle),
                        ),
                        if (query.isComplete) ...[
                          const SizedBox(height: 14),
                          _RouteSummaryCard(summary: query.summaryLine),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _VehicleBottomBar(vehicle: vehicle),
          );
        },
      ),
    );
  }
}

class _VehicleGalleryAppBar extends StatelessWidget {
  const _VehicleGalleryAppBar({
    required this.vehicle,
    required this.galleryController,
    required this.galleryIndex,
    required this.onPageChanged,
  });

  final dynamic vehicle;
  final PageController galleryController;
  final int galleryIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 310,
      pinned: true,
      stretch: true,
      title: Text(AppLocalizations.of(context)!.booking_vehicleDetails),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            VehicleImageStrip(
              labels: vehicle.imageLabels,
              height: 310,
              pageController: galleryController,
              onPageChanged: onPageChanged,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(95),
                    Colors.black.withAlpha(10),
                    Colors.black.withAlpha(160),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: 16,
              end: 16,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vehicle.isRecommended) ...[
                    _WhitePill(
                      icon: Icons.auto_awesome_rounded,
                      label: AppLocalizations.of(context)!.booking_recommendedForYou,
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    vehicle.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vehicle.model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withAlpha(220),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  VehicleImageDots(
                    count: vehicle.imageLabels.length,
                    index: galleryIndex,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*class _VehicleSummaryCard extends StatelessWidget {
  const _VehicleSummaryCard({required this.vehicle});

  final dynamic vehicle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            scheme.primary,
            scheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(45),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -32,
            end: -20,
            child: Icon(
              Icons.directions_bus_filled_rounded,
              size: 132,
              color: Colors.white.withAlpha(28),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WhitePill(
                icon: Icons.verified_rounded,
                label: vehicle.vehicleType,
              ),
              const SizedBox(height: 16),
              Text(
                'اختيار مناسب لرحلتك',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'راجع تفاصيل العربية، مستوى الراحة، تقييم السائق، وعدد المقاعد قبل تأكيد الحجز.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withAlpha(225),
                      height: 1.7,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroInfoChip(
                    icon: Icons.event_seat_rounded,
                    label: '${vehicle.availableSeats} مقاعد متاحة',
                  ),
                  _HeroInfoChip(
                    icon: Icons.star_rounded,
                    label: vehicle.driverRating.toStringAsFixed(1),
                  ),
                  _HeroInfoChip(
                    icon: Icons.payments_rounded,
                    label: vehicle.price,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

*/

class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard({required this.vehicle});

  final dynamic vehicle;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: _QuickStat(
              icon: Icons.payments_rounded,
              label: AppLocalizations.of(context)!.booking_tripPrice,
              value: vehicle.price,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _QuickStat(
              icon: Icons.event_seat_rounded,
              label: AppLocalizations.of(context)!.booking_availableSeats,
              value: '${vehicle.availableSeats}',
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _QuickStat(
              icon: Icons.star_rounded,
              label: AppLocalizations.of(context)!.booking_sortRating,
              value: vehicle.driverRating.toStringAsFixed(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: scheme.primary, size: 21),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withAlpha(150),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
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
            _SoftIcon(icon: icon, color: scheme.primary, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextThemes.subtitle(scheme),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withAlpha(150),
                        ),
                  ),
                ],
              ),
            ),
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
        children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i != items.length - 1) const Divider(height: 22),
          ],
        ],
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
        _SoftIcon(icon: icon, color: scheme.primary, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(145),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComfortCard extends StatelessWidget {
  const _ComfortCard({required this.vehicle});

  final dynamic vehicle;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ComfortTile(
            icon: Icons.ac_unit_rounded,
            label: AppLocalizations.of(context)!.booking_ac,
            value: vehicle.hasAirConditioning ? AppLocalizations.of(context)!.booking_available : AppLocalizations.of(context)!.booking_unavailable,
            positive: vehicle.hasAirConditioning,
          ),
          _ComfortTile(
            icon: Icons.chair_rounded,
            label: AppLocalizations.of(context)!.booking_seatType,
            value: vehicle.seatType,
            positive: true,
          ),
          _ComfortTile(
            icon: Icons.airline_seat_recline_normal_rounded,
            label: AppLocalizations.of(context)!.booking_recliningSeats,
            value: vehicle.hasRecliningSeats ? AppLocalizations.of(context)!.common_yes : AppLocalizations.of(context)!.common_no,
            positive: vehicle.hasRecliningSeats,
          ),
          _LegRoomTile(rating: vehicle.legRoomRating),
          _ComfortTile(
            icon: Icons.build_circle_outlined,
            label: AppLocalizations.of(context)!.booking_vehicleCondition,
            value: _vehicleConditionLabel(context, vehicle.vehicleCondition),
            positive: vehicle.vehicleCondition == 'Excellent',
          ),
        ],
      ),
    );
  }

  String _vehicleConditionLabel(BuildContext context, String condition) {
    return switch (condition) {
      'Excellent' => AppLocalizations.of(context)!.booking_ratingExcellent,
      'Very good' => AppLocalizations.of(context)!.booking_ratingVeryGood,
      'Good' => AppLocalizations.of(context)!.booking_ratingGood,
      _ => condition,
    };
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
    final color = positive ? scheme.secondary : scheme.onSurface.withAlpha(130);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _SoftIcon(icon: icon, color: color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(145),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            positive ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: color,
            size: 21,
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
        ? AppLocalizations.of(context)!.booking_ratingExcellent
        : rating >= 3.5
            ? AppLocalizations.of(context)!.booking_ratingVeryGood
            : rating >= 2.5
                ? AppLocalizations.of(context)!.booking_ratingGood
                : AppLocalizations.of(context)!.booking_ratingNormal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SoftIcon(
                icon: Icons.straighten_rounded,
                color: scheme.primary,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.booking_legRoom,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                '$label (${rating.toStringAsFixed(1)}/5)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (rating / 5).clamp(0, 1),
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

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.vehicle});

  final dynamic vehicle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(initials: vehicle.driverInitials, radius: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.driverName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled = i < vehicle.driverRating.floor();
                          return Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 18,
                            color: scheme.tertiary,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          vehicle.driverRating.toStringAsFixed(2),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${vehicle.completedTrips} ${AppLocalizations.of(context)!.booking_completedTrips} · ${vehicle.yearsExperience} ${AppLocalizations.of(context)!.booking_yearsExperience}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withAlpha(170),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              StatusChip(label: AppLocalizations.of(context)!.booking_certified),
            ],
          ),
        ],
      ),
    );
  }
}

class _PricingAvailabilityCard extends StatelessWidget {
  const _PricingAvailabilityCard({required this.vehicle});

  final dynamic vehicle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _PriceSeatColumn(
              label: AppLocalizations.of(context)!.booking_tripPrice,
              value: vehicle.price,
              icon: Icons.payments_rounded,
              color: scheme.primary,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _PriceSeatColumn(
              label: AppLocalizations.of(context)!.booking_availableSeats,
              value: '${vehicle.availableSeats} ${AppLocalizations.of(context)!.booking_remaining}',
              icon: Icons.event_seat_rounded,
              color: scheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSeatColumn extends StatelessWidget {
  const _PriceSeatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SoftIcon(icon: icon, color: color, size: 42),
        const SizedBox(height: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(145),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _SoftIcon(icon: Icons.route_rounded, color: scheme.primary, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملخص خط السير',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(145),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
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

class _VehicleBottomBar extends StatelessWidget {
  const _VehicleBottomBar({required this.vehicle});

  final dynamic vehicle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withAlpha(245),
          border: Border(
            top: BorderSide(color: scheme.outline.withAlpha(80)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(16),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.price,
                    style: AppTextThemes.priceEmphasis(scheme).copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vehicle.availableSeats} مقاعد متاحة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppButton(
                label: 'اختيار المقعد',
                height: 52,
                onPressed: () => Navigator.pushNamed(context, '/seat-selection', arguments: {'tripId': vehicle.id}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhitePill extends StatelessWidget {
  const _WhitePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroInfoChip extends StatelessWidget {
  const _HeroInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(34),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon, required this.color, this.size = 44});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).colorScheme.outline.withAlpha(90),
    );
  }
}

class _VehicleLoadingView extends StatelessWidget {
  const _VehicleLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _StaticVehicleAppBar(title: 'تفاصيل العربية'),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _VehicleErrorView extends StatelessWidget {
  const _VehicleErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const _StaticVehicleAppBar(title: 'تفاصيل العربية'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppSurface(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: scheme.error, size: 44),
                const SizedBox(height: 12),
                Text(
                  'لم نتمكن من تحميل تفاصيل العربية',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleEmptyView extends StatelessWidget {
  const _VehicleEmptyView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _StaticVehicleAppBar(title: 'تفاصيل العربية'),
      body: Center(child: Text('لم يتم العثور على العربية')),
    );
  }
}

class _StaticVehicleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _StaticVehicleAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
