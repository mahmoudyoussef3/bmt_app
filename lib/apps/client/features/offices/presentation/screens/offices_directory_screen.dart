import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/offices_directory_cubit.dart';
import '../cubit/offices_directory_state.dart';
import '../widgets/offices_directory_list.dart';
import '../widgets/offices_empty_view.dart';
import '../widgets/offices_search_field.dart';

/// The marketplace directory: every active transportation office, best-rated
/// first, searchable by company name or the cities it serves. Tapping one opens
/// its profile with the departures and routes it operates.
class OfficesDirectoryScreen extends StatelessWidget {
  const OfficesDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: ClientAppBar(title: context.l10n.offices_directoryTitle),
      body: BlocBuilder<OfficesDirectoryCubit, OfficesDirectoryState>(
        builder: (context, state) => switch (state) {
          OfficesDirectoryLoading() => const _DirectorySkeleton(),
          OfficesDirectoryError(:final message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ClientErrorCard(
                message: message,
                retryLabel: context.l10n.common_retry,
                onRetry: () => context.read<OfficesDirectoryCubit>().load(),
              ),
            ),
          ),
          // The search box stays mounted whenever there is a directory to
          // search, including when the query currently matches nothing —
          // otherwise the field the rider just typed into disappears under them.
          OfficesDirectoryLoaded(:final offices) when offices.isEmpty =>
            const OfficesEmptyView(),
          final OfficesDirectoryLoaded loaded => Column(
            children: [
              OfficesSearchField(query: loaded.query),
              Expanded(
                child: loaded.isFilteredEmpty
                    ? OfficesEmptyView(query: loaded.query)
                    : RefreshIndicator(
                        onRefresh: () =>
                            context.read<OfficesDirectoryCubit>().refresh(),
                        child: OfficesDirectoryList(
                          offices: loaded.visibleOffices,
                        ),
                      ),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _DirectorySkeleton extends StatelessWidget {
  const _DirectorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const ClientSkeleton(height: 92, borderRadius: 16),
    );
  }
}
