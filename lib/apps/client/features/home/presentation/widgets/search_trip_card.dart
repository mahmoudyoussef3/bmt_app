import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ClientColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: ClientColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Trip',
                      style: ClientTypography.labelLarge(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find your next commute in seconds',
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SearchFieldRow(
            icon: Icons.trip_origin_rounded,
            iconColor: ClientColors.journeyGreen,
            label: 'Pickup Location',
            value: pickup,
            placeholder: 'Select pickup point',
            onTap: onPickupTap,
          ),
          const SizedBox(height: 10),
          _SearchFieldRow(
            icon: Icons.location_on_rounded,
            iconColor: ClientColors.journeyAmber,
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
                  iconColor: ClientColors.primary,
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
                  iconColor: ClientColors.primary,
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
          ClientButton(
            label: 'Search Trips',
            expand: true,
            onPressed: onSearch,
          ),
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
            color: ClientColors.surfaceSubtleFor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ClientColors.borderFor(context)),
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
                      style: ClientTypography.labelSmall(
                        context,
                      ).copyWith(color: ClientColors.textTertiaryFor(context)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.bodyMedium(context).copyWith(
                        fontWeight: hasValue
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: hasValue
                            ? ClientColors.textPrimaryFor(context)
                            : ClientColors.textTertiaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: ClientColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet picker for search fields.
Future<String?> showHomePickerSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: ClientColors.surfaceFor(context),
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
                    color: ClientColors.borderFor(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: ClientTypography.headingMedium(ctx)),
              const SizedBox(height: 12),
              ...options.map((option) {
                final isSelected = option == selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected
                        ? ClientColors.primaryLight
                        : ClientColors.surfaceSubtleFor(ctx),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, option),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? Border.all(
                                  color: ClientColors.primary,
                                  width: 2,
                                )
                              : Border.all(color: ClientColors.borderFor(ctx)),
                        ),
                        child: Text(
                          option,
                          style: ClientTypography.bodyLarge(ctx).copyWith(
                            color: isSelected
                                ? ClientColors.primary
                                : ClientColors.textPrimaryFor(ctx),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
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
