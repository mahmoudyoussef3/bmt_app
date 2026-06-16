import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../../shared/domain/entities/operation_trip.dart';
import '../../shared/domain/entities/trip_pricing.dart';
import '../../trip_pricing/presentation/cubit/trip_pricing_cubit.dart';

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
    final matches = widget.trip.routePoints.where(
      (point) => point.id == existing.fromPointId,
    );
    return matches.isNotEmpty ? matches.first : widget.trip.routePoints.first;
  }

  TripRoutePoint get _initialToPoint {
    final existing = widget.pricing;
    if (existing == null) return widget.trip.routePoints[1];
    final matches = widget.trip.routePoints.where(
      (point) => point.id == existing.toPointId,
    );
    return matches.isNotEmpty ? matches.first : widget.trip.routePoints[1];
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
    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = (viewport.width - 48).clamp(340.0, 620.0);
    final dialogHeight = (viewport.height - 96).clamp(420.0, 560.0);
    if (widget.trip.routePoints.length < 2) {
      return AlertDialog(
        title: const Text('تعذر تعديل التسعير'),
        content: const Text('يجب أن يحتوي المسار على نقطتين على الأقل.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      );
    }
    final availableToPoints = widget.trip.routePoints
        .where((point) => point.order > fromPoint.order)
        .toList();
    if (!availableToPoints.any((point) => point.id == toPoint.id)) {
      toPoint = availableToPoints.first;
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.medium,
                AppSpacing.medium,
                AppSpacing.medium,
                AppSpacing.small,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.pricing == null ? 'إضافة تسعير' : 'تعديل التسعير',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'إغلاق',
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outline.withAlpha(60)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fieldWidth = constraints.maxWidth >= 520
                            ? (constraints.maxWidth - AppSpacing.small) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: AppSpacing.small,
                          runSpacing: AppSpacing.small,
                          children: [
                            SizedBox(
                              width: fieldWidth,
                              child: DropdownButtonFormField<TripRoutePoint>(
                                initialValue: fromPoint,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'من نقطة',
                                ),
                                items: widget.trip.routePoints
                                    .where(
                                      (point) =>
                                          point.order <
                                          widget.trip.routePoints.last.order,
                                    )
                                    .map(
                                      (point) => DropdownMenuItem(
                                        value: point,
                                        child: Text(
                                          point.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (next) {
                                  if (next == null) return;
                                  setState(() {
                                    fromPoint = next;
                                    final nextToPoints = widget.trip.routePoints
                                        .where(
                                          (point) =>
                                              point.order > fromPoint.order,
                                        )
                                        .toList();
                                    toPoint = nextToPoints.first;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: DropdownButtonFormField<TripRoutePoint>(
                                key: ValueKey(fromPoint.id),
                                initialValue: toPoint,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'إلى نقطة',
                                ),
                                items: availableToPoints
                                    .map(
                                      (point) => DropdownMenuItem(
                                        value: point,
                                        child: Text(
                                          point.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (next) =>
                                    setState(() => toPoint = next ?? toPoint),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    _PriceFields(
                      oneTime: oneTime,
                      fiveDays: fiveDays,
                      tenDays: tenDays,
                      monthly: monthly,
                      threeMonths: threeMonths,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 520;
                        final currencyField = TextField(
                          controller: currency,
                          decoration: const InputDecoration(
                            labelText: 'العملة',
                          ),
                        );
                        final activeSwitch = SwitchListTile(
                          value: isActive,
                          contentPadding: EdgeInsets.zero,
                          title: Text(isActive ? 'نشط' : 'غير نشط'),
                          onChanged: (value) =>
                              setState(() => isActive = value),
                        );
                        if (compact) {
                          return Column(
                            children: [currencyField, activeSwitch],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: currencyField),
                            const SizedBox(width: AppSpacing.medium),
                            SizedBox(width: 180, child: activeSwitch),
                          ],
                        );
                      },
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
            Divider(height: 1, color: scheme.outline.withAlpha(60)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Row(
                children: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: saving ? null : _save,
                    child: Text(saving ? 'جار الحفظ' : 'حفظ'),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final result = await context.read<TripPricingCubit>().savePricing(
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
