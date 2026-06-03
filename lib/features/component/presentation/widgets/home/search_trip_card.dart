import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
/// Search trip form card with pickup, destination, date, and time fields.
class SearchTripCard extends StatelessWidget {
  const SearchTripCard({
    super.key,
    required this.pickup,
    required this.destination,
    required this.date,
    required this.time,
    required this.onPickupTap,
    required this.onDestinationTap,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onSearch,
  });

  final String pickup;
  final String destination;
  final String date;
  final String time;
  final VoidCallback onPickupTap;
  final VoidCallback onDestinationTap;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.search_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search Trip', style: AppTextThemes.subtitle(scheme)),
                    const SizedBox(height: 4),
                    Text(
                      'Find your next commute in seconds',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(170),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SearchFieldRow(
            icon: Icons.trip_origin_rounded,
            iconColor: scheme.secondary,
            label: 'Pickup Location',
            value: pickup,
            placeholder: 'Select pickup point',
            onTap: onPickupTap,
          ),
          const SizedBox(height: 10),
          _SearchFieldRow(
            icon: Icons.location_on_rounded,
            iconColor: scheme.tertiary,
            label: 'Destination',
            value: destination,
            placeholder: 'Where are you going?',
            onTap: onDestinationTap,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SearchFieldRow(
                  icon: Icons.calendar_today_rounded,
                  iconColor: scheme.primary,
                  label: 'Date',
                  value: date,
                  placeholder: 'Today',
                  onTap: onDateTap,
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SearchFieldRow(
                  icon: Icons.schedule_rounded,
                  iconColor: scheme.primary,
                  label: 'Time',
                  value: time,
                  placeholder: 'Select time',
                  onTap: onTimeTap,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Search Trips', height: 50, onPressed: onSearch),
        ],
      ),
    );
  }
}

class _SearchFieldRow extends StatelessWidget {
  const _SearchFieldRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String placeholder;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value.isNotEmpty;
    final display = hasValue ? value : placeholder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outline.withAlpha(120)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface.withAlpha(150),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: hasValue
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: hasValue
                            ? scheme.onSurface
                            : scheme.onSurface.withAlpha(140),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: scheme.onSurface.withAlpha(140),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet picker for search fields (mock).
Future<String?> showHomePickerSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(ctx).textTheme.displaySmall),
              const SizedBox(height: 12),
              ...options.map((option) {
                final isSelected = option == selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    radius: 14,
                    onTap: () => Navigator.pop(ctx, option),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(ctx).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                    child: Text(
                      option,
                      style: Theme.of(ctx).textTheme.bodyLarge,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
