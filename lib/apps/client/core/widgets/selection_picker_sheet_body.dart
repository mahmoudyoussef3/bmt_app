import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';
import 'package:bmt_app/apps/client/core/widgets/selection_option_tile.dart';
import 'package:bmt_app/apps/client/core/widgets/selection_state_widgets.dart';

/// Dispatches [SelectionPickerSheet] to its loading / error / empty / list
/// state, so the sheet itself only has to own the search field and layout.
class SelectionPickerSheetBody extends StatelessWidget {
  const SelectionPickerSheetBody({
    super.key,
    required this.options,
    required this.recent,
    required this.selected,
    required this.query,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.emptyMessage,
    required this.onClearSearch,
  });

  final List<String> options;
  final List<String> recent;
  final String? selected;
  final String query;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyMessage;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.55;

    if (isLoading) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, _) => const ClientSkeleton(height: 52, borderRadius: 14),
        ),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClientErrorCard(
          message: errorMessage!,
          onRetry: onRetry,
          retryLabel: 'Retry',
          compact: true,
        ),
      );
    }

    if (options.isEmpty) {
      return SelectionEmptyState(icon: Icons.inbox_rounded, message: emptyMessage);
    }

    final lowerQuery = query.toLowerCase();
    final filtered = query.isEmpty
        ? options
        : options.where((o) => o.toLowerCase().contains(lowerQuery)).toList();

    if (filtered.isEmpty) {
      return SelectionEmptyState(
        icon: Icons.search_off_rounded,
        message: 'No results for "$query"',
        actionLabel: 'Clear search',
        onAction: onClearSearch,
      );
    }

    final recentInOptions = query.isEmpty
        ? recent.where(options.contains).toList()
        : const <String>[];

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          if (recentInOptions.isNotEmpty) ...[
            const SelectionSectionLabel('Recent'),
            const SizedBox(height: 8),
            for (final option in recentInOptions) ...[
              SelectionOptionTile(
                label: option,
                icon: Icons.history_rounded,
                isSelected: option == selected,
                onTap: () => Navigator.pop(context, option),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            const SelectionSectionLabel('All'),
            const SizedBox(height: 8),
          ],
          for (final option in filtered) ...[
            SelectionOptionTile(
              label: option,
              isSelected: option == selected,
              onTap: () => Navigator.pop(context, option),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
