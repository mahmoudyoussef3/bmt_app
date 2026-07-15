import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/search_field_row.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

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
    this.onSwap,
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

  /// Swaps pickup and destination in one tap. Omit to hide the swap button.
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ClientRadius.xl),
        border: Border.all(
          color: isDark
              ? scheme.outline.withAlpha(40)
              : scheme.outline.withAlpha(60),
        ),
        boxShadow: ClientElevation.md(context),
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
                      l10n.home_searchTripTitle,
                      style: ClientTypography.labelLarge(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.home_searchTripSubtitle,
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
          Stack(
            children: [
              Column(
                children: [
                  SearchFieldRow(
                    icon: Icons.trip_origin_rounded,
                    iconColor: ClientColors.journeyCyan,
                    label: l10n.home_pickupLocation,
                    value: pickup,
                    placeholder: l10n.home_selectPickupPoint,
                    onTap: onPickupTap,
                  ),
                  const SizedBox(height: 10),
                  SearchFieldRow(
                    icon: Icons.location_on_rounded,
                    iconColor: ClientColors.journeyAmber,
                    label: l10n.common_destination,
                    value: destination,
                    placeholder: l10n.home_whereAreYouGoing,
                    onTap: onDestinationTap,
                  ),
                ],
              ),
              if (onSwap != null)
                PositionedDirectional(
                  end: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _SwapButton(onTap: onSwap!)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SearchFieldRow(
                  icon: Icons.calendar_today_rounded,
                  iconColor: ClientColors.primary,
                  label: l10n.common_date,
                  value: date,
                  placeholder: l10n.common_today,
                  onTap: onDateTap,
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SearchFieldRow(
                  icon: Icons.schedule_rounded,
                  iconColor: ClientColors.primary,
                  label: l10n.common_time,
                  value: time,
                  placeholder: l10n.home_selectTime,
                  onTap: onTimeTap,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClientButton(
            label: l10n.home_searchTrips,
            expand: true,
            onPressed: onSearch,
          ),
        ],
      ),
    );
  }
}

/// Circular button that swaps pickup and destination in one tap, sitting on
/// the seam between the two fields (the pattern riders already know from
/// maps/ride-hailing apps).
class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClientColors.surfaceFor(context),
      shape: CircleBorder(
        side: BorderSide(color: ClientColors.borderFor(context)),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.swap_vert_rounded,
            size: 20,
            color: ClientColors.primaryFor(context),
          ),
        ),
      ),
    );
  }
}
