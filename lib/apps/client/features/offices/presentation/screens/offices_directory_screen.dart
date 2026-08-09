import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
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
          body: Column(
            children: [
              _DirectoryMasthead(
                title: l10n.offices_directoryTitle,
                subtitle: loaded == null
                    ? null
                    : l10n.offices_countLabel(loaded.offices.length),
                searchBand: loaded != null ? OfficesSearchBand(state: loaded) : null,
              ),
              Expanded(
                child: switch (state) {
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
                  OfficesDirectoryLoaded(:final offices) when offices.isEmpty =>
                    const OfficesEmptyView(),
                  final OfficesDirectoryLoaded loadedState => loadedState.isFilteredEmpty
                      ? OfficesEmptyView(query: loadedState.query)
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<OfficesDirectoryCubit>().refresh(),
                          child: OfficesDirectoryList(
                            offices: loadedState.visibleOffices,
                          ),
                        ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DirectoryMasthead extends StatelessWidget {
  const _DirectoryMasthead({
    required this.title,
    required this.subtitle,
    required this.searchBand,
  });

  final String title;
  final String? subtitle;
  final Widget? searchBand;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final accent = ClientColors.primaryFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black54 
                : ClientColors.primaryFor(context).withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: ClientColors.heroGradientFor(context),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: topInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.of(context).maybePop(),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: ClientTypography.headingMedium(context).copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: ClientTypography.labelSmall(context).copyWith(
                                  color: Colors.white.withAlpha(200),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ?searchBand,
              ],
            ),
          ),
        ],
      ),
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
