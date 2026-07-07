import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_bottom_sheet.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';

/// A premium, tiered filter sheet: title, scrollable filter groups, and a
/// sticky reset/apply footer showing how many results currently match.
///
/// Built on [ClientBottomSheet] so every filter surface in the app shares the
/// same header, drag handle, and corner radius rather than each screen
/// inventing its own overlay (this replaces ad hoc `PopupMenuButton`s).
class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({
    super.key,
    required this.title,
    required this.groups,
    required this.resultCount,
    required this.onReset,
    required this.onApply,
    this.canReset = true,
  });

  final String title;
  final List<Widget> groups;
  final int resultCount;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final bool canReset;

  @override
  Widget build(BuildContext context) {
    return ClientBottomSheet(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in groups) ...[
                    group,
                    const SizedBox(height: ClientSpacing.lg),
                  ],
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ClientButton.secondary(
                  label: 'Reset',
                  onPressed: canReset ? onReset : null,
                ),
              ),
              const SizedBox(width: ClientSpacing.sm),
              Expanded(
                flex: 2,
                child: ClientButton(
                  label: resultCount == 1
                      ? 'Show 1 result'
                      : 'Show $resultCount results',
                  onPressed: onApply,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
