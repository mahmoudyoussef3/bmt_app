import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';

import '../utils/trip_history_filters.dart';

/// Route search plus the date-range chips.
///
/// The text field is uncontrolled on purpose: it owns the captain's keystrokes
/// and reports them upward, but never reads the query back down. Feeding the
/// cubit's value back into a controller here would fight the keyboard's own
/// editing state for no gain.
class TripHistorySearchBar extends StatelessWidget {
  const TripHistorySearchBar({
    super.key,
    required this.dateFilter,
    required this.onQueryChanged,
    required this.onDateFilterChanged,
  });

  final TripHistoryDateFilter dateFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TripHistoryDateFilter> onDateFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s8,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث باسم الخط...',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: CaptainColors.surfaceFor(context),
              border: OutlineInputBorder(
                borderRadius: CaptainDesignTokens.br12,
                borderSide: BorderSide(
                  color: CaptainColors.dividerFor(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final filter in TripHistoryDateFilter.values) ...[
                  ChoiceChip(
                    label: Text(filter.label),
                    selected: dateFilter == filter,
                    onSelected: (_) => onDateFilterChanged(filter),
                  ),
                  const SizedBox(width: CaptainDesignTokens.s8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
