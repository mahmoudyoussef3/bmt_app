import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/widgets/client_bottom_sheet.dart';
import 'package:bmt_app/apps/client/core/widgets/selection_picker_sheet_body.dart';
import 'package:bmt_app/apps/client/core/widgets/selection_search_field.dart';

/// Premium picker bottom sheet used across the booking search flow
/// (pickup, destination, date, time).
///
/// Supports an optional search field, a "Recent" shortcut section, and
/// loading/error/empty states so callers never have to fake data while a
/// network fetch is in flight.
class SelectionPickerSheet extends StatefulWidget {
  const SelectionPickerSheet({
    super.key,
    required this.title,
    required this.options,
    this.subtitle,
    this.selected,
    this.recent = const [],
    this.enableSearch = false,
    this.searchHint = 'Search',
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.emptyMessage = 'No options available yet',
  });

  final String title;
  final String? subtitle;
  final List<String> options;
  final String? selected;
  final List<String> recent;
  final bool enableSearch;
  final String searchHint;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyMessage;

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required List<String> options,
    String? subtitle,
    String? selected,
    List<String> recent = const [],
    bool enableSearch = false,
    String searchHint = 'Search',
    bool isLoading = false,
    String? errorMessage,
    VoidCallback? onRetry,
    String emptyMessage = 'No options available yet',
  }) {
    return showClientBottomSheet<String>(
      context: context,
      builder: (_) => SelectionPickerSheet(
        title: title,
        subtitle: subtitle,
        options: options,
        selected: selected,
        recent: recent,
        enableSearch: enableSearch,
        searchHint: searchHint,
        isLoading: isLoading,
        errorMessage: errorMessage,
        onRetry: onRetry,
        emptyMessage: emptyMessage,
      ),
    );
  }

  @override
  State<SelectionPickerSheet> createState() => _SelectionPickerSheetState();
}

class _SelectionPickerSheetState extends State<SelectionPickerSheet> {
  final _controller = TextEditingController();
  String _query = '';

  bool get _showSearch =>
      widget.enableSearch && !widget.isLoading && widget.errorMessage == null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClientBottomSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showSearch) ...[
            SelectionSearchField(
              controller: _controller,
              hint: widget.searchHint,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
          ],
          SelectionPickerSheetBody(
            options: widget.options,
            recent: widget.recent,
            selected: widget.selected,
            query: _query,
            isLoading: widget.isLoading,
            errorMessage: widget.errorMessage,
            onRetry: widget.onRetry,
            emptyMessage: widget.emptyMessage,
            onClearSearch: () => setState(() {
              _controller.clear();
              _query = '';
            }),
          ),
        ],
      ),
    );
  }
}
