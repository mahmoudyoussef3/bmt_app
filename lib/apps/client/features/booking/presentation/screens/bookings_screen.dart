import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_hub_data.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

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
                style: Theme.of(context).textTheme.bodyMedium,
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
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.booking_title, style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.booking_subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withAlpha(175),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _BookingChip(
                      label: AppLocalizations.of(context)!.booking_today,
                      value: data.todayRoutes,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BookingChip(label: AppLocalizations.of(context)!.booking_month, value: data.monthPlans),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          onTap: () => onOpenRoute('/daily-booking'),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.booking_dailyBooking,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.booking_dailyBookingDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(165),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => onOpenRoute('/subscription'),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withAlpha(26),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.booking_monthlySubscription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.booking_monthlySubscriptionDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(165),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(AppLocalizations.of(context)!.booking_summary, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _BookingMetric(label: AppLocalizations.of(context)!.booking_activeTrips, value: data.activeTrips),
              const SizedBox(height: 12),
              _BookingMetric(
                label: AppLocalizations.of(context)!.booking_upcomingBookings,
                value: data.upcomingBookings,
              ),
              const SizedBox(height: 12),
              _BookingMetric(
                label: AppLocalizations.of(context)!.booking_reservedSeats,
                value: data.reservedSeats,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingChip extends StatelessWidget {
  const _BookingChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.onSurface.withAlpha(160),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
