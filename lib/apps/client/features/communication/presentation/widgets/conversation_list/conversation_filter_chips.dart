import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../../cubit/communication_cubit.dart';
import '../../models/conversation_filter.dart';
import '../../utils/communication_labels.dart';

class ConversationFilterChips extends StatelessWidget {
  const ConversationFilterChips({super.key, required this.selected});

  final ConversationFilter selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final filter in ConversationFilter.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(
                  filterLabel(context, filter),
                  style:
                      (filter == selected
                              ? ClientTypography.labelMedium(context)
                              : ClientTypography.bodySmall(context))
                          .copyWith(
                            color: filter == selected
                                ? scheme.onPrimary
                                : scheme.onSurface,
                          ),
                ),
                selected: filter == selected,
                selectedColor: scheme.primary,
                backgroundColor: scheme.surface,
                onSelected: (isSelected) {
                  if (isSelected) {
                    context.read<CommunicationCubit>().setFilter(filter);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
