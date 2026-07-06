import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import '../models/booking_filters.dart';

/// Status tabs + quick filters. Priority filtering was removed because the
/// concept has no backing column in `operation_bookings`.
class BookingsToolbar extends StatelessWidget {
  const BookingsToolbar({super.key, required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusTabs(state: state, cubit: cubit),
          const SizedBox(height: AppSpacing.medium),
          _FiltersBar(filters: state.filters, onChanged: cubit.updateFilters),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({required this.state, required this.cubit});

  final BookingsLoaded state;
  final BookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: BookingStatus.values.map((status) {
          final selected = state.activeTab == status;
          final count = state.countByStatus(status);
          final label = '${status.label}  $count';
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.small),
            child: selected
                ? FilledButton(
                    onPressed: () => cubit.switchTab(status),
                    child: Text(label),
                  )
                : OutlinedButton(
                    onPressed: () => cubit.switchTab(status),
                    child: Text(label),
                  ),
          );
        }).toList(),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.filters, required this.onChanged});

  final BookingFilters filters;
  final ValueChanged<BookingFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.maxWidth;
        final compact = full < 720;

        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            SizedBox(
              width: compact ? full : 280,
              child: TextField(
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'بحث سريع',
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'اسم، هاتف، رقم حجز',
                ),
                onChanged: (v) => onChanged(filters.copyWith(search: v)),
              ),
            ),
            SizedBox(
              width: compact ? full : 220,
              child: TextField(
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'المسار',
                  prefixIcon: Icon(Icons.route_rounded),
                ),
                onChanged: (v) => onChanged(filters.copyWith(route: v)),
              ),
            ),
            SizedBox(
              width: compact ? full : 170,
              child: TextField(
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'التاريخ',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                onChanged: (v) => onChanged(filters.copyWith(date: v)),
              ),
            ),
            SizedBox(
              width: compact ? full : 190,
              child: DropdownButtonFormField<BookingPaymentMethod?>(
                initialValue: filters.paymentMethod,
                decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                items: [
                  const DropdownMenuItem<BookingPaymentMethod?>(
                    value: null,
                    child: Text('كل الطرق'),
                  ),
                  ...BookingPaymentMethod.values.map(
                    (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                  ),
                ],
                onChanged: (value) => onChanged(
                  filters.copyWith(
                    paymentMethod: value,
                    clearPaymentMethod: value == null,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
