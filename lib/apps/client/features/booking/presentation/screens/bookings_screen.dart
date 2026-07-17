import 'package:bmt_app/apps/client/features/packages/presentation/routes/packages_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_hub_data.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key, required this.onOpenRoute});

  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  BookingHubData? _data;

  @override
  void initState() {
    super.initState();
    context.read<BookingCubit>().loadBookingHubData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state is BookingHubLoaded) {
          _data = state.data;
        }

        if (state is BookingError && _data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                state.message,
                style: ClientTypography.bodyMedium(context),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = _data;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return _BookingHubContent(data: data, onOpenRoute: widget.onOpenRoute);
      },
    );
  }
}

class _BookingHubContent extends StatelessWidget {
  const _BookingHubContent({required this.data, required this.onOpenRoute});

  final BookingHubData data;
  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.booking_title,
                style: ClientTypography.headingLarge(context),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.booking_subtitle,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _BookingChip(
                      label: context.l10n.booking_today,
                      value: data.todayRoutes,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BookingChip(
                      label: context.l10n.booking_month,
                      value: data.monthPlans,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Daily booking option
        _NavCard(
          onTap: () => onOpenRoute(BookingRoutes.dailyBooking),
          icon: Icons.directions_bus_rounded,
          title: context.l10n.booking_dailyBooking,
          subtitle: context.l10n.booking_dailyBookingDesc,
        ),
        const SizedBox(height: 12),

        // Monthly subscription option
        _NavCard(
          onTap: () => onOpenRoute(PackagesRoutes.subscription),
          icon: Icons.calendar_month_rounded,
          title: context.l10n.booking_monthlySubscription,
          subtitle: context.l10n.booking_monthlySubscriptionDesc,
        ),
        const SizedBox(height: 20),

        Text(
          context.l10n.booking_summary,
          style: ClientTypography.headingSmall(context),
        ),
        const SizedBox(height: 12),

        // Metrics card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              _BookingMetric(
                label: context.l10n.booking_activeTrips,
                value: data.activeTrips,
              ),
              const SizedBox(height: 12),
              _BookingMetric(
                label: context.l10n.booking_upcomingBookings,
                value: data.upcomingBookings,
              ),
              const SizedBox(height: 12),
              _BookingMetric(
                label: context.l10n.booking_reservedSeats,
                value: data.reservedSeats,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ClientColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: ClientColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ClientTypography.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
              DirectionalIcon(
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

class _BookingChip extends StatelessWidget {
  const _BookingChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _BookingMetric extends StatelessWidget {
  const _BookingMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        Text(value, style: ClientTypography.headingSmall(context)),
      ],
    );
  }
}
