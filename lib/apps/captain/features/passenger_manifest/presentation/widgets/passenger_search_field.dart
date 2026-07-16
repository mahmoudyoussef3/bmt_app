import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';

/// Search across name, seat and pickup point.
///
/// Stateful for one reason: the clear button has to be able to empty the field,
/// which means owning the [TextEditingController] and disposing it. The query
/// itself is the cubit's — this only reports changes upward.
class PassengerSearchField extends StatefulWidget {
  const PassengerSearchField({
    super.key,
    required this.hasQuery,
    required this.onChanged,
  });

  /// Drives the clear affordance. Read from cubit state rather than from the
  /// controller so the button can't disagree with the list being shown.
  final bool hasQuery;
  final ValueChanged<String> onChanged;

  @override
  State<PassengerSearchField> createState() => _PassengerSearchFieldState();
}

class _PassengerSearchFieldState extends State<PassengerSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s16,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s16,
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو المقعد أو نقطة الركوب',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: widget.hasQuery
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  tooltip: 'مسح البحث',
                  onPressed: _clear,
                )
              : null,
          filled: true,
          fillColor: CaptainColors.surfaceFor(context),
          border: const OutlineInputBorder(
            borderRadius: CaptainDesignTokens.br16,
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: CaptainDesignTokens.s16,
            horizontal: CaptainDesignTokens.s24,
          ),
        ),
      ),
    );
  }
}
