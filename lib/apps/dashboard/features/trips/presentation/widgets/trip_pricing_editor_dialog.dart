import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/operation_trip.dart';
import '../../domain/entities/trip_pricing.dart';
import '../cubit/trips_cubit.dart';

class TripPricingEditorDialog extends StatefulWidget {
  final OperationTrip trip;
  final TripPricing? pricing;

  const TripPricingEditorDialog({super.key, required this.trip, this.pricing});

  @override
  State<TripPricingEditorDialog> createState() =>
      _TripPricingEditorDialogState();
}

class _TripPricingEditorDialogState extends State<TripPricingEditorDialog> {
  late TripRoutePoint fromPoint = _initialFromPoint;
  late TripRoutePoint toPoint = _initialToPoint;
  late bool isActive = widget.pricing?.isActive ?? true;
  final oneTime = TextEditingController();
  final fiveDays = TextEditingController();
  final tenDays = TextEditingController();
  final monthly = TextEditingController();
  final threeMonths = TextEditingController();
  final currency = TextEditingController(text: 'ج.م');
  String error = '';
  bool saving = false;

  TripRoutePoint get _initialFromPoint {
    final existing = widget.pricing;
    if (existing == null) return widget.trip.routePoints.first;
    return widget.trip.routePoints.firstWhere(
      (point) => point.id == existing.fromPointId,
      orElse: () => widget.trip.routePoints.first,
    );
  }

  TripRoutePoint get _initialToPoint {
    final existing = widget.pricing;
    if (existing == null) return widget.trip.routePoints[1];
    return widget.trip.routePoints.firstWhere(
      (point) => point.id == existing.toPointId,
      orElse: () => widget.trip.routePoints[1],
    );
  }

  @override
  void initState() {
    super.initState();
    final pricing = widget.pricing;
    oneTime.text = _initialValue(pricing?.oneTimePrice);
    fiveDays.text = _initialValue(pricing?.fiveDaysPrice);
    tenDays.text = _initialValue(pricing?.tenDaysPrice);
    monthly.text = _initialValue(pricing?.monthlyPrice);
    threeMonths.text = _initialValue(pricing?.threeMonthsPrice);
    currency.text = pricing?.currency ?? 'ج.م';
  }

