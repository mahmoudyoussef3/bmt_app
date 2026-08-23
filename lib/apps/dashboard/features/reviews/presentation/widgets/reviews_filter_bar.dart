import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../cubit/reviews_state.dart';

/// Search plus the three ways operations slices the feed — rendered inside
/// [ReviewsTable]'s own card, above its sticky column header. The same "one
/// bordered panel holding the search bar, the column header and the rows"
/// shape every EWT table module (Trips, Tickets, Fleet…) uses, rather than a
/// separate toolbar floating above the table.
class ReviewsFilterBar extends StatelessWidget {
  const ReviewsFilterBar({
    super.key,
    required this.filter,
    required this.query,
    required this.needsAttentionCount,
    required this.onFilterChanged,
    required this.onSearch,
  });

  final ReviewsFilter filter;
  final String query;
  final int needsAttentionCount;
  final ValueChanged<ReviewsFilter> onFilterChanged;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = DebouncedSearchField(
          hintText: 'ابحث باسم العميل أو الكابتن أو رقم الحجز…',
          initialValue: query,
          onChanged: onSearch,
        );

        final chips = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in ReviewsFilter.values)
              ChoiceChip(
                label: Text(_labelFor(option)),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                selected: filter == option,
                showCheckmark: false,
                onSelected: (_) => onFilterChanged(option),
              ),
          ],
        );

        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const SizedBox(height: 10), chips],
          );
        }

        return Row(
          children: [
            SizedBox(width: 280, child: search),
            const SizedBox(width: 12),
            Expanded(child: chips),
          ],
        );
      },
    );
  }

  /// The unhappy-passenger queue carries its count on the chip — operations
  /// should not have to click it to find out whether it is worth clicking.
  String _labelFor(ReviewsFilter option) {
    if (option == ReviewsFilter.needsAttention && needsAttentionCount > 0) {
      return '${option.label} ($needsAttentionCount)';
    }
    return option.label;
  }
}
