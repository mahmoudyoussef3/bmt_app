import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_booking.dart';
import '../models/booking_filters.dart';

class BookingFiltersBar extends StatelessWidget {
  final BookingFilters filters;
  final ValueChanged<BookingFilters> onChanged;

  const BookingFiltersBar({
    required this.filters,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        spacing: AppSpacing.medium,
        runSpacing: AppSpacing.medium,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'بحث',
                prefixIcon: Icon(Icons.search),
                hintText: 'اسم، هاتف، مقعد',
              ),
              onChanged: (value) => onChanged(filters.copyWith(search: value)),
            ),
          ),
          SizedBox(
            width: 220,
            child: TextField(
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'المسار'),
              onChanged: (value) => onChanged(filters.copyWith(route: value)),
            ),
          ),
          SizedBox(
            width: 180,
            child: TextField(
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'التاريخ'),
              onChanged: (value) => onChanged(filters.copyWith(date: value)),
            ),
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<BookingStatus?>(
              initialValue: filters.status,
              decoration: const InputDecoration(labelText: 'الحالة'),
              items: [
                const DropdownMenuItem<BookingStatus?>(
                  value: null,
                  child: Text('كل الحالات'),
                ),
                ...BookingStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  ),
                ),
              ],
              onChanged: (value) => onChanged(
                filters.copyWith(status: value, clearStatus: value == null),
              ),
            ),
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<BookingPaymentMethod?>(
              initialValue: filters.paymentMethod,
              decoration: const InputDecoration(labelText: 'طريقة الدفع'),
              items: [
                const DropdownMenuItem<BookingPaymentMethod?>(
                  value: null,
                  child: Text('كل الطرق'),
                ),
                ...BookingPaymentMethod.values.map(
                  (method) => DropdownMenuItem(
                    value: method,
                    child: Text(method.label),
                  ),
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
      ),
    );
  }
}
