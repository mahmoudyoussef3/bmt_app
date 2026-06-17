import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_image_strip.dart';
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
      textDirection: TextDirection.ltr,
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
                  onPageChanged: (index) =>
                      setState(() => _galleryIndex = index),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _QuickStatsCard(vehicle: vehicle),
                        const SizedBox(height: 20),
                        _DetailSection(
                          title: AppLocalizations.of(
                            context,
                          )!.booking_comfortAndAmenities,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.booking_comfortDesc,
                          icon: Icons.airline_seat_recline_extra_rounded,
                          child: _ComfortCard(vehicle: vehicle),
                        ),
                        const SizedBox(height: 20),
                        _DetailSection(
                          title: AppLocalizations.of(context)!.booking_driver,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.booking_driverDesc,
                          icon: Icons.person_pin_circle_rounded,
                          child: _DriverCard(vehicle: vehicle),
                        ),
                        const SizedBox(height: 20),
                        _DetailSection(
                          title: AppLocalizations.of(
                            context,
                          )!.booking_priceAndAvailability,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.booking_priceDesc,
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
                  Text(
                    vehicle.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.headingLarge(context).copyWith(
                      color: ClientColors.textInverse,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vehicle.model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.bodyMedium(context).copyWith(
                      color: ClientColors.textInverse.withAlpha(220),
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

class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard({required this.vehicle});

  final dynamic vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
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
              icon: Icons.schedule_rounded,
              label: 'Departure',
              value: vehicle.departureTime,
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
    return Column(
      children: [
        Icon(icon, color: ClientColors.primary, size: 21),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(context).copyWith(
            color: ClientColors.textPrimaryFor(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: ClientTypography.bodySmall(context).copyWith(
            color: ClientColors.textSecondaryFor(context),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SoftIcon(icon: icon, color: ClientColors.primary, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ClientTypography.headingSmall(context).copyWith(
                      color: ClientColors.textPrimaryFor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: ClientTypography.bodySmall(context).copyWith(
                      color: ClientColors.textSecondaryFor(context),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
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
    return Row(
      children: [
        _SoftIcon(icon: icon, color: ClientColors.primary, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ClientTypography.bodySmall(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: ClientTypography.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: ClientColors.textPrimaryFor(context),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: [
          _ComfortTile(
            icon: Icons.ac_unit_rounded,
            label: AppLocalizations.of(context)!.booking_ac,
            value: vehicle.hasAirConditioning
                ? AppLocalizations.of(context)!.booking_available
                : AppLocalizations.of(context)!.booking_unavailable,
            positive: vehicle.hasAirConditioning,
          ),
          _ComfortTile(
            icon: Icons.chair_rounded,
            label: AppLocalizations.of(context)!.booking_seatType,
            value: vehicle.seatType,
            positive: true,
          ),
          _ComfortTile(
            icon: Icons.chair_rounded,
            label: AppLocalizations.of(context)!.booking_seatType,
            value: vehicle.seatType,
            positive: true,
          ),
        ],
      ),
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
    final color = positive
        ? ClientColors.journeyGreen
        : ClientColors.textTertiaryFor(context);

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
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: ClientColors.textPrimaryFor(context),
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
                color: ClientColors.primary,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.booking_legRoom,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
              ),
              Text(
                '$label (${rating.toStringAsFixed(1)}/5)',
                style: ClientTypography.bodySmall(context).copyWith(
                  color: ClientColors.primary,
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
              backgroundColor: ClientColors.borderFor(context),
              color: ClientColors.primary,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: ClientColors.primaryLight,
            child: Text(
              vehicle.driverInitials,
              style: ClientTypography.headingSmall(context).copyWith(
                color: ClientColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.driverName,
                  style: ClientTypography.headingSmall(context).copyWith(
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          ClientStatusBadge(
            status: ClientJourneyStatus.active,
            label: AppLocalizations.of(context)!.booking_certified,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PriceSeatColumn(
              label: AppLocalizations.of(context)!.booking_tripPrice,
              value: vehicle.price,
              icon: Icons.payments_rounded,
              color: ClientColors.primary,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _PriceSeatColumn(
              label: AppLocalizations.of(context)!.booking_availableSeats,
              value:
                  '${vehicle.availableSeats} ${AppLocalizations.of(context)!.booking_remaining}',
              icon: Icons.event_seat_rounded,
              color: ClientColors.journeyGreen,
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
          style: ClientTypography.bodySmall(context).copyWith(
            fontWeight: FontWeight.w700,
            color: ClientColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: ClientTypography.headingSmall(context).copyWith(
            color: ClientColors.textPrimaryFor(context),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          _SoftIcon(
            icon: Icons.route_rounded,
            color: ClientColors.primary,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملخص خط السير',
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  summary,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: ClientColors.textPrimaryFor(context),
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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          border: Border(
            top: BorderSide(color: ClientColors.borderFor(context)),
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
                    style: ClientTypography.priceMedium(context).copyWith(
                      color: ClientColors.textPrimaryFor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vehicle.availableSeats} مقاعد متاحة',
                    style: ClientTypography.bodySmall(context).copyWith(
                      color: ClientColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ClientButton(
                label: 'اختيار المقعد',
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/seat-selection',
                  arguments: {'tripId': vehicle.id},
                ),
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
          Icon(icon, color: ClientColors.textInverse, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: ClientColors.textInverse,
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
          Icon(icon, color: ClientColors.textInverse, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: ClientColors.textInverse,
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
      color: ClientColors.borderFor(context),
    );
  }
}

class _VehicleLoadingView extends StatelessWidget {
  const _VehicleLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _StaticVehicleAppBar(title: 'تفاصيل العربية'),
      body: Center(
        child: CircularProgressIndicator(color: ClientColors.primary),
      ),
    );
  }
}

class _VehicleErrorView extends StatelessWidget {
  const _VehicleErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _StaticVehicleAppBar(title: 'تفاصيل العربية'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ClientColors.borderFor(context)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: ClientColors.journeyRed,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  'لم نتمكن من تحميل تفاصيل العربية',
                  textAlign: TextAlign.center,
                  style: ClientTypography.headingSmall(context).copyWith(
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
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

class _VehicleEmptyView extends StatelessWidget {
  const _VehicleEmptyView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _StaticVehicleAppBar(title: 'تفاصيل العربية'),
      body: Center(
        child: Text(
          'لم يتم العثور على العربية',
          style: ClientTypography.bodyMedium(context).copyWith(
            color: ClientColors.textSecondaryFor(context),
          ),
        ),
      ),
    );
  }
}

class _StaticVehicleAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _StaticVehicleAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
