import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/offices_directory_cubit.dart';

/// Search box over the offices directory. Owns only its text controller — the
/// query itself lives in [OfficesDirectoryCubit], so the list and the field can
/// never disagree about what is being searched for.
class OfficesSearchField extends StatefulWidget {
  const OfficesSearchField({super.key, required this.query});

  /// The cubit's current query. Passed in rather than read from the controller
  /// so that a reset from elsewhere — the "clear search" action on the empty
  /// view — also empties the box the rider typed into.
  final String query;

  @override
  State<OfficesSearchField> createState() => _OfficesSearchFieldState();
}

class _OfficesSearchFieldState extends State<OfficesSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  @override
  void didUpdateWidget(OfficesSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only follow the cubit when the two have genuinely diverged; assigning on
    // every keystroke would fight the user's cursor.
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    context.read<OfficesDirectoryCubit>().setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: TextField(
        controller: _controller,
        onChanged: context.read<OfficesDirectoryCubit>().setQuery,
        textInputAction: TextInputAction.search,
        style: ClientTypography.bodyMedium(context),
        decoration: InputDecoration(
          hintText: context.l10n.offices_searchHint,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: ClientColors.surfaceSubtleFor(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ClientRadius.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ClientRadius.md),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ClientRadius.md),
            borderSide: BorderSide(color: ClientColors.primaryFor(context)),
          ),
          suffixIcon: widget.query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  onPressed: _clear,
                )
              : null,
        ),
      ),
    );
  }
}