  @override
  void dispose() {
    oneTime.dispose();
    fiveDays.dispose();
    tenDays.dispose();
    monthly.dispose();
    threeMonths.dispose();
    currency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final availableToPoints = widget.trip.routePoints
        .where((point) => point.order > fromPoint.order)
        .toList();
    if (!availableToPoints.any((point) => point.id == toPoint.id)) {
      toPoint = availableToPoints.first;
    }

    return SizedBox(
      width: 620,
      height: 500,
      child: AlertDialog(
        title: Text(widget.pricing == null ? 'إضافة تسعير' : 'تعديل التسعير'),
        content: SizedBox(
          width: 620,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TripRoutePoint>(
                        initialValue: fromPoint,
                        decoration: const InputDecoration(labelText: 'من نقطة'),
                        items: widget.trip.routePoints
                            .where(
                              (point) =>
                                  point.order <
                                  widget.trip.routePoints.last.order,
                            )
                            .map(
                              (point) => DropdownMenuItem(
                                value: point,
                                child: Text(point.name),
                              ),
                            )
                            .toList(),
                        onChanged: (next) {
                          if (next == null) return;
                          setState(() {
                            fromPoint = next;
                            final nextToPoints = widget.trip.routePoints
                                .where((point) => point.order > fromPoint.order)
                                .toList();
                            toPoint = nextToPoints.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: DropdownButtonFormField<TripRoutePoint>(
                        key: ValueKey(fromPoint.id),
                        initialValue: toPoint,
                        decoration: const InputDecoration(labelText: 'إلى نقطة'),
                        items: availableToPoints
                            .map(
                              (point) => DropdownMenuItem(
                                value: point,
                                child: Text(point.name),
                              ),
                            )
                            .toList(),
                        onChanged: (next) =>
                            setState(() => toPoint = next ?? toPoint),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                _PriceFields(
                  oneTime: oneTime,
                  fiveDays: fiveDays,
                  tenDays: tenDays,
                  monthly: monthly,
                  threeMonths: threeMonths,
                ),
                const SizedBox(height: AppSpacing.small),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: currency,
                        decoration: const InputDecoration(labelText: 'العملة'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    SwitchListTile(
                      value: isActive,
                      contentPadding: EdgeInsets.zero,
                      title: Text(isActive ? 'نشط' : 'غير نشط'),
                      onChanged: (value) => setState(() => isActive = value),
                    ),
                  ],
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    error,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: scheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? 'جار الحفظ' : 'حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final parsed = [
      _parsePrice(oneTime.text),
      _parsePrice(fiveDays.text),
      _parsePrice(tenDays.text),
      _parsePrice(monthly.text),
      _parsePrice(threeMonths.text),
    ];
    if (parsed.any((value) => value == null || value <= 0) ||
        currency.text.trim().isEmpty) {
      setState(() => error = 'كل الأسعار والعملة مطلوبة ويجب أن تكون صحيحة');
      return;
    }

    setState(() {
      saving = true;
      error = '';
    });
    final now = DateTime.now();
    final existing = widget.pricing;
    final result = await context.read<TripsCubit>().saveTripPricing(
      TripPricing(
        id: existing?.id ?? '',
        tripId: widget.trip.id,
        fromPointId: fromPoint.id,
        toPointId: toPoint.id,
        fromPointName: fromPoint.name,
        toPointName: toPoint.name,
        fromPointOrder: fromPoint.order,
        toPointOrder: toPoint.order,
        oneTimePrice: parsed[0]!,
        fiveDaysPrice: parsed[1]!,
        tenDaysPrice: parsed[2]!,
        monthlyPrice: parsed[3]!,
        threeMonthsPrice: parsed[4]!,
        currency: currency.text.trim(),
        isActive: isActive,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    if (!mounted) return;
    if (result == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      saving = false;
      error = result;
    });
  }
}

class _PriceFields extends StatelessWidget {
  final TextEditingController oneTime;
  final TextEditingController fiveDays;
  final TextEditingController tenDays;
  final TextEditingController monthly;
  final TextEditingController threeMonths;

  const _PriceFields({
    required this.oneTime,
    required this.fiveDays,
    required this.tenDays,
    required this.monthly,
    required this.threeMonths,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 560
            ? (constraints.maxWidth - AppSpacing.small) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            _PriceField(width: width, label: 'رحلة واحدة', controller: oneTime),
            _PriceField(width: width, label: '٥ أيام', controller: fiveDays),
            _PriceField(
              width: width,
              label: '١٠ أيام شهريًا',
              controller: tenDays,
            ),
            _PriceField(width: width, label: 'شهري', controller: monthly),
            _PriceField(width: width, label: '٣ شهور', controller: threeMonths),
          ],
        );
      },
    );
  }
}

class _PriceField extends StatelessWidget {
  final double width;
  final String label;
  final TextEditingController controller;

  const _PriceField({
    required this.width,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

double? _parsePrice(String value) {
  final normalized = value
      .replaceAll('٠', '0')
      .replaceAll('١', '1')
      .replaceAll('٢', '2')
      .replaceAll('٣', '3')
      .replaceAll('٤', '4')
      .replaceAll('٥', '5')
      .replaceAll('٦', '6')
      .replaceAll('٧', '7')
      .replaceAll('٨', '8')
      .replaceAll('٩', '9')
      .replaceAll(',', '.')
      .trim();
  return double.tryParse(normalized);
}

String _initialValue(double? value) {
  if (value == null) return '';
  final intValue = value.round();
  return value == intValue ? '$intValue' : value.toStringAsFixed(2);
}
