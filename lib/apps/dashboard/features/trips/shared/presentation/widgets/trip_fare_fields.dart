import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/trip_pricable_package.dart';
import 'trip_fare_controllers.dart';

/// The ONE fare editor used by both trip creation (the planner's pricing
/// panel) and trip editing (the trip-pricing dialog): the base ticket fare,
/// plus the package menu this trip sells.
///
/// The menu is the office's to build. Catalog packages are offered as a
/// starting point and can be dropped; "باقة جديدة" writes a package that
/// exists on this trip alone, with its own name, shape, price and note. Prices
/// are TOTAL package prices, not per-ride.
class TripFareFields extends StatelessWidget {
  const TripFareFields({
    super.key,
    required this.controllers,
    required this.onChanged,
  });

  final TripFareControllers controllers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controllers.baseFareController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'سعر التذكرة (رحلة واحدة)',
            suffixText: 'ج.م',
          ),
          onChanged: (_) {
            controllers.syncPricesFromBase();
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        Row(
          children: [
            Expanded(
              child: Text(
                'باقات هذه الرحلة',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Text(
              '${controllers.entries.length}',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          'أضف ما تريد بيعه في هذه الرحلة فقط — من باقات المكتب أو باقة جديدة '
          'تكتبها بنفسك. الباقة التي لا تضيفها لا تُعرض على الراكب.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.small),
        if (controllers.entries.isEmpty)
          _EmptyMenuNote(scheme: scheme)
        else
          for (var i = 0; i < controllers.entries.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: _PackageEntryCard(
                entry: controllers.entries[i],
                baseFare: controllers.baseFare,
                onChanged: onChanged,
                onPriceEdited: () =>
                    controllers.markPriceEdited(controllers.entries[i]),
                onRemove: () {
                  controllers.removeAt(i);
                  onChanged();
                },
              ),
            ),
        const SizedBox(height: AppSpacing.small),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            FilledButton.tonalIcon(
              onPressed: () {
                controllers.addBlank();
                onChanged();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('باقة جديدة لهذه الرحلة'),
            ),
            if (controllers.unusedCatalog.isNotEmpty)
              _CatalogMenuButton(
                packages: controllers.unusedCatalog,
                onPicked: (package) {
                  controllers.addFromCatalog(package);
                  onChanged();
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptyMenuNote extends StatelessWidget {
  const _EmptyMenuNote({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(60)),
      ),
      child: Text(
        'لا توجد باقات على هذه الرحلة — سيتم بيع التذاكر المفردة فقط.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _CatalogMenuButton extends StatelessWidget {
  const _CatalogMenuButton({required this.packages, required this.onPicked});

  final List<TripPricablePackage> packages;
  final ValueChanged<TripPricablePackage> onPicked;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDialog<TripPricablePackage>(
          context: context,
          builder: (_) => _CatalogPickerDialog(packages: packages),
        );
        if (picked != null) onPicked(picked);
      },
      icon: const Icon(Icons.playlist_add_rounded, size: 18),
      label: const Text('إضافة من باقات المكتب'),
    );
  }
}

class _CatalogPickerDialog extends StatelessWidget {
  const _CatalogPickerDialog({required this.packages});

  final List<TripPricablePackage> packages;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('باقات المكتب'),
      content: SizedBox(
        width: 380,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final package in packages)
              ListTile(
                title: Text(package.name),
                subtitle: Text(
                  '${package.rideCount} رحلات • ${package.durationDays} يوم',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(package),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}

class _PackageEntryCard extends StatelessWidget {
  const _PackageEntryCard({
    required this.entry,
    required this.baseFare,
    required this.onChanged,
    required this.onPriceEdited,
    required this.onRemove,
  });

  final TripFarePackageEntry entry;
  final double baseFare;
  final VoidCallback onChanged;
  final VoidCallback onPriceEdited;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _title(context)),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                tooltip: 'إزالة من هذه الرحلة',
                color: scheme.error,
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 520;
              final third = wide
                  ? (constraints.maxWidth - AppSpacing.small * 2) / 3
                  : constraints.maxWidth;
              return Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  if (entry.isDraft) ...[
                    SizedBox(
                      width: constraints.maxWidth,
                      child: TextField(
                        controller: entry.name,
                        decoration: InputDecoration(
                          labelText: 'اسم الباقة',
                          hintText: 'مثال: أسبوع الجامعة',
                          errorText: _fieldError(
                            entry.isDraft &&
                                _rowTouched(entry) &&
                                entry.name.text.trim().isEmpty,
                            'اسم الباقة مطلوب',
                          ),
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                    SizedBox(
                      width: third,
                      child: TextField(
                        controller: entry.rides,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'عدد الرحلات',
                          errorText: _fieldError(
                            entry.isDraft &&
                                _rowTouched(entry) &&
                                entry.rideCount <= 0,
                            'مطلوب',
                          ),
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                    SizedBox(
                      width: third,
                      child: TextField(
                        controller: entry.days,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'مدة الصلاحية (أيام)',
                          errorText: _fieldError(
                            entry.isDraft &&
                                _rowTouched(entry) &&
                                entry.durationDays <= 0,
                            'مطلوب',
                          ),
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                  ],
                  SizedBox(
                    width: entry.isDraft ? third : constraints.maxWidth,
                    child: TextField(
                      controller: entry.price,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'سعر الباقة',
                        helperText: _savingHelper(entry, baseFare),
                        suffixText: 'ج.م',
                        // A draft row flags its price once any of its other
                        // fields is touched; an existing (catalog) row only
                        // once the operator has actually edited ITS price —
                        // otherwise every catalog package would show a red
                        // price error the moment the panel opens with no
                        // base fare typed yet.
                        errorText: _fieldError(
                          (entry.isDraft
                                  ? _rowTouched(entry)
                                  : entry.priceEdited) &&
                              entry.priceValue <= 0,
                          'مطلوب',
                        ),
                      ),
                      onChanged: (_) {
                        onPriceEdited();
                        onChanged();
                      },
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: TextField(
                      controller: entry.note,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة للراكب (اختياري)',
                        hintText: 'مثال: تشمل رحلة العودة بعد الساعة ٤',
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String? _fieldError(bool show, String message) =>
      show ? message : null;

  /// True once the operator has put something into this specific row — the
  /// signal for a draft row to start flagging whichever of its fields are
  /// still empty. A blank new row shows no errors at all.
  static bool _rowTouched(TripFarePackageEntry entry) =>
      entry.name.text.trim().isNotEmpty ||
      entry.priceValue > 0 ||
      entry.rideCount > 0 ||
      entry.durationDays > 0;

  Widget _title(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (entry.isDraft) {
      return Text(
        'باقة جديدة — تُباع في هذه الرحلة فقط',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: scheme.primary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.name.text, style: Theme.of(context).textTheme.titleSmall),
        Text(
          entry.isTripScoped
              ? '${entry.rideCount} رحلات • ${entry.durationDays} يوم • خاصة بهذه الرحلة'
              : '${entry.rideCount} رحلات • ${entry.durationDays} يوم • من باقات المكتب',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// Shows the operator what the rider saves versus paying per ride — the
  /// same comparison the Client app's package card renders.
  static String? _savingHelper(TripFarePackageEntry entry, double baseFare) {
    if (baseFare <= 0 || entry.rideCount <= 0) return null;
    final regular = baseFare * entry.rideCount;
    return 'بدون باقة: ${regular.toStringAsFixed(0)} ج.م';
  }
}
