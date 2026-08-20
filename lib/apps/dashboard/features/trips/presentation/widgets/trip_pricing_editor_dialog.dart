import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../../shared/domain/entities/operation_trip.dart';
import '../../shared/domain/entities/trip_pricable_package.dart';
import '../../shared/domain/entities/trip_pricing.dart';
import '../../shared/presentation/widgets/trip_fare_controllers.dart';
import '../../shared/presentation/widgets/trip_fare_fields.dart';
import '../../trip_pricing/presentation/cubit/trip_pricing_cubit.dart';

class TripPricingEditorDialog extends StatefulWidget {
  final OperationTrip trip;
  final TripPricing? pricing;
  final List<TripPricablePackage> packages;

  const TripPricingEditorDialog({
    super.key,
    required this.trip,
    required this.packages,
    this.pricing,
  });

  @override
  State<TripPricingEditorDialog> createState() =>
      _TripPricingEditorDialogState();
}

class _TripPricingEditorDialogState extends State<TripPricingEditorDialog> {
  late TripRoutePoint fromPoint = _initialFromPoint;
  late TripRoutePoint toPoint = _initialToPoint;
  late bool isActive = widget.pricing?.isActive ?? true;

  /// The same fare editor the trip planner uses: one ticket price that
  /// suggests package prices, plus the package menu sold on this specific
  /// stop pair — catalog packages, this trip's own, or a new one written
  /// here.
  late final _fare = TripFareControllers(widget.packages);
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
    if (pricing != null) {
      _fare.loadFrom(pricing);
    } else {
      // A brand new stop pair starts from the office's catalog, exactly as
      // the planner does — every entry still removable.
      _fare.seedFromCatalog();
    }
    currency.text = pricing?.currency ?? 'ج.م';
  }

  @override
  void dispose() {
    _fare.dispose();
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
                    TripFareFields(
                      controllers: _fare,
                      onChanged: () => setState(() {}),
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
    if (currency.text.trim().isEmpty) {
      setState(() => error = 'العملة مطلوبة');
      return;
    }
    if (_fare.hasIncompletePackage) {
      setState(
        () => error = 'أكمل بيانات كل باقة: الاسم وعدد الرحلات والمدة والسعر.',
      );
      return;
    }
    if (!_fare.isValid) {
      setState(() => error = 'سعر التذكرة مطلوب ويجب أن يكون أكبر من صفر');
      return;
    }

    setState(() {
      saving = true;
      error = '';
    });

    // A package written in this dialog does not exist yet — create it against
    // the trip first, so the pricing row below can key on a real package id.
    final cubit = context.read<TripPricingCubit>();
    final drafts = _fare.entries.where((entry) => entry.isDraft).toList();
    for (final entry in drafts) {
      final offer = entry.toOffer();
      if (!offer.isSellable) continue;
      final id = await cubit.createTripPackage(widget.trip.id, offer);
      if (!mounted) return;
      if (id == null) {
        setState(() {
          saving = false;
          error = 'تعذر إنشاء الباقة "${offer.name}". حاول مرة أخرى.';
        });
        return;
      }
      _fare.adoptCreatedPackage(entry, id);
    }

    final now = DateTime.now();
    final existing = widget.pricing;

    final result = await cubit.savePricing(
      _fare.applyTo(
        TripPricing(
          id: existing?.id ?? '',
          tripId: widget.trip.id,
          fromPointId: fromPoint.id,
          toPointId: toPoint.id,
          fromPointName: fromPoint.name,
          toPointName: toPoint.name,
          fromPointOrder: fromPoint.order,
          toPointOrder: toPoint.order,
          oneTimePrice: 0,
          currency: currency.text.trim(),
          isActive: isActive,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
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
