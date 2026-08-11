import 'dart:async';

import 'package:flutter/material.dart';

/// A search input that reports changes only after the user stops typing.
///
/// Filtering a loaded workspace on every keystroke re-runs the filter and
/// rebuilds the whole list once per character; on the larger operational lists
/// that is visible as lag while typing. Debouncing collapses a burst of
/// keystrokes into a single update without changing what the operator sees.
class DebouncedSearchField extends StatefulWidget {
  const DebouncedSearchField({
    super.key,
    required this.onChanged,
    this.hintText,
    this.initialValue = '',
    this.duration = const Duration(milliseconds: 300),
  });

  final ValueChanged<String> onChanged;
  final String? hintText;
  final String initialValue;
  final Duration duration;

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.duration, () => widget.onChanged(value));
    
    setState(() {});
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'مسح البحث',
                icon: const Icon(Icons.close_rounded),
                onPressed: _clear,
              ),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
