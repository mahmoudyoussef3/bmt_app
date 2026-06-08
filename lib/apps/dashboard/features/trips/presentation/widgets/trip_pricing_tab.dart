import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/operation_trip.dart';
import '../../domain/entities/trip_pricing.dart';
import '../cubit/trips_cubit.dart';
import '../cubit/trips_state.dart';
import 'trip_pricing_editor_dialog.dart';

class TripPricingTab extends StatelessWidget {
  final OperationTrip trip;
  final TripsLoaded state;

  const TripPricingTab({super.key, required this.trip, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.routePoints.first.name} ← ${trip.routePoints.last.name}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      '${trip.id} • ${trip.date} • ${trip.departure}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openEditor(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة تسعير جديد'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        _RouteTimeline(points: trip.routePoints),
        const SizedBox(height: AppSpacing.medium),
        if (state.pricingLoading)
          const Center(child: CircularProgressIndicator())
        else if (state.pricingError != null)
          Text(
            state.pricingError!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.error),
          )
        else if (state.selectedTripPricing.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Text(
              'لم يتم إعداد تسعير لهذه الرحلة بعد',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          )
        else
          _PricingCards(
            pricing: state.selectedTripPricing,
            onEdit: (pricing) => _openEditor(context, pricing),
            onToggle: context.read<TripsCubit>().toggleTripPricing,
          ),
      ],
    );
  }

  void _openEditor(BuildContext context, [TripPricing? pricing]) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<TripsCubit>(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: TripPricingEditorDialog(trip: trip, pricing: pricing),
        ),
      ),
    );
  }
}

class _RouteTimeline extends StatelessWidget {
  final List<TripRoutePoint> points;

  const _RouteTimeline({required this.points});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نقاط المسار', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.medium),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: points.map((point) {
                final isLast = point == points.last;
                return Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 112),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.small,
                        vertical: AppSpacing.xSmall,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withAlpha(80),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusSmall,
                        ),
                        border: Border.all(color: scheme.outline.withAlpha(90)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${point.order}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: scheme.primary),
                          ),
                          Text(point.name, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.small,
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCards extends StatelessWidget {
  final List<TripPricing> pricing;
  final ValueChanged<TripPricing> onEdit;
  final ValueChanged<TripPricing> onToggle;

  const _PricingCards({
    required this.pricing,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 3
            : constraints.maxWidth >= 760
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pricing.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 286,
          ),
          itemBuilder: (context, index) {
            return _PricingCard(
              pricing: pricing[index],
              onEdit: onEdit,
              onToggle: onToggle,
            );
          },
        );
      },
    );
  }
}

class _PricingCard extends StatelessWidget {
  final TripPricing pricing;
  final ValueChanged<TripPricing> onEdit;
  final ValueChanged<TripPricing> onToggle;

  const _PricingCard({
    required this.pricing,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${pricing.fromPointName} ← ${pricing.toPointName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip(label: pricing.isActive ? 'نشط' : 'غير نشط'),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _PriceRow(label: 'رحلة واحدة', value: pricing.oneTimePrice),
          _PriceRow(label: '٥ أيام', value: pricing.fiveDaysPrice),
          _PriceRow(label: '١٠ أيام شهريًا', value: pricing.tenDaysPrice),
          _PriceRow(label: 'شهري', value: pricing.monthlyPrice),
          _PriceRow(label: '٣ شهور', value: pricing.threeMonthsPrice),
          const Spacer(),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () => onEdit(pricing),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('تعديل'),
              ),
              const SizedBox(width: AppSpacing.small),
              TextButton(
                onPressed: () => onToggle(pricing),
                child: Text(pricing.isActive ? 'إيقاف' : 'تفعيل'),
              ),
              const Spacer(),
              Text(
                pricing.currency,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;

  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            '${_formatPrice(value)} ج.م',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

String _formatPrice(double value) {
  final intValue = value.round();
  return value == intValue ? '$intValue' : value.toStringAsFixed(2);
}
