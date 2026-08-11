import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';

class PassengerSearchField extends StatefulWidget {
  const PassengerSearchField({
    super.key,
    required this.hasQuery,
    required this.onChanged,
  });

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
