import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../utils/trip_history_filters.dart';
import '../utils/trip_history_labels.dart';
import '../utils/trip_history_palette.dart';

/// Route search, the date ranges, and what the two of them are hiding.
///
/// The text field's controller is owned here and never written from the cubit's
/// state: it exists so the field can carry its own clear button, not so the
/// query can be pushed back down mid-edit, which would fight the keyboard's own
/// editing state for no gain. The one external reset — "مسح الفلاتر" — is
/// routed through this widget for the same reason, so the controller stays the
/// only writer of the field's text.
class TripHistorySearchBar extends StatefulWidget {
  const TripHistorySearchBar({
    super.key,
    required this.dateFilter,
    required this.filterCounts,
    required this.matchCount,
    required this.isFiltering,
    required this.onQueryChanged,
    required this.onDateFilterChanged,
    required this.onClearFilters,
  });

  final TripHistoryDateFilter dateFilter;
  final Map<TripHistoryDateFilter, int> filterCounts;
  final int matchCount;
  final bool isFiltering;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TripHistoryDateFilter> onDateFilterChanged;
  final VoidCallback onClearFilters;

  @override
  State<TripHistorySearchBar> createState() => _TripHistorySearchBarState();
}

class _TripHistorySearchBarState extends State<TripHistorySearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearAll() {
    _controller.clear();
    FocusScope.of(context).unfocus();
    widget.onClearFilters();
  }

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
          _SearchField(
            controller: _controller,
            onChanged: widget.onQueryChanged,
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          _DateFilterRow(
            selected: widget.dateFilter,
            counts: widget.filterCounts,
            onSelected: widget.onDateFilterChanged,
          ),
          if (widget.isFiltering)
            _ResultsLine(matchCount: widget.matchCount, onClear: _clearAll),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final muted = TripHistoryPalette.neutral(context);

    OutlineInputBorder border(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: CaptainDesignTokens.br16,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: CaptainTypography.bodyMedium(context),
      decoration: InputDecoration(
        hintText: 'ابحث باسم الخط',
        hintStyle: CaptainTypography.bodyMedium(
          context,
        ).copyWith(color: muted, fontWeight: FontWeight.w500),
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: muted),
        // Only rebuilds the clear button as the captain types, rather than the
        // whole bar — the chips and the results line below don't change with a
        // keystroke that hasn't reached the cubit yet.
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: muted,
              tooltip: 'مسح البحث',
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            );
          },
        ),
        isDense: true,
        filled: true,
        fillColor: CaptainColors.surfaceFor(context),
        contentPadding: const EdgeInsets.symmetric(
          vertical: CaptainDesignTokens.s12,
        ),
        border: border(CaptainColors.dividerFor(context), 1),
        enabledBorder: border(CaptainColors.dividerFor(context), 1),
        focusedBorder: border(TripHistoryPalette.accent, 1.5),
      ),
    );
  }
}

class _DateFilterRow extends StatelessWidget {
  const _DateFilterRow({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final TripHistoryDateFilter selected;
  final Map<TripHistoryDateFilter, int> counts;
  final ValueChanged<TripHistoryDateFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in TripHistoryDateFilter.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: CaptainDesignTokens.s8,
              ),
              child: _DateChip(
                label: filter.label,
                count: counts[filter] ?? 0,
                isSelected: filter == selected,
                onTap: () => onSelected(filter),
              ),
            ),
        ],
      ),
    );
  }
}

/// A date range and how many trips it holds.
///
/// A range with nothing in it stays visible but refuses the tap: hiding it
/// would make the row's shape shift under the captain's thumb, and letting it
/// through would only ever land on the same empty list.
class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEmpty = count == 0 && !isSelected;
    final foreground = switch ((isSelected, isEmpty)) {
      (true, _) => CaptainColors.onPrimary,
      (false, true) => TripHistoryPalette.neutral(
        context,
      ).withValues(alpha: 0.5),
      (false, false) => CaptainColors.textPrimaryFor(context),
    };

    return Material(
      color: isSelected
          ? TripHistoryPalette.accent
          : CaptainColors.surfaceFor(context),
      borderRadius: CaptainDesignTokens.brPill,
      child: InkWell(
        onTap: isEmpty ? null : onTap,
        borderRadius: CaptainDesignTokens.brPill,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(
            CaptainDesignTokens.s12,
            CaptainDesignTokens.s8,
            CaptainDesignTokens.s8,
            CaptainDesignTokens.s8,
          ),
          decoration: BoxDecoration(
            borderRadius: CaptainDesignTokens.brPill,
            border: Border.all(
              color: isSelected
                  ? TripHistoryPalette.accent
                  : CaptainColors.dividerFor(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: CaptainTypography.labelMedium(
                  context,
                ).copyWith(color: foreground, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: CaptainDesignTokens.s8),
              _CountBadge(
                count: count,
                isSelected: isSelected,
                foreground: foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.isSelected,
    required this.foreground,
  });

  final int count;
  final bool isSelected;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected
            ? CaptainColors.onPrimary.withValues(alpha: 0.22)
            : TripHistoryPalette.accent.withValues(alpha: 0.10),
        borderRadius: CaptainDesignTokens.brPill,
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: CaptainTypography.labelSmall(context).copyWith(
          color: isSelected ? foreground : TripHistoryPalette.accent,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// What the filters left, and the way back out of them.
class _ResultsLine extends StatelessWidget {
  const _ResultsLine({required this.matchCount, required this.onClear});

  final int matchCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: CaptainDesignTokens.s4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              TripHistoryLabels.results(matchCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.labelMedium(
                context,
              ).copyWith(color: TripHistoryPalette.neutral(context)),
            ),
          ),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
            label: const Text('مسح الفلاتر'),
            style: TextButton.styleFrom(
              foregroundColor: TripHistoryPalette.accent,
              padding: const EdgeInsets.symmetric(
                horizontal: CaptainDesignTokens.s8,
              ),
              visualDensity: VisualDensity.compact,
              textStyle: CaptainTypography.labelMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
