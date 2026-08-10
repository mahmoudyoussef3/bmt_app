import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/routes_directory_cubit.dart';

/// Search box over the routes catalog. Owns only its text controller — the
/// query itself lives in [RoutesDirectoryCubit], so the list and the field
/// can never disagree about what is being searched for.
class RoutesSearchField extends StatefulWidget {
  const RoutesSearchField({super.key, required this.query});

  /// The cubit's current query. Passed in rather than read from the
  /// controller so a reset from elsewhere — the "clear search" action on the
  /// empty view — also empties the box the rider typed into.
  final String query;

  @override
  State<RoutesSearchField> createState() => _RoutesSearchFieldState();
}

class _RoutesSearchFieldState extends State<RoutesSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  @override
  void didUpdateWidget(RoutesSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    context.read<RoutesDirectoryCubit>().setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      padding: const EdgeInsetsDirectional.only(start: 8, end: 8),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
        border: Border.all(
          color: ClientColors.borderFor(context).withAlpha(100),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withAlpha(22),
              borderRadius: BorderRadius.circular(ClientRadius.pill),
            ),
            child: Icon(Icons.search_rounded, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: context.read<RoutesDirectoryCubit>().setQuery,
              textInputAction: TextInputAction.search,
              style: ClientTypography.bodyMedium(context),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                hintText: context.l10n.routes_searchHint,
                hintStyle: ClientTypography.bodyMedium(
                  context,
                ).copyWith(color: ClientColors.textTertiaryFor(context)),
              ),
            ),
          ),
          if (widget.query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              visualDensity: VisualDensity.compact,
              color: ClientColors.textSecondaryFor(context),
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              onPressed: _clear,
            ),
        ],
      ),
    );
  }
}
