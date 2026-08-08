import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/offices_directory_cubit.dart';
import '../cubit/offices_directory_state.dart';
import '../widgets/offices_directory_list.dart';
import '../widgets/offices_empty_view.dart';
import '../widgets/offices_search_band.dart';

/// The marketplace directory: every active transportation office, best-rated
/// first, searchable by company name or the cities it serves. Tapping one opens
/// its profile with the departures and routes it operates.
///
/// The whole screen rebuilds on state rather than only its body, because the
/// header carries the size of the directory — a count that is part of the
/// answer, not chrome around it.
class OfficesDirectoryScreen extends StatelessWidget {
  const OfficesDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfficesDirectoryCubit, OfficesDirectoryState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final loaded = state is OfficesDirectoryLoaded ? state : null;

        return Scaffold(
          backgroundColor: ClientColors.backgroundFor(context),
          appBar: ClientAppBar(
            title: l10n.offices_directoryTitle,
            subtitle: loaded == null
                ? null
                : l10n.offices_countLabel(loaded.offices.length),
          ),
          body: switch (state) {
            OfficesDirectoryLoading() => const _DirectorySkeleton(),
            OfficesDirectoryError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(ClientSpacing.md),
                child: ClientErrorCard(
                  message: message,
                  retryLabel: l10n.common_retry,
                  onRetry: () => context.read<OfficesDirectoryCubit>().load(),
                ),
              ),
            ),
            // The search box stays mounted whenever there is a directory to
            // search, including when the query currently matches nothing —
            // otherwise the field the rider just typed into disappears under
            // them.
            OfficesDirectoryLoaded(:final offices) when offices.isEmpty =>
              const OfficesEmptyView(),
            final OfficesDirectoryLoaded loaded => Column(
              children: [
                OfficesSearchBand(state: loaded),
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
        );
      },
    );
  }
}

class _DirectorySkeleton extends StatelessWidget {
  const _DirectorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: ClientSpacing.sm),
      itemBuilder: (_, _) => ClientSkeleton.officeCard(),
    );
  }
}
