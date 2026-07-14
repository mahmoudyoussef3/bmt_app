import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../cubit/reviews_state.dart';

/// Search + the three ways operations slices the feed.
class ReviewsFilterBar extends StatelessWidget {
  const ReviewsFilterBar({
    super.key,
    required this.filter,
    required this.needsAttentionCount,
    required this.onFilterChanged,
    required this.onSearch,
    required this.searchController,
  });

  final ReviewsFilter filter;
  final int needsAttentionCount;
  final ValueChanged<ReviewsFilter> onFilterChanged;
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearch,
          decoration: InputDecoration(
            hintText: 'ابحث باسم العميل أو الكابتن أو رقم الحجز…',
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      searchController.clear();
                      onSearch('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            for (final option in ReviewsFilter.values)
              ChoiceChip(
                label: Text(_labelFor(option)),
                selected: filter == option,
                onSelected: (_) => onFilterChanged(option),
              ),
          ],
        ),
      ],
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
