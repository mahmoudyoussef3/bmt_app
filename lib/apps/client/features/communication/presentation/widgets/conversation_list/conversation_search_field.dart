import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../cubit/communication_cubit.dart';

/// Search box over the conversation list. Owns only its text controller — the
/// query itself lives in [CommunicationCubit].
class ConversationSearchField extends StatefulWidget {
  const ConversationSearchField({super.key, required this.hasQuery});

  final bool hasQuery;

  @override
  State<ConversationSearchField> createState() =>
      _ConversationSearchFieldState();
}

class _ConversationSearchFieldState extends State<ConversationSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    context.read<CommunicationCubit>().setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _controller,
        onChanged: context.read<CommunicationCubit>().setQuery,
        decoration: InputDecoration(
          hintText: context.l10n.communication_searchHint,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          fillColor: scheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          suffixIcon: widget.hasQuery
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: _clear,
                )
              : null,
        ),
      ),
    );
  }
}
